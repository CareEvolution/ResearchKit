/*
 Copyright (c) 2017, CareEvolution, LLC.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ORKWebViewStepViewController.h"
#import "ORKStepViewController_Internal.h"
#import "ORKWebViewStep.h"

#import "ORKResult_Private.h"
#import "ORKCollectionResult_Private.h"
#import "ORKWebViewStepResult.h"
#import "ORKNavigationContainerView_Internal.h"

#import <ResearchKit/ORKResult.h>
@import SafariServices;

static NSString *const ResearchKitCompleteStepMessageName = @"ResearchKit";

@interface ORKWeakScriptMessageHandler: NSObject <WKScriptMessageHandler>
@property (nonatomic, copy, nullable) void (^didReceiveScriptMessageFunc)(WKUserContentController *, WKScriptMessage *);
@end

@implementation ORKWeakScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.didReceiveScriptMessageFunc != nil) {
        self.didReceiveScriptMessageFunc(userContentController, message);
    }
}
@end

@interface ORKWebViewStepViewController ()
@property (nonatomic, strong) NSMutableArray *scriptMessageQueue;
@property (nonatomic, strong) ORKWeakScriptMessageHandler *scriptMessageHandlerWrapper;
@property (nonatomic) NSURLRequestCachePolicy remoteURLCachePolicy;
@property (nonatomic) NSTimeInterval remoteURLTimeoutInterval;
@end

@implementation ORKWebViewStepViewController {
    NSString *_result;
    NSString *_originalResult;
    ORKNavigationContainerView *_navigationFooterView;
    NSArray<NSLayoutConstraint *> *_constraints;
}

#pragma mark Public Interface

- (instancetype)initWithStep:(ORKStep *)step {
    return [self initWithStep:step result:nil scriptMessageNames:[NSSet set] remoteURLCachePolicy:NSURLRequestUseProtocolCachePolicy remoteURLTimeoutInterval:30];
}

- (instancetype)initWithStep:(ORKStep *)step result:(ORKResult *)result {
    return [self initWithStep:step result:result scriptMessageNames:[NSSet set] remoteURLCachePolicy:NSURLRequestUseProtocolCachePolicy remoteURLTimeoutInterval:30];
}

- (instancetype)initWithStep:(ORKStep *)step
                      result:(ORKResult *)result
          scriptMessageNames:(NSSet<NSString *> *)scriptMessageNames
        remoteURLCachePolicy:(NSURLRequestCachePolicy)remoteURLCachePolicy
    remoteURLTimeoutInterval:(NSTimeInterval)remoteURLTimeoutInterval {
    self = [super initWithStep:step];
    if (self) {
        NSParameterAssert([step isKindOfClass:[ORKWebViewStep class]]);
        
        _result = nil;
        _originalResult = nil;
        if ([result isKindOfClass:[ORKStepResult class]]) {
            ORKStepResult *stepResult = (ORKStepResult *)result;
            if ([stepResult.results.firstObject isKindOfClass:[ORKWebViewStepResult class]]) {
                ORKWebViewStepResult *webResult = (ORKWebViewStepResult *)stepResult.results.firstObject;
                _originalResult = webResult.result;
            }
        }
        
        _scriptMessageHandler = nil;
        _scriptMessageQueue = [NSMutableArray array];
        _scriptMessageNames = [scriptMessageNames copy];
        _remoteURLCachePolicy = remoteURLCachePolicy;
        _remoteURLTimeoutInterval = remoteURLTimeoutInterval;
        
        // WKWebView maintains a strong reference to its scriptMessageHandlers, making retain cycles possible. This wrapper facilitates breaking such retain cycles.
        __weak typeof(self) weakSelf = self;
        _scriptMessageHandlerWrapper = [[ORKWeakScriptMessageHandler alloc] init];
        _scriptMessageHandlerWrapper.didReceiveScriptMessageFunc = ^(WKUserContentController *userContentController, WKScriptMessage *scriptMessage) {
            [weakSelf userContentController:userContentController didReceiveScriptMessage:scriptMessage];
        };
        
        WKUserContentController *controller = [[WKUserContentController alloc] init];
        [controller addScriptMessageHandler:_scriptMessageHandlerWrapper name:ResearchKitCompleteStepMessageName];
        for (NSString *name in scriptMessageNames) {
            [controller addScriptMessageHandler:_scriptMessageHandlerWrapper name:name];
        }
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.allowsInlineMediaPlayback = true;
        if ([config respondsToSelector:@selector(mediaTypesRequiringUserActionForPlayback)]) {
            config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        }
        config.userContentController = controller;
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.navigationDelegate = self;
        
        [self loadWebContent];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseAudio) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (ORKWebViewStep *)webViewStep {
    return (ORKWebViewStep *)self.step;
}

- (void)setScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler {
    _scriptMessageHandler = scriptMessageHandler;
    [self processQueuedScriptMessages];
}

- (void)reloadWebContent {
    [self loadWebContent];
}

#pragma mark - ResearchKit

- (ORKStepResult *)result {
    ORKStepResult *parentResult = [super result];
    if (parentResult) {
        ORKWebViewStepResult *childResult = [[ORKWebViewStepResult alloc] initWithIdentifier:self.step.identifier];
        childResult.result = _result;
        childResult.endDate = parentResult.endDate;
        parentResult.results = [parentResult.results arrayByAddingObject:childResult] ? : @[childResult];
    }
    return parentResult;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    _webView.frame = self.view.bounds;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_webView];
    [self setupNavigationFooterView];
    [self setupConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /*
     CEVHACK - This fixes a bug that affects RK2 where the cancel button did nothing - because the view cycle is different than
     other subclasses of ORKStepViewController. Setting the cancelButtonItem on the _navigationFooterView needs to happen AFTER
     the super class ORKStepViewController has had a chance to create it.
     */
    _navigationFooterView.cancelButtonItem = self.cancelButtonItem;
}

- (void)viewDidDisappear:(BOOL)animated {
    [self pauseAudio];
    [super viewDidDisappear:animated];
}

- (void)setupNavigationFooterView {
    if (!_navigationFooterView) {
        _navigationFooterView = [[ORKNavigationContainerView alloc] initFromStepViewController:self];
    }
    _navigationFooterView.neverHasContinueButton = YES;
    [self.view addSubview:_navigationFooterView];
}

- (void)setupConstraints {
    if (_constraints) {
        [NSLayoutConstraint deactivateConstraints:_constraints];
    }

    UIView *viewForiPad = [self viewForiPadLayoutConstraints];

    _constraints = nil;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationFooterView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _constraints = @[
                     [NSLayoutConstraint constraintWithItem:_webView
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:viewForiPad ? : self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeTop
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_webView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:viewForiPad ? : self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_webView
                                                  attribute:NSLayoutAttributeRight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:viewForiPad ? : self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeRight
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:viewForiPad ? : self.view
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:viewForiPad ? : self.view
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeRight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:viewForiPad ? : self.view
                                                  attribute:NSLayoutAttributeRight
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_webView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeTop
                                                 multiplier:1.0
                                                   constant:0.0]
                     ];
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)pauseAudio {
    // https://stackoverflow.com/a/44829559
    NSString *script = @"var vids = document.getElementsByTagName('video'); var i; for (i of vids) { i.pause(); }";
    [_webView evaluateJavaScript:script completionHandler:nil];
}

#pragma mark - Web Content Handling

- (void)loadWebContent {
    [self.scriptMessageQueue removeAllObjects];
    _result = _originalResult;
    
    ORKWebViewStep *webViewStep = [self webViewStep];
    if (webViewStep.url) {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:webViewStep.url cachePolicy:self.remoteURLCachePolicy timeoutInterval:self.remoteURLTimeoutInterval];
        [_webView loadRequest:request];
    } else if ([self webViewStep].html) {
        [_webView loadHTMLString:webViewStep.html baseURL:webViewStep.baseURL];
    }
}

- (BOOL)shouldProcessScriptMessages {
    // scriptMessageNames is empty: no need for scriptMessageHandler; immediately process any ResearchKit message.
    // scriptMessageNames is non-empty: wait until scriptMessageHandler is set.
    return self.scriptMessageNames.count == 0
        || self.scriptMessageHandler != nil;
}

- (void)processQueuedScriptMessages {
    if (![self shouldProcessScriptMessages]) { return; }
    for (WKScriptMessage *message in self.scriptMessageQueue) {
        BOOL stop = [self processScriptMessage:message];
        if (stop) {
            break;
        }
    }
    [self.scriptMessageQueue removeAllObjects];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([self shouldProcessScriptMessages]) {
        [self processScriptMessage:message];
    } else {
        [self.scriptMessageQueue addObject:message];
    }
}

/// Returns YES if the view controller should stop processing any other messages. Assumes that `shouldProcessScriptMessages` is true.
/// - Parameter message: The message to process.
- (BOOL)processScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:ResearchKitCompleteStepMessageName] && [message.body isKindOfClass:[NSString class]]) {
        _result = (NSString *)message.body;
        [self goForward];
        return YES;
    }
    
    if ([self.scriptMessageNames containsObject:message.name]) {
        [self.scriptMessageHandler userContentController:self.webView.configuration.userContentController didReceiveScriptMessage:message];
        return NO;
    }
    return NO;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (navigationAction.targetFrame != nil
            && ([navigationAction.request.URL.scheme isEqualToString:@"http"]
                || [navigationAction.request.URL.scheme isEqualToString:@"https"])) {

            SFSafariViewControllerConfiguration *cfg = [[SFSafariViewControllerConfiguration alloc] init];
            cfg.barCollapsingEnabled = YES;
            SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:navigationAction.request.URL configuration:cfg];
            safari.preferredBarTintColor = self.navigationController.navigationBar.barTintColor;
            safari.preferredControlTintColor = self.view.tintColor;
            [self presentViewController:safari animated:YES completion:NULL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:NULL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
