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


#import "ORK1ConsentLearnMoreViewController.h"

#import "ORK1ConsentDocument_Internal.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"
#import <WebKit/WebKit.h>


@interface ORK1ConsentLearnMoreViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSURL *contentURL;

@end


@implementation ORK1ConsentLearnMoreViewController

- (instancetype)initWithHTMLContent:(NSString *)content {
    self = [super init];
    if (self) {
        self.content = [ORK1ConsentDocument wrapHTMLBody:content mobile:YES];
    }
    return self;
}

- (instancetype)initWithContentURL:(NSURL *)contentURL {
    self = [super init];
    if (self) {
        self.contentURL = contentURL;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
  
    WKWebViewConfiguration *webViewConfiguration = [WKWebViewConfiguration new];
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:webViewConfiguration];
    
    const CGFloat horizMargin = ORK1StandardLeftMarginForTableViewCell(self.view);
    _webView.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
    _webView.scrollView.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
    
    _webView.clipsToBounds = NO;
    _webView.scrollView.clipsToBounds = NO;
    _webView.scrollView.scrollIndicatorInsets = (UIEdgeInsets){.left = -horizMargin, .right = -horizMargin};
    _webView.opaque = NO; // If opaque is set to YES, _webView shows a black right margin during transition when modally presented. This is an artifact due to disabling clipsToBounds to be able to show the scroll indicator outside the view.
    
    
    _webView.navigationDelegate = self;
    
    if (_contentURL) {
        [_webView loadRequest:[NSURLRequest requestWithURL:_contentURL]];
    } else {
        [_webView loadHTMLString:self.content baseURL:ORK1CreateRandomBaseURL()];
    }
    
    [self.view addSubview:_webView];
    
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self setUpConstraints];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_webView);
    const CGFloat horizMargin = ORK1StandardLeftMarginForTableViewCell(self.view);
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-horizMargin-[_webView]-horizMargin-|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:@{ @"horizMargin": @(horizMargin) }
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (IBAction)done:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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

@end
