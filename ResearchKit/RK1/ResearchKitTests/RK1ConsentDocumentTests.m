/*
 Copyright (c) 2015, Alex Basson. All rights reserved.

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


@import XCTest;
@import ResearchKit.Private;

#import "RK1ConsentSectionFormatter.h"
#import "RK1ConsentSignatureFormatter.h"
#import "RK1HTMLPDFWriter.h"


@interface RK1MockHTMLPDFWriter : RK1HTMLPDFWriter

@property (nonatomic, copy) NSString *html;
@property (nonatomic, copy) void (^completionBlock)(NSData *, NSError *);

@end


@implementation RK1MockHTMLPDFWriter

- (void)writePDFFromHTML:(NSString *)html withCompletionBlock:(void (^)(NSData *, NSError *))completionBlock {
    self.html = html;
    self.completionBlock = completionBlock;
}

@end


@interface RK1MockConsentSectionFormatter : RK1ConsentSectionFormatter

@end


@implementation RK1MockConsentSectionFormatter

- (NSString *)HTMLForSection:(RK1ConsentSection *)section {
    return @"html for section";
}

@end


@interface RK1MockConsentSignatureFormatter : RK1ConsentSignatureFormatter

@end


@implementation RK1MockConsentSignatureFormatter

- (NSString *)HTMLForSignature:(RK1ConsentSignature *)signature {
    return @"html for signature";
}

@end


@interface RK1ConsentDocumentTests : XCTestCase

@property (nonatomic, strong) RK1ConsentDocument *document;
@property (nonatomic, strong) RK1MockHTMLPDFWriter *mockWriter;

@end


@implementation RK1ConsentDocumentTests

- (void)setUp {
    [super setUp];

    self.mockWriter = [[RK1MockHTMLPDFWriter alloc] init];

    self.document = [[RK1ConsentDocument alloc] initWithHTMLPDFWriter:self.mockWriter
                                              consentSectionFormatter:[[RK1MockConsentSectionFormatter alloc] init]
                                            consentSignatureFormatter:[[RK1MockConsentSignatureFormatter alloc] init]];
}

- (void)tearDown {
    self.document = nil;
    [super tearDown];
}

- (NSString *)htmlWithContent:(NSString *)content mobile:(BOOL)mobile {
    NSString *boilerplateHeader =
@"<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'><style>@media print { .pagebreak { page-break-before: always; } }\n\
h1, h2 { text-align: center; }\n\
h2, h3 { margin-top: 3em; }\n\
body, p, h1, h2, h3 { font-family: Helvetica; }\n\
.col-1-3 { width: 33.3%; float: left; padding-right: 20px; margin-top: 100px;}\n\
.sigbox { position: relative; height: 100px; max-height:100px; display: inline-block; bottom: 10px }\n\
.inbox { position: absolute; bottom:10px; top: 100%%; transform: translateY(-100%%); -webkit-transform: translateY(-100%%);  }\n\
.inboxImage { position: relative; bottom:60px; top: 100%%; transform: translateY(-100%%); -webkit-transform: translateY(-100%%);  }\n\
.grid:after { content: \"\"; display: table; clear: both; }\n\
.border { -webkit-box-sizing: border-box; box-sizing: border-box; }\n\
</style></head><body><div class='header'></div>";
    NSMutableString *boilerplateFooter = [NSMutableString new];
    if (mobile) {
        [boilerplateFooter appendString:@"<h4 class=\"pagebreak\"></h4><p></p>"];
    }
    [boilerplateFooter appendString:@"</body></html>"];

    return [NSString stringWithFormat:@"%@%@%@", boilerplateHeader, content, boilerplateFooter];
}

- (void)testMakePDFWithCompletionHandler_withHTMLReviewContent_callsWriterWithCorrectHTML {
    self.document.htmlReviewContent = @"some content";
    [self.document makePDFWithCompletionHandler:^(NSData *data, NSError *error) {}];
    XCTAssertEqualObjects(self.mockWriter.html, [self htmlWithContent:@"some content"]);
}

- (void)testMakePDFWithCompletionHandler_withoutHTMLReviewContent_callsWriterWithCorrectHTML {
    self.document.title = @"A Title";
    self.document.sections = @[
                               [[RK1ConsentSection alloc] init],
                               [[RK1ConsentSection alloc] init]
                               ];
    self.document.signaturePageTitle = @"Signature Page Title";
    self.document.signaturePageContent = @"signature page content";
    self.document.signatures = @[
                                 [[RK1ConsentSignature alloc] init],
                                 [[RK1ConsentSignature alloc] init]
                                 ];

    NSString *content = @"<h3>A Title</h3>"
                        @"html for section"
                        @"html for section"
                        @"<h4 class=\"pagebreak\">Signature Page Title</h4>"
                        @"<p>signature page content</p>"
                        @"html for signature"
                        @"html for signature";

    [self.document makePDFWithCompletionHandler:^(NSData *data, NSError *error) {}];
    XCTAssertEqualObjects(self.mockWriter.html, [self htmlWithContent:content]);
}

- (void)testMakePDFWithCompletionHandler_whenWriterReturnsData_callsCompletionBlockWithData {
    __block NSData *passedData;
    __block NSError *passedError;
    [self.document makePDFWithCompletionHandler:^(NSData *data, NSError *error) {
        passedData = data;
        passedError = error;
    }];

    NSData *data = [NSData data];
    self.mockWriter.completionBlock(data, nil);

    XCTAssertEqualObjects(passedData, data);
    XCTAssertEqualObjects(passedError, nil);
}

- (void)testMakePDFWithCompletionHandler_whenWriterReturnsError_callsCompletionBlockWithError {
    __block NSData *passedData;
    __block NSError *passedError;
    [self.document makePDFWithCompletionHandler:^(NSData *data, NSError *error) {
        passedData = data;
        passedError = error;
    }];

    NSError *error = [NSError errorWithDomain:@"some error domain" code:123 userInfo:@{}];
    self.mockWriter.completionBlock(nil, error);

    XCTAssertEqualObjects(passedData, nil);
    XCTAssertEqualObjects(passedError, error);
}

@end
