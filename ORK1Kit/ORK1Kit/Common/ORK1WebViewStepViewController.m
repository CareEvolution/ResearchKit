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

#import "ORK1WebViewStepViewController.h"
#import "ORK1WebViewStep.h"
#import <ORK1Kit/ORK1Result.h>
@import SafariServices;

@implementation ORK1WebViewPreloader {
    NSCache *_cache;
}

+ (instancetype)shared {
    static ORK1WebViewPreloader *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ORK1WebViewPreloader alloc] init];
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

- (void)preload:(NSString *)htmlString forKey:(NSString *)key {
    WKWebView *webView = [self newWebView:htmlString];
    [_cache setObject:webView forKey:key];
}

- (WKWebView *)webViewForKey:(NSString *)key {
    WKWebView *webView = [_cache objectForKey:key];
    [_cache removeObjectForKey:key];
    if (webView == nil) {
        webView = [self newWebView:nil];
    }
    return webView;
}

- (WKWebView *)newWebView:(NSString *)htmlString {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = true;
    if ([config respondsToSelector:@selector(mediaTypesRequiringUserActionForPlayback)]) {
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    config.userContentController = controller;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    if (htmlString) {
        [webView loadHTMLString:htmlString baseURL:nil];
    }
    return webView;
}

@end

@interface ORK1ScriptMessageHandlerImpl: NSObject <WKScriptMessageHandler>
@property (nonatomic, copy, nullable) void (^didReceiveScriptMessageFunc)(WKUserContentController *, WKScriptMessage *);
@end

@implementation ORK1ScriptMessageHandlerImpl
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.didReceiveScriptMessageFunc != nil) {
        self.didReceiveScriptMessageFunc(userContentController, message);
    }
}
@end

@implementation ORK1WebViewStepViewController {
    NSString *_result;
    ORK1ScriptMessageHandlerImpl *_scriptMessageHandler;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        __weak typeof(self) weakSelf = self;
        _scriptMessageHandler = [[ORK1ScriptMessageHandlerImpl alloc] init];
        _scriptMessageHandler.didReceiveScriptMessageFunc = ^(WKUserContentController *userContentController, WKScriptMessage *scriptMessage) {
            [weakSelf userContentController:userContentController didReceiveScriptMessage:scriptMessage];
        };
        
        _webView = [[ORK1WebViewPreloader shared] webViewForKey:step.identifier];
        [_webView.configuration.userContentController addScriptMessageHandler:_scriptMessageHandler name:@"ResearchKit"];
        [_webView.configuration.userContentController addScriptMessageHandler:_scriptMessageHandler name:@"GetAccessToken"];
        _webView.frame = self.view.bounds;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.navigationDelegate = self;
        [_webView loadHTMLString:[self webViewStep].html baseURL:nil];
        [self.view addSubview:_webView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseAudio) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (ORK1WebViewStep *)webViewStep {
    return (ORK1WebViewStep *)self.step;
}

- (void)stepDidChange {
    _result = nil;
    [_webView loadHTMLString:[self webViewStep].html baseURL:nil];
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
    if ([message.name isEqual: @"GetAccessToken"]) {
        [self.scriptMessageHandler userContentController:userContentController didReceiveScriptMessage:message];
        return;
    }
    if ([message.body isKindOfClass:[NSString class]]){
        _result = (NSString *)message.body;
        [self goForward];
    }
}

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

@end
