/*
 Copyright (c) 2017, CareEvolution, Inc.
 
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

@implementation ORKWebViewPreloader {
    NSCache *_cache;
}

+ (instancetype)shared {
    static ORKWebViewPreloader *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ORKWebViewPreloader alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if ((self = [super init])) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 1;
    }
    return self;
}

- (void)preload:(NSString *)htmlString baseURL:(nullable NSURL *)baseURL forKey:(nonnull NSString *)key {
    WKWebView *webView = [self newWebView:htmlString baseURL:baseURL];
    [_cache setObject:webView forKey:key];
}

- (WKWebView *)webViewForKey:(NSString *)key baseURL:(nullable NSURL *)baseURL {
    WKWebView *webView = [_cache objectForKey:key];
    [_cache removeObjectForKey:key];
    if (webView == nil) {
        webView = [self newWebView:nil baseURL:baseURL];
    }
    return webView;
}

- (WKWebView *)newWebView:(NSString *)htmlString baseURL:(nullable NSURL *)baseURL {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = true;
    if ([config respondsToSelector:@selector(mediaTypesRequiringUserActionForPlayback)]) {
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    config.userContentController = controller;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    if (htmlString) {
        [webView loadHTMLString:htmlString baseURL:baseURL];
    }
    return webView;
}

@end

@interface ORKScriptMessageHandlerImpl: NSObject <WKScriptMessageHandler>
@property (nonatomic, copy, nullable) void (^didReceiveScriptMessageFunc)(WKUserContentController *, WKScriptMessage *);
@end

@implementation ORKScriptMessageHandlerImpl
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.didReceiveScriptMessageFunc != nil) {
        self.didReceiveScriptMessageFunc(userContentController, message);
    }
}
@end

@implementation ORKWebViewStepViewController {
    NSString *_result;
    ORKNavigationContainerView *_navigationFooterView;
    NSArray<NSLayoutConstraint *> *_constraints;
    ORKScriptMessageHandlerImpl *_scriptMessageHandlerImpl;
}

- (ORKWebViewStep *)webViewStep {
    return (ORKWebViewStep *)self.step;
}

- (void)stepDidChange {
    _result = nil;
    [_webView loadHTMLString:[self webViewStep].html baseURL:[self webViewStep].baseURL];
}

- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStep:step];
    if (self) {
        __weak typeof(self) weakSelf = self;
        _scriptMessageHandlerImpl = [[ORKScriptMessageHandlerImpl alloc] init];
        _scriptMessageHandlerImpl.didReceiveScriptMessageFunc = ^(WKUserContentController *userContentController, WKScriptMessage *scriptMessage) {
            [weakSelf userContentController:userContentController didReceiveScriptMessage:scriptMessage];
        };
        
        _webView = [[ORKWebViewPreloader shared] webViewForKey:step.identifier baseURL:[self webViewStep].baseURL];
        [_webView.configuration.userContentController addScriptMessageHandler:_scriptMessageHandlerImpl name:@"ResearchKit"];
        _webView.frame = self.view.bounds;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.navigationDelegate = self;
        [_webView loadHTMLString:[self webViewStep].html baseURL:[self webViewStep].baseURL];
        [self.view addSubview:_webView];
        [self setupNavigationFooterView];
        [self setupConstraints];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseAudio) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    /*
     CEVHACK - This fixes a bug that affects RK2 where the cancel button did nothing - because the view cycle is different than
     other subclasses of ORKStepViewController. Setting the cancelButtonItem on the _navigationFooterView needs to happen AFTER
     the super class ORKStepViewController has had a chance to create it.
     */
    
    [super viewWillAppear:animated];
    _navigationFooterView.cancelButtonItem = self.cancelButtonItem;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self stepDidChange];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self pauseAudio];
    [super viewDidDisappear:animated];
}

- (void)pauseAudio {
    // https://stackoverflow.com/a/44829559
    NSString *script = @"var vids = document.getElementsByTagName('video'); var i; for (i of vids) { i.pause(); }";
    [_webView evaluateJavaScript:script completionHandler:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([self.scriptMessageNames containsObject:message.name]) {
        [self.scriptMessageHandler userContentController:userContentController didReceiveScriptMessage:message];
        return;
    }
    if ([message.body isKindOfClass:[NSString class]]){
        _result = (NSString *)message.body;
        [self goForward];
    }
}

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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (navigationAction.targetFrame != nil
            && ([navigationAction.request.URL.scheme isEqualToString:@"http"]
                || [navigationAction.request.URL.scheme isEqualToString:@"https"])) {
                if (@available(iOS 11.0, *)) {
                    SFSafariViewControllerConfiguration *cfg = [[SFSafariViewControllerConfiguration alloc] init];
                    cfg.barCollapsingEnabled = YES;
                    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:navigationAction.request.URL configuration:cfg];
                    safari.preferredBarTintColor = self.navigationController.navigationBar.barTintColor;
                    safari.preferredControlTintColor = self.view.tintColor;
                    [self presentViewController:safari animated:YES completion:NULL];
                    decisionHandler(WKNavigationActionPolicyCancel);
                    return;
                }
            }
        
        if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
}

- (void)setScriptMessageNames:(NSArray<NSString *> *)scriptMessageNames {
    _scriptMessageNames = scriptMessageNames;
    for (NSString *i in scriptMessageNames) {
        [_webView.configuration.userContentController addScriptMessageHandler:_scriptMessageHandlerImpl name:i];
    }
}

@end
