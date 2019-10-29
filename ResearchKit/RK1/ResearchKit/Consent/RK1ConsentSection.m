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


#import "RK1ConsentSection.h"

#import "RK1ConsentDocument_Internal.h"

#import "RK1Helpers_Internal.h"


static NSString *movieNameForType(RK1ConsentSectionType type, CGFloat scale) {
    NSString *fullMovieName = [NSString stringWithFormat:@"consent_%02ld", (long)type + 1];
    fullMovieName = [NSString stringWithFormat:@"%@@%dx", fullMovieName, (int)scale];
    return fullMovieName;
}

NSURL *RK1MovieURLForConsentSectionType(RK1ConsentSectionType type) {
    CGFloat scale = [UIScreen mainScreen].scale;
    
    // For iPad, use the movie for the next scale up
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && scale < 3) {
        scale++;
    }
    
    NSURL *url = [RK1AssetsBundle() URLForResource:movieNameForType(type, scale) withExtension:@"m4v"];
    if (url == nil) {
        // This can fail on 3x devices when the display is set to zoomed. Try an asset at 2x instead.
        url = [RK1AssetsBundle() URLForResource:movieNameForType(type, 2.0) withExtension:@"m4v"];
    }
    return url;
}

UIImage *RK1ImageForConsentSectionType(RK1ConsentSectionType type) {
    NSString *imageName = [NSString stringWithFormat:@"consent_%02ld", (long)type];
    return [UIImage imageNamed:imageName inBundle:RK1Bundle() compatibleWithTraitCollection:nil];
}

// Copied from CFXMLParser.c in http://www.opensource.apple.com/source/CF/CF-550.13/CFXMLParser.c
/*
 At the very least we need to do <, >, &, ", and '. In addition, we'll have to do everything else in the string.
 We should also be handling items that are up over certain values correctly.
 */
static CFStringRef CFXMLCreateStringByEscapingEntities(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
    //CFAssert1(string != NULL, __kCFLogAssertion, "%s(): NULL string not permitted.", __PRETTY_FUNCTION__);
    CFMutableStringRef newString = CFStringCreateMutable(allocator, 0); // unbounded mutable string
    CFMutableCharacterSetRef startChars = CFCharacterSetCreateMutable(allocator);
    
    CFStringInlineBuffer inlineBuf;
    CFIndex idx = 0;
    CFIndex mark = idx;
    CFIndex stringLength = CFStringGetLength(string);
    UniChar uc;
    
    CFCharacterSetAddCharactersInString(startChars, CFSTR("&<>'\""));
    
    CFStringInitInlineBuffer(string, &inlineBuf, CFRangeMake(0, stringLength));
    for(idx = 0; idx < stringLength; idx++) {
        uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, idx);
        if (CFCharacterSetIsCharacterMember(startChars, uc)) {
            CFStringRef previousSubstring = CFStringCreateWithSubstring(allocator, string, CFRangeMake(mark, idx - mark));
            CFStringAppend(newString, previousSubstring);
            CFRelease(previousSubstring);
            switch(uc) {
                case '&':
                    CFStringAppend(newString, CFSTR("&amp;"));
                    break;
                case '<':
                    CFStringAppend(newString, CFSTR("&lt;"));
                    break;
                case '>':
                    CFStringAppend(newString, CFSTR("&gt;"));
                    break;
                case '\'':
                    CFStringAppend(newString, CFSTR("&apos;"));
                    break;
                case '"':
                    CFStringAppend(newString, CFSTR("&quot;"));
                    break;
            }
            mark = idx + 1;
        }
    }
    // Copy the remainder to the output string before returning.
    CFStringRef remainder = CFStringCreateWithSubstring(allocator, string, CFRangeMake(mark, idx - mark));
    if (NULL != remainder) {
        CFStringAppend(newString, remainder);
        CFRelease(remainder);
    }
    CFRelease(startChars);
    return newString;
}


@implementation RK1ConsentSection {
    NSString *_escapedContent;
}

static NSString *localizedTitleForConsentSectionType(RK1ConsentSectionType sectionType) {
    NSString *str = nil;
    switch (sectionType) {
        case RK1ConsentSectionTypeOverview:
            str = RK1LocalizedString(@"CONSENT_SECTION_WELCOME", nil);
            break;
        case RK1ConsentSectionTypeDataGathering:
            str = RK1LocalizedString(@"CONSENT_SECTION_DATA_GATHERING", nil);
            break;
        case RK1ConsentSectionTypePrivacy:
            str = RK1LocalizedString(@"CONSENT_SECTION_PRIVACY", nil);
            break;
        case RK1ConsentSectionTypeDataUse:
            str = RK1LocalizedString(@"CONSENT_SECTION_DATA_USE", nil);
            break;
        case RK1ConsentSectionTypeTimeCommitment:
            str = RK1LocalizedString(@"CONSENT_SECTION_TIME_COMMITMENT", nil);
            break;
        case RK1ConsentSectionTypeStudySurvey:
            str = RK1LocalizedString(@"CONSENT_SECTION_STUDY_SURVEY", nil);
            break;
        case RK1ConsentSectionTypeStudyTasks:
            str = RK1LocalizedString(@"CONSENT_SECTION_STUDY_TASKS", nil);
            break;
        case RK1ConsentSectionTypeWithdrawing:
            str = RK1LocalizedString(@"CONSENT_SECTION_WITHDRAWING", nil);
            break;
        case RK1ConsentSectionTypeOnlyInDocument:
        case RK1ConsentSectionTypeCustom:
            break;
    }
    return str;
}

- (instancetype)initWithType:(RK1ConsentSectionType)type {
    self = [super init];
    if (self) {
        _type = type;
        _title = localizedTitleForConsentSectionType(type);
        _summary = nil;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)setContent:(NSString *)content {
    _content = content;
    _escapedContent = nil;
}

- (NSString *)escapedContent {
    if (_content == nil || _content.length == 0) {
        return _content;
    }
    
    if (_escapedContent == nil) {
        _escapedContent = (__bridge NSString *)(CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)(_content), NULL));
        
        // Use <br/> to replace "\n"
        _escapedContent = [_escapedContent stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    }
    return _escapedContent;
}

- (UIImage *)image {
    UIImage *image = nil;
    if (_type == RK1ConsentSectionTypeCustom) {
        image = _customImage;
    } else {
        image = RK1ImageForConsentSectionType(_type);
    }
    return image;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_ENUM(aDecoder, type);
        RK1_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, summary, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, content, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, htmlContent, NSString);
        RK1_DECODE_URL_BOOKMARK(aDecoder, contentURL);
        RK1_DECODE_BOOL(aDecoder, omitFromDocument);
        RK1_DECODE_OBJ_CLASS(aDecoder, formalTitle, NSString);
        RK1_DECODE_IMAGE(aDecoder, customImage);
        RK1_DECODE_URL_BOOKMARK(aDecoder, customAnimationURL);
        RK1_DECODE_OBJ_CLASS(aDecoder, customLearnMoreButtonTitle, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    RK1_ENCODE_ENUM(aCoder, type);
    RK1_ENCODE_OBJ(aCoder, title);
    RK1_ENCODE_OBJ(aCoder, formalTitle);
    RK1_ENCODE_OBJ(aCoder, summary);
    RK1_ENCODE_OBJ(aCoder, content);
    RK1_ENCODE_OBJ(aCoder, htmlContent);
    RK1_ENCODE_URL_BOOKMARK(aCoder, contentURL);
    RK1_ENCODE_BOOL(aCoder, omitFromDocument);
    RK1_ENCODE_IMAGE(aCoder, customImage);
    RK1_ENCODE_URL_BOOKMARK(aCoder, customAnimationURL);
    RK1_ENCODE_OBJ(aCoder, customLearnMoreButtonTitle);
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (RK1EqualObjects(self.title, castObject.title)
            && RK1EqualObjects(self.formalTitle, castObject.formalTitle)
            && RK1EqualObjects(self.summary, castObject.summary)
            && RK1EqualObjects(self.content, castObject.content)
            && RK1EqualObjects(self.htmlContent, castObject.htmlContent)
            && RK1EqualFileURLs(self.contentURL, castObject.contentURL)
            && (self.omitFromDocument == castObject.omitFromDocument)
            && RK1EqualObjects(self.customImage, castObject.customImage)
            && RK1EqualObjects(self.customLearnMoreButtonTitle, castObject.customLearnMoreButtonTitle)
            && RK1EqualFileURLs(self.customAnimationURL, castObject.customAnimationURL) &&
            (self.type == castObject.type));
}

- (NSUInteger)hash {
    return _title.hash ^ _type;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1ConsentSection *sec = [[[self class] allocWithZone:zone] init];
    sec.title = _title;
    sec.formalTitle = _formalTitle;
    sec.summary = _summary;
    sec.content = _content;
    sec.htmlContent = _htmlContent;
    sec.contentURL = _contentURL;
    sec.omitFromDocument = _omitFromDocument;
    sec.customImage = _customImage;
    sec->_type = _type;
    sec.customAnimationURL = _customAnimationURL;
    sec.customLearnMoreButtonTitle = _customLearnMoreButtonTitle;
    
    return sec;
}

@end
