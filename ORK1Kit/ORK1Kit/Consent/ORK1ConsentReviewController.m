/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
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


#import "ORK1ConsentReviewController.h"

#import "ORK1SignatureView.h"
#import "ORK1VerticalContainerView_Internal.h"

#import "ORK1ConsentDocument_Internal.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"


@interface ORK1ConsentReviewController () <WKNavigationDelegate, UIScrollViewDelegate>

@end


@implementation ORK1ConsentReviewController {
    UIToolbar *_toolbar;
    NSString *_htmlString;
    NSMutableArray *_variableConstraints;
    UIBarButtonItem *_agreeButton;
    BOOL _webViewFinishedLoading;
}

- (instancetype)initWithHTML:(NSString *)html delegate:(id<ORK1ConsentReviewControllerDelegate>)delegate requiresScrollToBottom:(BOOL)requiresScrollToBottom {
    self = [super init];
    if (self) {
        _htmlString = html;
        _delegate = delegate;
        _webViewFinishedLoading = NO;
        
        _agreeButton = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_AGREE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(ack)];
        if (requiresScrollToBottom) {
            _agreeButton.enabled = NO;
            _agreeButton.accessibilityHint = @"must scroll to the bottom to enable this button";
        }
        
        self.toolbarItems = @[
                             [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_DISAGREE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             _agreeButton];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.items = self.toolbarItems;
    
    self.view.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
    
    WKWebViewConfiguration *webViewConfiguration = [WKWebViewConfiguration new];
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfiguration];
    [_webView loadHTMLString:_htmlString baseURL:ORK1CreateRandomBaseURL()];
    _webView.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
    _webView.scrollView.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
    if (!_agreeButton.isEnabled) {
        _webView.scrollView.delegate = self;
    }
    _webView.navigationDelegate = self;
    [_webView setClipsToBounds:YES];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.translucent = YES;

    _webView.clipsToBounds = NO;
    _webView.scrollView.clipsToBounds = NO;
    [self updateLayoutMargins];

    [self.view addSubview:_webView];
    [self.view addSubview:_toolbar];
    
    [self setUpStaticConstraints];
}

- (void)updateLayoutMargins {
    const CGFloat margin = ORK1StandardHorizontalMarginForView(self.view);
    _webView.scrollView.scrollIndicatorInsets = (UIEdgeInsets){.left = -margin, .right = -margin};
}
    
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateLayoutMargins];
}

- (void)setUpStaticConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_webView, _toolbar);
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_toolbar]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_webView][_toolbar]-|"
                                                                             options:(NSLayoutFormatOptions)0 metrics:nil
                                                                               views:views]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_toolbar
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:ORK1GetMetricForWindow(ORK1ScreenMetricToolbarHeight, self.view.window)]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    if (!_variableConstraints) {
        _variableConstraints = [NSMutableArray new];
    }
    [NSLayoutConstraint deactivateConstraints:_variableConstraints];
    [_variableConstraints removeAllObjects];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_webView, _toolbar);
    const CGFloat horizontalMargin = ORK1StandardHorizontalMarginForView(self.view);
    [_variableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-horizMargin-[_webView]-horizMargin-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                                      metrics:@{ @"horizMargin": @(horizontalMargin) }
                                                                        views:views]];
    [NSLayoutConstraint activateConstraints:_variableConstraints];
}

- (IBAction)cancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(consentReviewControllerDidCancel:)]) {
        [self.delegate consentReviewControllerDidCancel:self];
    }
}

- (void)doAck {
    if (self.delegate && [self.delegate respondsToSelector:@selector(consentReviewControllerDidAcknowledge:)]) {
        [self.delegate consentReviewControllerDidAcknowledge:self];
    }
}

- (IBAction)ack {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ORK1LocalizedString(@"CONSENT_REVIEW_ALERT_TITLE", nil)
                                                                   message:self.localizedReasonForConsent
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_CANCEL", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_AGREE", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Have to dispatch, so following transition animation works
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doAck];
        });
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *) __unused webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType != WKNavigationTypeOther) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:^(BOOL __unused success) {
            decisionHandler(WKNavigationActionPolicyCancel);
        }];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *) __unused navigation {
    //need a delay here because of a race condition where the webview may not have fully rendered by the time this is called in which case scrolledToBottom returns YES because everything == 0
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _webViewFinishedLoading = YES;
        if (!_agreeButton.isEnabled && [self scrolledToBottom:_webView.scrollView]) {
            [_agreeButton setEnabled:YES];
            _agreeButton.accessibilityHint = nil;
        }
    });
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL scrolledToBottom = [self scrolledToBottom:scrollView];
    if (!_agreeButton.isEnabled && scrolledToBottom && _webViewFinishedLoading) {
        _agreeButton.enabled = YES;
        _agreeButton.accessibilityHint = nil;
    }
}

- (BOOL)scrolledToBottom:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    UIEdgeInsets inset = scrollView.contentInset;
    CGFloat currentOffset = offset.y + bounds.size.height - inset.bottom;
    return (currentOffset - scrollView.contentSize.height >= 0);
}

@end
