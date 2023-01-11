/*
 Copyright (c) 2023, CareEvolution, LLC.
 
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

#import <XCTest/XCTest.h>
@import ORK1Kit.Private;
@import WebKit;
#import "ORK1WebViewStepViewController.h"

@interface ORK1WebViewStepViewControllerTests : XCTestCase <ORK1StepViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
- (NSString *)webViewResult:(ORK1StepViewController *)stepViewController;
@end

@interface MockScriptMessage: WKScriptMessage
@property (nonatomic, strong) NSString *nameOverride;
@property (nonatomic, strong) NSString *bodyOverride;
- (instancetype)initWithName:(NSString *)name body:(NSString *)body;
@end

@implementation MockScriptMessage
- (instancetype)initWithName:(NSString *)name body:(NSString *)body {
    if (self = [super init]) {
        _nameOverride = name;
        _bodyOverride = body;
    }
    return self;
}

- (NSString *)name {
    return _nameOverride;
}
- (id)body {
    return _bodyOverride;
}
@end

@interface TestScriptHandler: NSObject <WKScriptMessageHandler, ORK1StepViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@end

@implementation TestScriptHandler
- (instancetype)init {
    if (self = [super init]) {
        _events = [NSMutableArray array];
    }
    return self;
}
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [_events addObject:[NSString stringWithFormat:@"didReceiveScriptMessage:%@", message.name]];
}
- (void)stepViewController:(ORK1StepViewController *)stepViewController didFinishWithNavigationDirection:(ORK1StepViewControllerNavigationDirection)direction {
    [_events addObject:[NSString stringWithFormat:@"didFinishWithNavigationDirection:%@", direction == ORK1StepViewControllerNavigationDirectionForward ? @"forward" : @"reverse"]];
}
- (void)stepViewControllerResultDidChange:(ORK1StepViewController *)stepViewController { }
- (void)stepViewControllerDidFail:(ORK1StepViewController *)stepViewController withError:(NSError *)error { }
- (void)stepViewController:(ORK1StepViewController *)stepViewController recorder:(ORK1Recorder *)recorder didFailWithError:(NSError *)error { }
@end

@implementation ORK1WebViewStepViewControllerTests

- (void)setUp {
    self.events = [NSMutableArray array];
}

- (ORK1WebViewStep *)webViewStep {
    ORK1WebViewStep *step = [[ORK1WebViewStep alloc] initWithIdentifier:@"step"];
    step.html = @"<html><body></body></html>";
    return step;
}

- (void)testNoScriptMessageHandler {
    ORK1WebViewStep *webViewStep = [self webViewStep];
    ORK1WebViewStepViewController *viewController = [[ORK1WebViewStepViewController alloc] initWithStep:webViewStep];
    viewController.delegate = self;
    
    XCTAssertNil(viewController.scriptMessageHandler, @"setup nil scriptMessageHandler");
    WKScriptMessage *messageResearchKit = [[MockScriptMessage alloc] initWithName:@"ResearchKit" body:@"result1"];
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageResearchKit];
    
    XCTAssertEqualObjects(self.events.firstObject, @"goForward:result1", @"ResearchKit message: sets result and triggers goForward");
}

- (void)testMessageQueue {
    ORK1WebViewStep *webViewStep = [self webViewStep];
    TestScriptHandler *handler = [[TestScriptHandler alloc] init];
    ORK1WebViewStepViewController *viewController = [[ORK1WebViewStepViewController alloc] initWithStep:webViewStep scriptMessageNames:[NSSet setWithObjects:@"MessageA", @"MessageB", nil] remoteURLCachePolicy:NSURLRequestUseProtocolCachePolicy remoteURLTimeoutInterval:30];
    viewController.delegate = handler;
    
    WKScriptMessage *messageA1 = [[MockScriptMessage alloc] initWithName:@"MessageA" body:nil];
    WKScriptMessage *messageA2 = [[MockScriptMessage alloc] initWithName:@"MessageA" body:nil];
    WKScriptMessage *messageB = [[MockScriptMessage alloc] initWithName:@"MessageB" body:nil];
    WKScriptMessage *messageC = [[MockScriptMessage alloc] initWithName:@"MessageC" body:nil];
    WKScriptMessage *messageResearchKit = [[MockScriptMessage alloc] initWithName:@"ResearchKit" body:@"result2"];
    
    // Send some messages before setting a handler; they should be enqueued for later processing.
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageA1];
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageB];
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageC];
    
    viewController.scriptMessageHandler = handler;
    
    XCTAssertEqual(handler.events.count, 2, @"Two queued messages processed after setting the script handler, one unsupported message ignored");
    if (handler.events.count == 2) {
        XCTAssertEqualObjects([handler.events objectAtIndex:0], @"didReceiveScriptMessage:MessageA");
        XCTAssertEqualObjects([handler.events objectAtIndex:1], @"didReceiveScriptMessage:MessageB");
    }
    [handler.events removeAllObjects];
    
    // Send some messages after setting a handler; they should be processed immediately.
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageC];
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageA2];
    [viewController userContentController:viewController.webView.configuration.userContentController didReceiveScriptMessage:messageResearchKit];
    
    XCTAssertEqual(handler.events.count, 2, @"One message processed immediately, one unsupported message ignored, ResearchKit (goForward) message not passed to handler.");
    if (handler.events.count == 2) {
        XCTAssertEqualObjects([handler.events objectAtIndex:0], @"didReceiveScriptMessage:MessageA");
        XCTAssertEqualObjects([handler.events objectAtIndex:1], @"didFinishWithNavigationDirection:forward");
    }
    [handler.events removeAllObjects];
    XCTAssertEqualObjects([self webViewResult:viewController], @"result2", @"Stores correct result");
}

#pragma mark - Test helpers

- (NSString *)webViewResult:(ORK1StepViewController *)stepViewController {
    if ([stepViewController.result.results.firstObject isKindOfClass:[ORK1WebViewStepResult class]]) {
        ORK1WebViewStepResult *result = (ORK1WebViewStepResult *)stepViewController.result.results.firstObject;
        return result.result ?: @"(nil)";
    } else {
        return @"(not present)";
    }
}

- (void)stepViewController:(ORK1StepViewController *)stepViewController didFinishWithNavigationDirection:(ORK1StepViewControllerNavigationDirection)direction {
    switch (direction) {
        case ORK1StepViewControllerNavigationDirectionForward:
            [self.events addObject:[NSString stringWithFormat:@"goForward:%@", [self webViewResult:stepViewController]]];
        case ORK1StepViewControllerNavigationDirectionReverse:
            [self.events addObject:[NSString stringWithFormat:@"goBackward:%@", [self webViewResult:stepViewController]]];
    }
}

- (void)stepViewControllerResultDidChange:(ORK1StepViewController *)stepViewController { }
- (void)stepViewControllerDidFail:(ORK1StepViewController *)stepViewController withError:(NSError *)error { }
- (void)stepViewController:(ORK1StepViewController *)stepViewController recorder:(ORK1Recorder *)recorder didFailWithError:(NSError *)error { }

@end
