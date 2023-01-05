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
@import ResearchKit.Private;
@import WebKit;
#import "ORKWebViewStepViewController.h"

@interface ORKWebViewStepViewControllerTests : XCTestCase

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

@interface TestScriptHandler: NSObject <WKScriptMessageHandler, ORKStepViewControllerDelegate>
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
- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction {
    [_events addObject:[NSString stringWithFormat:@"didFinishWithNavigationDirection:%@", direction == ORKStepViewControllerNavigationDirectionForward ? @"forward" : @"reverse"]];
}
- (void)stepViewControllerResultDidChange:(ORKStepViewController *)stepViewController { }
- (void)stepViewControllerDidFail:(ORKStepViewController *)stepViewController withError:(NSError *)error { }
- (void)stepViewController:(ORKStepViewController *)stepViewController recorder:(ORKRecorder *)recorder didFailWithError:(NSError *)error { }
@end

@implementation ORKWebViewStepViewControllerTests

- (ORKWebViewStep *)webViewStep {
    ORKWebViewStep *step = [[ORKWebViewStep alloc] initWithIdentifier:@"step"];
    step.html = @"<html><body></body></html>";
    return step;
}

- (void)testMessageQueue {
    ORKWebViewStep *webViewStep = [self webViewStep];
    TestScriptHandler *handler = [[TestScriptHandler alloc] init];
    ORKWebViewStepViewController *viewController = [[ORKWebViewStepViewController alloc] initWithStep:webViewStep scriptMessageNames:[NSSet setWithObjects:@"MessageA", @"MessageB", nil] remoteURLCachePolicy:NSURLRequestUseProtocolCachePolicy remoteURLTimeoutInterval:30];
    viewController.delegate = handler;
    
    WKScriptMessage *messageA1 = [[MockScriptMessage alloc] initWithName:@"MessageA" body:nil];
    WKScriptMessage *messageA2 = [[MockScriptMessage alloc] initWithName:@"MessageA" body:nil];
    WKScriptMessage *messageB = [[MockScriptMessage alloc] initWithName:@"MessageB" body:nil];
    WKScriptMessage *messageC = [[MockScriptMessage alloc] initWithName:@"MessageC" body:nil];
    WKScriptMessage *messageResearchKit = [[MockScriptMessage alloc] initWithName:@"ResearchKit" body:@"result"];
    
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
}

@end
