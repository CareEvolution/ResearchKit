/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
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


#import "RK1ConsentDocument_Internal.h"

#import "RK1BodyLabel.h"
#import "RK1HeadlineLabel.h"
#import "RK1SubheadlineLabel.h"

#import "RK1ConsentSection_Private.h"
#import "RK1ConsentSectionFormatter.h"
#import "RK1ConsentSignature.h"
#import "RK1ConsentSignatureFormatter.h"
#import "RK1HTMLPDFWriter.h"

#import "RK1Helpers_Internal.h"
#import "RK1Errors.h"


@implementation RK1ConsentDocument {
    NSMutableArray<RK1ConsentSignature *> *_signatures;
}

#pragma mark - Initializers

- (instancetype)init {
    return [self initWithHTMLPDFWriter:[[RK1HTMLPDFWriter alloc] init]
            consentSectionFormatter:[[RK1ConsentSectionFormatter alloc] init]
            consentSignatureFormatter:[[RK1ConsentSignatureFormatter alloc] init]];
}

- (instancetype)initWithHTMLPDFWriter:(RK1HTMLPDFWriter *)writer
              consentSectionFormatter:(RK1ConsentSectionFormatter *)sectionFormatter
            consentSignatureFormatter:(RK1ConsentSignatureFormatter *)signatureFormatter{
    if (self = [super init]) {
        _writer = writer;
        _sectionFormatter = sectionFormatter;
        _signatureFormatter = signatureFormatter;
    }
    return self;
}

#pragma mark - Accessors

- (void)setSignatures:(NSArray<RK1ConsentSignature *> *)signatures {
    _signatures = [signatures mutableCopy];
}

- (NSArray<RK1ConsentSignature *> *)signatures {
    return [_signatures copy];
}

#pragma mark - Public

- (void)addSignature:(RK1ConsentSignature *)signature {
    if (!_signatures) {
        _signatures = [NSMutableArray array];
    }
    [_signatures addObject:signature];
}

- (void)makePDFWithCompletionHandler:(void (^)(NSData *data, NSError *error))completionBlock {
    [_writer writePDFFromHTML:[self htmlForMobile:NO withTitle:nil detail:nil]
          withCompletionBlock:^(NSData *data, NSError *error) {
        if (error) {
            // Pass the webview error straight through. This is a pretty exceptional
            // condition (can only happen if they pass us really invalid content).
            completionBlock(nil, error);
        } else {
            completionBlock(data, nil);
        }
    }];
}

#pragma mark - Private

- (NSString *)mobileHTMLWithTitle:(NSString *)title detail:(NSString *)detail {
    return [self htmlForMobile:YES withTitle:title detail:detail];
}

+ (NSString *)cssStyleSheet:(BOOL)mobile {
    NSMutableString *css = [@"@media print { .pagebreak { page-break-before: always; } }\n" mutableCopy];
    if (mobile) {
        [css appendString:@".header { margin-top: 36px ; margin-bottom: 30px; text-align: center; }\n"];
        [css appendString:@"body { margin-left: 0px; margin-right: 0px; }\n"];
        
        
        CGFloat adjustment = [[RK1SubheadlineLabel defaultFont] pointSize] - 17.0;
        NSArray *hPointSizes = @[ @([[RK1HeadlineLabel defaultFont] pointSize]),
                                 @(24.0 + adjustment),
                                 @(19.0 + adjustment),
                                 @(17.0 + adjustment),
                                 @(13.0 + adjustment),
                                 @(11.0 + adjustment) ];
        
        [css appendString:[NSString stringWithFormat:@"h1 { font-family: -apple-system-font ; font-weight: 300; font-size: %.0lf; }\n",
                           ((NSNumber *)hPointSizes[0]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"h2 { font-family: -apple-system-font ; font-weight: 300; font-size: %.0lf; text-align: left; margin-top: 2em; }\n",
                           ((NSNumber *)hPointSizes[1]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"h3 { font-family: -apple-system-font ; font-size: %.0lf; margin-top: 2em; }\n",
                           ((NSNumber *)hPointSizes[2]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"h4 { font-family: -apple-system-font ; font-size: %.0lf; margin-top: 2em; }\n",
                           ((NSNumber *)hPointSizes[3]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"h5 { font-family: -apple-system-font ; font-size: %.0lf; margin-top: 2em; }\n",
                           ((NSNumber *)hPointSizes[4]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"h6 { font-family: -apple-system-font ; font-size: %.0lf; margin-top: 2em; }\n",
                           ((NSNumber *)hPointSizes[5]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"body { font-family: -apple-system-font; font-size: %.0lf; }\n",
                           ((NSNumber *)hPointSizes[3]).floatValue]];
        [css appendString:[NSString stringWithFormat:@"p, blockquote, ul, fieldset, form, ol, dl, dir, { font-family: -apple-system-font; font-size: %.0lf; margin-top: -.5em; }\n",
                           ((NSNumber *)hPointSizes[3]).floatValue]];
    } else {
        [css appendString:@"h1, h2 { text-align: center; }\n"];
        [css appendString:@"h2, h3 { margin-top: 3em; }\n"];
        [css appendString:@"body, p, h1, h2, h3 { font-family: Helvetica; }\n"];
    }
    
    [css appendFormat:@".col-1-3 { width: %@; float: left; padding-right: 20px; }\n", mobile ? @"66.6%" : @"33.3%"];
    [css appendString:@".sigbox { position: relative; height: 100px; max-height:100px; display: inline-block; bottom: 10px }\n"];
    [css appendString:@".inbox { position: relative; top: 100%%; transform: translateY(-100%%); -webkit-transform: translateY(-100%%);  }\n"];
    [css appendString:@".grid:after { content: \"\"; display: table; clear: both; }\n"];
    [css appendString:@".border { -webkit-box-sizing: border-box; box-sizing: border-box; }\n"];
    
    return css;
}

+ (NSString *)wrapHTMLBody:(NSString *)body mobile:(BOOL)mobile {
    NSMutableString *html = [NSMutableString string];
    
    [html appendString:@"<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'><style>"];
    [html appendString:[[self class] cssStyleSheet:mobile]];
    [html appendString:@"</style></head><body>"];
    [html appendString:body];
    [html appendString:@"</body></html>"];
    
    return [html copy];
}

- (NSString *)htmlForMobile:(BOOL)mobile withTitle:(NSString *)title detail:(NSString *)detail {
    NSMutableString *body = [NSMutableString new];
    
    // header
    [body appendFormat:@"<div class='header'>"];
    if (title) {
        [body appendFormat:@"<h1>%@</h1>", title];
    }
    
    if (detail) {
        [body appendFormat:@"<p>%@</p>", detail];
    }
    [body appendFormat:@"</div>"];
    
    if (_htmlReviewContent) {
        [body appendString:_htmlReviewContent];
    } else {
        
        // title
        [body appendFormat:@"<h3>%@</h3>", _title ? : @""];
        
        // scenes
        for (RK1ConsentSection *section in _sections) {
            if (!section.omitFromDocument) {
                [body appendFormat:@"%@", [_sectionFormatter HTMLForSection:section]];
            }
        }
        
        if (!mobile) {
            // page break
            [body appendFormat:@"<h4 class=\"pagebreak\">%@</h4>", _signaturePageTitle ? : @""];
            [body appendFormat:@"<p>%@</p>", _signaturePageContent ? : @""];
            
            for (RK1ConsentSignature *signature in self.signatures) {
                [body appendFormat:@"%@", [_signatureFormatter HTMLForSignature:signature]];
            }
        }
    }
    return [[self class] wrapHTMLBody:body mobile:mobile];
}

#pragma mark - <NSSecureCoding>

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, signaturePageTitle, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, signaturePageContent, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, htmlReviewContent, NSString);
        NSArray *signatures = (NSArray *)[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"signatures"];
        _signatures = [signatures mutableCopy];
        RK1_DECODE_OBJ_ARRAY(aDecoder, sections, RK1ConsentSection);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    RK1_ENCODE_OBJ(aCoder, title);
    RK1_ENCODE_OBJ(aCoder, signaturePageTitle);
    RK1_ENCODE_OBJ(aCoder, signaturePageContent);
    RK1_ENCODE_OBJ(aCoder, signatures);
    RK1_ENCODE_OBJ(aCoder, htmlReviewContent);
    RK1_ENCODE_OBJ(aCoder, sections);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark - <NSCopying>

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1ConsentDocument *doc = [[[self class] allocWithZone:zone] init];
    doc.title = _title;
    doc.signaturePageTitle = _signaturePageTitle;
    doc.signaturePageContent = _signaturePageContent;
    doc.htmlReviewContent = _htmlReviewContent;
    
    // Deep copy the signatures
    doc.signatures = RK1ArrayCopyObjects(_signatures);
    
    // Deep copy the sections
    doc.sections = RK1ArrayCopyObjects(_sections);
    
    return doc;
}

#pragma mark - <NSObject>

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }

    __typeof(self) castObject = object;
    return (RK1EqualObjects(self.title, castObject.title)
            && RK1EqualObjects(self.signaturePageTitle, castObject.signaturePageTitle)
            && RK1EqualObjects(self.signaturePageContent, castObject.signaturePageContent)
            && RK1EqualObjects(self.htmlReviewContent, castObject.htmlReviewContent)
            && RK1EqualObjects(self.signatures, castObject.signatures)
            && RK1EqualObjects(self.sections, castObject.sections));
}

- (NSUInteger)hash {
    return _title.hash ^ _sections.hash;
}

@end
