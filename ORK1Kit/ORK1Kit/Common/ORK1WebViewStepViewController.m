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

#import "ORK1WebViewStepViewController.h"
#import "ORK1WebViewStep.h"
#import <ORK1Kit/ORK1Result.h>
@import SafariServices;

static NSString *const ResearchKitCompleteStepMessageName = @"ResearchKit";

@interface ORK1WeakScriptMessageHandler: NSObject <WKScriptMessageHandler>
@property (nonatomic, copy, nullable) void (^didReceiveScriptMessageFunc)(WKUserContentController *, WKScriptMessage *);
@end

@implementation ORK1WeakScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.didReceiveScriptMessageFunc != nil) {
        self.didReceiveScriptMessageFunc(userContentController, message);
    }
}
@end

@interface ORK1WebViewStepViewController ()
@property (nonatomic, strong) NSMutableArray *scriptMessageQueue;
@property (nonatomic, strong) ORK1WeakScriptMessageHandler *scriptMessageHandlerWrapper;
@property (nonatomic) NSURLRequestCachePolicy remoteURLCachePolicy;
@property (nonatomic) NSTimeInterval remoteURLTimeoutInterval;
@end

@implementation ORK1WebViewStepViewController {
    NSString *_result;
    NSString *_originalResult;
    BOOL _hasCompleted;
}

#pragma mark Public Interface

- (instancetype)initWithStep:(ORK1Step *)step {
    return [self initWithStep:step result:nil scriptMessageNames:[NSSet set] remoteURLCachePolicy:NSURLRequestUseProtocolCachePolicy remoteURLTimeoutInterval:30];
}

- (instancetype)initWithStep:(ORK1Step *)step result:(ORK1Result *)result {
    return [self initWithStep:step result:result scriptMessageNames:[NSSet set] remoteURLCachePolicy:NSURLRequestUseProtocolCachePolicy remoteURLTimeoutInterval:30];
}

- (instancetype)initWithStep:(ORK1Step *)step
                      result:(ORK1Result *)result
          scriptMessageNames:(NSSet<NSString *> *)scriptMessageNames
        remoteURLCachePolicy:(NSURLRequestCachePolicy)remoteURLCachePolicy
    remoteURLTimeoutInterval:(NSTimeInterval)remoteURLTimeoutInterval {
    self = [super initWithStep:step];
    if (self) {
        NSParameterAssert([step isKindOfClass:[ORK1WebViewStep class]]);
        
        _result = nil;
        _originalResult = nil;
        if ([result isKindOfClass:[ORK1StepResult class]]) {
            ORK1StepResult *stepResult = (ORK1StepResult *)result;
            if ([stepResult.results.firstObject isKindOfClass:[ORK1WebViewStepResult class]]) {
                ORK1WebViewStepResult *webResult = (ORK1WebViewStepResult *)stepResult.results.firstObject;
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
        _scriptMessageHandlerWrapper = [[ORK1WeakScriptMessageHandler alloc] init];
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

- (ORK1WebViewStep *)webViewStep {
    return (ORK1WebViewStep *)self.step;
}

- (void)setScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler {
    _scriptMessageHandler = scriptMessageHandler;
    [self processQueuedScriptMessages];
}

- (void)reloadWebContent {
    [self loadWebContent];
}

#pragma mark - ResearchKit

- (ORK1StepResult *)result {
    ORK1StepResult *parentResult = [super result];
    if (parentResult) {
        ORK1WebViewStepResult *childResult = [[ORK1WebViewStepResult alloc] initWithIdentifier:self.step.identifier];
        childResult.result = _result;
        childResult.endDate = parentResult.endDate;
        parentResult.results = @[childResult];
    }
    return parentResult;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:_webView];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;

    // Top edge: on iOS 26+, pin to the safe area rather than the raw view edge, so this full-bleed
    // view still reserves space for CEVRK1's navigation-bar progress view (added via
    // additionalSafeAreaInsets in ORK1TaskViewController's configureProgressView) instead of
    // rendering underneath it. Leading/trailing/bottom stay pinned to the raw edges (unchanged,
    // still full-bleed there) — the nav bar is already opaque on iOS 26+ regardless of progress
    // style (see ORK1TaskViewController commonInit), so this is a no-op except when the extra
    // progress-bar inset is actually present. iOS <26 is left on the original raw-edge pin
    // (previously achieved via frame = self.view.bounds; now via an equivalent top anchor).
    NSLayoutYAxisAnchor *topAnchor = self.view.topAnchor;
    if (@available(iOS 26.0, *)) {
        topAnchor = self.view.safeAreaLayoutGuide.topAnchor;
    }
    [NSLayoutConstraint activateConstraints:@[
        [_webView.topAnchor constraintEqualToAnchor:topAnchor],
        [_webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
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

#pragma mark - Web Content Handling

- (void)loadWebContent {
    [self.scriptMessageQueue removeAllObjects];
    _result = _originalResult;
    
    ORK1WebViewStep *webViewStep = [self webViewStep];
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
    if ([message.name isEqualToString:ResearchKitCompleteStepMessageName] && [message.body isKindOfClass:[NSString class]] && !_hasCompleted) {
        _result = (NSString *)message.body;
        [self goForward];
        _hasCompleted = YES;
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
