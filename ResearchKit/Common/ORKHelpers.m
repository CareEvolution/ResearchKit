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


#import "ORKHelpers_Internal.h"

#import "ORKStep.h"

#import "ORKSkin.h"
#import "ORKTypes.h"

#import <CoreText/CoreText.h>


NSURL *ORKLegacyCreateRandomBaseURL() {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://researchkit.%@/", [NSUUID UUID].UUIDString]];
}

NSBundle *ORKLegacyAssetsBundle(void) {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleForClass:[ORKLegacyStep class]];
    });
    return bundle;
}

ORKLegacy_INLINE CGFloat ORKLegacyCGFloor(CGFloat value) {
    if (sizeof(value) == sizeof(float)) {
        return (CGFloat)floorf((float)value);
    } else {
        return (CGFloat)floor((double)value);
    }
}

ORKLegacy_INLINE CGFloat ORKLegacyAdjustToScale(CGFloat (adjustFunction)(CGFloat), CGFloat value, CGFloat scale) {
    if (scale == 0) {
        static CGFloat screenScale = 1.0;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            screenScale = [UIScreen mainScreen].scale;
        });
        scale = screenScale;
    }
    if (scale == 1.0) {
        return adjustFunction(value);
    } else {
        return adjustFunction(value * scale) / scale;
    }
}

CGFloat ORKLegacyFloorToViewScale(CGFloat value, UIView *view) {
    return ORKLegacyAdjustToScale(ORKLegacyCGFloor, value, view.contentScaleFactor);
}

id findInArrayByKey(NSArray * array, NSString *key, id value) {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
    NSArray *matches = [array filteredArrayUsingPredicate:pred];
    if (matches.count) {
        return matches[0];
    }
    return nil;
}

NSString *ORKLegacyStringFromDateISO8601(NSDate *date) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [formatter stringFromDate:date];
}

NSDate *ORKLegacyDateFromStringISO8601(NSString *string) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [formatter dateFromString:string];
}

NSString *ORKLegacySignatureStringFromDate(NSDate *date) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    });
    return [formatter stringFromDate:date];
}

UIColor *ORKLegacyRGBA(uint32_t x, CGFloat alpha) {
    CGFloat b = (x & 0xff) / 255.0f; x >>= 8;
    CGFloat g = (x & 0xff) / 255.0f; x >>= 8;
    CGFloat r = (x & 0xff) / 255.0f;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

UIColor *ORKLegacyRGB(uint32_t x) {
    return ORKLegacyRGBA(x, 1.0f);
}

UIFontDescriptor *ORKLegacyFontDescriptorForLightStylisticAlternative(UIFontDescriptor *descriptor) {
    UIFontDescriptor *fontDescriptor = [descriptor
                      fontDescriptorByAddingAttributes:
                      @{ UIFontDescriptorFeatureSettingsAttribute: @[
                                 @{ UIFontFeatureTypeIdentifierKey: @(kCharacterAlternativesType),
                                    UIFontFeatureSelectorIdentifierKey: @(1) }]}];
    return fontDescriptor;
}


UIFont *ORKLegacyTimeFontForSize(CGFloat size) {
    UIFontDescriptor *fontDescriptor = [ORKLegacyLightFontWithSize(size) fontDescriptor];
    fontDescriptor = ORKLegacyFontDescriptorForLightStylisticAlternative(fontDescriptor);
    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0];
    return font;
}

NSString *ORKLegacyFileProtectionFromMode(ORKLegacyFileProtectionMode mode) {
    switch (mode) {
        case ORKLegacyFileProtectionComplete:
            return NSFileProtectionComplete;
        case ORKLegacyFileProtectionCompleteUnlessOpen:
            return NSFileProtectionCompleteUnlessOpen;
        case ORKLegacyFileProtectionCompleteUntilFirstUserAuthentication:
            return NSFileProtectionCompleteUntilFirstUserAuthentication;
        case ORKLegacyFileProtectionNone:
            return NSFileProtectionNone;
    }
    //assert(0);
    return NSFileProtectionNone;
}

CGFloat ORKLegacyExpectedLabelHeight(UILabel *label) {
    CGSize expectedLabelSize = [label.text boundingRectWithSize:CGSizeMake(label.frame.size.width, CGFLOAT_MAX)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{ NSFontAttributeName : label.font }
                                                        context:nil].size;
    return expectedLabelSize.height;
}

void ORKLegacyAdjustHeightForLabel(UILabel *label) {
    CGRect rect = label.frame;
    rect.size.height = ORKLegacyExpectedLabelHeight(label);
    label.frame = rect;
}

UIImage *ORKLegacyImageWithColor(UIColor *color) {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

void ORKLegacyEnableAutoLayoutForViews(NSArray *views) {
    [views enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView *)obj setTranslatesAutoresizingMaskIntoConstraints:NO];
    }];
}

NSDateFormatter *ORKLegacyResultDateTimeFormatter() {
    static NSDateFormatter *dateTimeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateTimeformatter = [[NSDateFormatter alloc] init];
        [dateTimeformatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        dateTimeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return dateTimeformatter;
}

NSDateFormatter *ORKLegacyResultTimeFormatter() {
    static NSDateFormatter *timeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeformatter = [[NSDateFormatter alloc] init];
        [timeformatter setDateFormat:@"HH:mm"];
        timeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return timeformatter;
}

NSDateFormatter *ORKLegacyResultDateFormatter() {
    static NSDateFormatter *dateformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyy-MM-dd"];
        dateformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return dateformatter;
}

NSDateFormatter *ORKLegacyTimeOfDayLabelFormatter() {
    static NSDateFormatter *timeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeformatter = [[NSDateFormatter alloc] init];
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hma" options:0 locale:[NSLocale currentLocale]];
        [timeformatter setDateFormat:dateFormat];
        timeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return timeformatter;
}

NSBundle *ORKLegacyBundle() {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleForClass:[ORKLegacyStep class]];
    });
    return bundle;
}

NSBundle *ORKLegacyDefaultLocaleBundle() {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [ORKLegacyBundle() pathForResource:[ORKLegacyBundle() objectForInfoDictionaryKey:@"CFBundleDevelopmentRegion"] ofType:@"lproj"];
        bundle = [NSBundle bundleWithPath:path];
    });
    return bundle;
}

NSDateComponentsFormatter *ORKLegacyTimeIntervalLabelFormatter() {
    static NSDateComponentsFormatter *durationFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        durationFormatter = [[NSDateComponentsFormatter alloc] init];
        [durationFormatter setUnitsStyle:NSDateComponentsFormatterUnitsStyleFull];
        [durationFormatter setAllowedUnits:NSCalendarUnitHour | NSCalendarUnitMinute];
        [durationFormatter setFormattingContext:NSFormattingContextStandalone];
        [durationFormatter setMaximumUnitCount: 2];
    });
    return durationFormatter;
}

NSDateComponentsFormatter *ORKLegacyDurationStringFormatter() {
    static NSDateComponentsFormatter *durationFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        durationFormatter = [[NSDateComponentsFormatter alloc] init];
        [durationFormatter setUnitsStyle:NSDateComponentsFormatterUnitsStyleFull];
        [durationFormatter setAllowedUnits: NSCalendarUnitMinute | NSCalendarUnitSecond];
        [durationFormatter setFormattingContext:NSFormattingContextStandalone];
        [durationFormatter setMaximumUnitCount: 2];
    });
    return durationFormatter;
}

NSCalendar *ORKLegacyTimeOfDayReferenceCalendar() {
    static NSCalendar *calendar;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return calendar;
}

NSString *ORKLegacyTimeOfDayStringFromComponents(NSDateComponents *dateComponents) {
    static NSDateComponentsFormatter *timeOfDayFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeOfDayFormatter = [[NSDateComponentsFormatter alloc] init];
        [timeOfDayFormatter setUnitsStyle:NSDateComponentsFormatterUnitsStylePositional];
        [timeOfDayFormatter setAllowedUnits:NSCalendarUnitHour | NSCalendarUnitMinute];
        [timeOfDayFormatter setZeroFormattingBehavior:NSDateComponentsFormatterZeroFormattingBehaviorPad];
    });
    return [timeOfDayFormatter stringFromDateComponents:dateComponents];
}

NSDateComponents *ORKLegacyTimeOfDayComponentsFromString(NSString *string) {
    // NSDateComponentsFormatter don't support parsing, this is a work around.
    static NSDateFormatter *timeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeformatter = [[NSDateFormatter alloc] init];
        [timeformatter setDateFormat:@"HH:mm"];
        timeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    NSDate *date = [timeformatter dateFromString:string];
    return [ORKLegacyTimeOfDayReferenceCalendar() components:(NSCalendarUnitMinute |NSCalendarUnitHour) fromDate:date];
}

NSDateComponents *ORKLegacyTimeOfDayComponentsFromDate(NSDate *date) {
    if (date == nil) {
        return nil;
    }
    return [ORKLegacyTimeOfDayReferenceCalendar() components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date];
}

NSDate *ORKLegacyTimeOfDayDateFromComponents(NSDateComponents *dateComponents) {
    return [ORKLegacyTimeOfDayReferenceCalendar() dateFromComponents:dateComponents];
}

BOOL ORKLegacyCurrentLocalePresentsFamilyNameFirst() {
    NSString *language = [[NSLocale preferredLanguages].firstObject substringToIndex:2];
    static dispatch_once_t onceToken;
    static NSArray *familyNameFirstLanguages = nil;
    dispatch_once(&onceToken, ^{
        familyNameFirstLanguages = @[@"zh", @"ko", @"ja", @"vi"];
    });
    return (language != nil) && [familyNameFirstLanguages containsObject:language];
}

BOOL ORKLegacyWantsWideContentMargins(UIScreen *screen) {
    
    if (screen != [UIScreen mainScreen]) {
        return NO;
    }
   
    // If our screen's minimum dimension is bigger than a fixed threshold,
    // decide to use wide content margins. This is less restrictive than UIKit,
    // but a good enough approximation.
    CGRect screenRect = screen.bounds;
    CGFloat minDimension = MIN(screenRect.size.width, screenRect.size.height);
    BOOL isWideScreenFormat = (minDimension > 375.);
    
    return isWideScreenFormat;
}

#define ORKLegacy_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_REGULAR 20.0
#define ORKLegacy_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT 16.0
#define ORKLegacy_LAYOUT_MARGIN_WIDTH_REGULAR_BEZEL 15.0

CGFloat ORKLegacyTableViewLeftMargin(UITableView *tableView) {
    if (ORKLegacyWantsWideContentMargins(tableView.window.screen)) {
        if (CGRectGetWidth(tableView.frame) > 320.0) {
            return ORKLegacy_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_REGULAR;
            
        } else {
            return ORKLegacy_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT;
        }
    } else {
        // Probably should be ORKLegacy_LAYOUT_MARGIN_WIDTH_REGULAR_BEZEL
        return ORKLegacy_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT;
    }
}

UIFont *ORKLegacyThinFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightThin];
    } else {
        font = [UIFont fontWithName:@".HelveticaNeueInterface-Thin" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

UIFont *ORKLegacyMediumFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    } else {
        font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

UIFont *ORKLegacyLightFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightLight];
    } else {
        font = [UIFont fontWithName:@".HelveticaNeueInterface-Light" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

NSURL *ORKLegacyURLFromBookmarkData(NSData *data) {
    if (data == nil) {
        return nil;
    }
    
    BOOL bookmarkIsStale = NO;
    NSError *bookmarkError = nil;
    NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:data
                                                   options:NSURLBookmarkResolutionWithoutUI
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&bookmarkIsStale
                                                     error:&bookmarkError];
    if (!bookmarkURL) {
        ORKLegacy_Log_Warning(@"Error loading URL from bookmark: %@", bookmarkError);
    }
    
    return bookmarkURL;
}

NSData *ORKLegacyBookmarkDataFromURL(NSURL *url) {
    if (!url) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil
                                              error:&error];
    if (!bookmark) {
        ORKLegacy_Log_Warning(@"Error converting URL to bookmark: %@", error);
    }
    return bookmark;
}

NSString *ORKLegacyPathRelativeToURL(NSURL *url, NSURL *baseURL) {
    NSURL *standardizedURL = [url URLByStandardizingPath];
    NSURL *standardizedBaseURL = [baseURL URLByStandardizingPath];
    
    NSString *path = [standardizedURL absoluteString];
    NSString *basePath = [standardizedBaseURL absoluteString];
    
    if ([path hasPrefix:basePath]) {
        NSString *relativePath = [path substringFromIndex:basePath.length];
        if ([relativePath hasPrefix:@"/"]) {
            relativePath = [relativePath substringFromIndex:1];
        }
        return relativePath;
    } else {
        return path;
    }
}

static NSURL *ORKLegacyHomeDirectoryURL() {
    static NSURL *homeDirectoryURL = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    });
    return homeDirectoryURL;
}

NSURL *ORKLegacyURLForRelativePath(NSString *relativePath) {
    if (!relativePath) {
        return nil;
    }
    
    NSURL *homeDirectoryURL = ORKLegacyHomeDirectoryURL();
    NSURL *url = [NSURL fileURLWithFileSystemRepresentation:relativePath.fileSystemRepresentation isDirectory:NO relativeToURL:homeDirectoryURL];
    
    if (url != nil) {
        BOOL isDirectory = NO;;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];
        if (fileExists && isDirectory) {
            url = [NSURL fileURLWithFileSystemRepresentation:relativePath.fileSystemRepresentation isDirectory:YES relativeToURL:homeDirectoryURL];
        }
    }
    return url;
}
NSString *ORKLegacyRelativePathForURL(NSURL *url) {
    if (!url) {
        return nil;
    }
    
    return ORKLegacyPathRelativeToURL(url, ORKLegacyHomeDirectoryURL());
}

id ORKLegacyDynamicCast_(id x, Class objClass) {
    return [x isKindOfClass:objClass] ? x : nil;
}

const CGFloat ORKLegacyScrollToTopAnimationDuration = 0.2;

void ORKLegacyValidateArrayForObjectsOfClass(NSArray *array, Class expectedObjectClass, NSString *exceptionReason) {
    NSCParameterAssert(array);
    NSCParameterAssert(expectedObjectClass);
    NSCParameterAssert(exceptionReason);

    for (id object in array) {
        if (![object isKindOfClass:expectedObjectClass]) {
            @throw [NSException exceptionWithName:NSGenericException reason:exceptionReason userInfo:nil];
        }
    }
}

void ORKLegacyRemoveConstraintsForRemovedViews(NSMutableArray *constraints, NSArray *removedViews) {
    for (NSLayoutConstraint *constraint in [constraints copy]) {
        for (UIView *view in removedViews) {
            if (constraint.firstItem == view || constraint.secondItem == view) {
                [constraints removeObject:constraint];
            }
        }
    }
}

const double ORKLegacyDoubleInvalidValue = DBL_MAX;

const CGFloat ORKLegacyCGFloatInvalidValue = CGFLOAT_MAX;

void ORKLegacyAdjustPageViewControllerNavigationDirectionForRTL(UIPageViewControllerNavigationDirection *direction) {
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        *direction = (*direction == UIPageViewControllerNavigationDirectionForward) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
    }
}

NSString *ORKLegacyPaddingWithNumberOfSpaces(NSUInteger numberOfPaddingSpaces) {
    return [@"" stringByPaddingToLength:numberOfPaddingSpaces withString:@" " startingAtIndex:0];
}

NSNumberFormatter *ORKLegacyDecimalNumberFormatter() {
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.maximumFractionDigits = NSDecimalNoScale;
    numberFormatter.usesGroupingSeparator = NO;
    return numberFormatter;
}
