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

@import UIKit;
@import WebKit;
#import <ResearchKit/ORKStepViewController.h>

NS_ASSUME_NONNULL_BEGIN

@class ORKWebViewStep;

ORK_CLASS_AVAILABLE
/// Caches at most exactly one instance of a WKWebView.
///
/// Intended for offscreen loading of web content before there is a view controller to contain the web view, so that the content is ready to immediately render once it is time to display on-screen.
@interface ORKWebViewPreloader : NSObject

/// A singleton instance.
+ (instancetype)shared;

@property (nonatomic) NSURLRequestCachePolicy remoteURLCachePolicy;
@property (nonatomic) NSTimeInterval remoteURLTimeoutInterval;

/// Creates and stores a web view, and immediately begins loading content in the view as specified by the `webViewStep`. Replaces any previously stored web view.
/// - Parameters:
///   - webViewStep: Defines the content to load in the web view.
///   - key: A unique identifier for the web view.
- (void)preload:(ORKWebViewStep *)webViewStep forKey:(NSString *)key;

@end

/**
 The `ORKWebViewStepViewController` class is a step view controller subclass
 used to manage a web view step (`ORKWebViewStep`).
 
 You should not need to instantiate a web view step view controller directly. Instead, include
 a web view step in a task, and present a task view controller for that task.
 */
ORK_CLASS_AVAILABLE
@interface ORKWebViewStepViewController : ORKStepViewController<WKScriptMessageHandler, WKNavigationDelegate>

// Guaranteed to be non-nil after this view controller's init.
@property (nonatomic, strong, readonly) WKWebView *webView;

// Set these properties before the first viewWillAppear event, or in the `stepViewControllerWillAppear` delegate method.

@property (nonatomic) BOOL reloadContentOnFirstAppearance;
@property (nonatomic, strong) id<WKScriptMessageHandler> scriptMessageHandler;
@property (nonatomic, strong) NSArray<NSString *> *scriptMessageNames;
@end

NS_ASSUME_NONNULL_END
