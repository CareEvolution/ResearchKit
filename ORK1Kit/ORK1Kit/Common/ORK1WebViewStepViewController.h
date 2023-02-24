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

@import UIKit;
@import WebKit;
#import <ORK1Kit/ORK1Defines.h>
#import <ORK1Kit/ORK1StepViewController.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `ORK1WebViewStepViewController` class is a step view controller subclass
 used to manage a web view step (`ORK1WebViewStep`).
 */
ORK1_CLASS_AVAILABLE
@interface ORK1WebViewStepViewController : ORK1StepViewController<WKScriptMessageHandler, WKNavigationDelegate>

/// Guaranteed to be non-nil after this view controller is initialized.
@property (nonatomic, strong, readonly) WKWebView *webView;

/// The set of all WebKit Javascript bridge message names that should be passed to the ``scriptMessageHandler``.
///
/// This is in addition to WebKit messages named "ResearchKit", which are handled by this view controller, setting the ``result`` and triggering ``goForward`` to navigate to the next step.
@property (nonatomic, readonly) NSSet<NSString *> *scriptMessageNames;

/// The delegate object that will receive any script messages identified by ``scriptMessageNames``.
///
/// This is initially `nil`. If ``scriptMessageNames`` is non-empty, any incoming script messages, including the "ResearchKit" message, are stored in a queue until you set `scriptMessageHandler` to a non-nil value; at that time any queued messages will immediately be sent to the `scriptMessageHandler`.
///
/// If ``scriptMessageNames`` is empty, "ResearchKit" messages are processed immediately without needing to set `scriptMessageHandler`. This allows automatically-constructed ORK1WebViewStepViewController instances to work with no additional configuration.
///
/// See ``WKScriptMessageHandler`` for more information.
@property (nonatomic, strong, nullable) id<WKScriptMessageHandler> scriptMessageHandler;

/// Creates a web view and immediately begins loading content in the web view as specified by the step definition.
///
/// Use this initializer to pre-load a web view step offscreen so it can be ready to render immediately when it is time to present the step.
///
/// The `scriptMessageHandler` is initialized as `nil`. Any incoming script messages received while `scriptMessageHandler` is nil will be enqueued for later processing. Interactivity can thus be delayed until this view controller is ready to display, for example by waiting to set a `scriptMessageHandler` until this view controller's `viewWillAppear` lifecycle event.
/// - Parameters:
///   - step: Must be an `ORK1WebViewStep`.
///   - result: The previous step result for this step, if any. The view controller will use this as the source of its `result` value until any user interaction updates the result.
///   - scriptMessageNames: A set of custom WebKit message names to declare as supported. See ``scriptMessageHandler``.
///   - remoteURLCachePolicy: Cache policy for loading URL-based web view steps.
///   - remoteURLTimeoutInterval: Timeout interval for loading URL-based web view steps.
- (instancetype)initWithStep:(ORK1Step *)step
                      result:(nullable ORK1Result *)result
          scriptMessageNames:(NSSet<NSString *> *)scriptMessageNames
        remoteURLCachePolicy:(NSURLRequestCachePolicy)remoteURLCachePolicy
    remoteURLTimeoutInterval:(NSTimeInterval)remoteURLTimeoutInterval;

/// Immediately reloads the content specified by this view controller's web view step.
///
/// Use this to prepare a view controller previously loaded offscreen with the latest step content. This discards any enqueued WebKit script messages.
- (void)reloadWebContent;

@end

NS_ASSUME_NONNULL_END
