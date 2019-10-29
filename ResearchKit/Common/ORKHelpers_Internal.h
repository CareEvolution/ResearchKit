/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.

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
#import "ORKHelpers_Private.h"
#import "ORKTypes.h"
#import "ORKErrors.h"


NS_ASSUME_NONNULL_BEGIN

// Logging
#if ( defined(ORKLegacy_LOG_LEVEL_NONE) && ORKLegacy_LOG_LEVEL_NONE )
#  undef ORKLegacy_LOG_LEVEL_DEBUG
#  undef ORKLegacy_LOG_LEVEL_WARNING
#  undef ORKLegacy_LOG_LEVEL_ERROR
#endif

#if ( !defined(ORKLegacy_LOG_LEVEL_NONE) && !defined(ORKLegacy_LOG_LEVEL_DEBUG) && !defined(ORKLegacy_LOG_LEVEL_WARNING) && !defined(ORKLegacy_LOG_LEVEL_ERROR) )
#  define ORKLegacy_LOG_LEVEL_WARNING 1
#endif

#define _ORKLegacy_LogWithLevel(level,fmt,...) NSLog(@"[ResearchKit]["#level"] %s " fmt, __PRETTY_FUNCTION__, ## __VA_ARGS__)

#if ( ORKLegacy_LOG_LEVEL_DEBUG )
#  define ORKLegacy_Log_Debug(fmt,...) _ORKLegacy_LogWithLevel(Debug, fmt, ## __VA_ARGS__)
#else
#  define ORKLegacy_Log_Debug(...)
#endif

#if ( ORKLegacy_LOG_LEVEL_DEBUG || ORKLegacy_LOG_LEVEL_WARNING )
#  define ORKLegacy_Log_Warning(fmt,...) _ORKLegacy_LogWithLevel(Warning, fmt, ## __VA_ARGS__)
#else
#  define ORKLegacy_Log_Warning(...)
#endif

#if ( ORKLegacy_LOG_LEVEL_DEBUG || ORKLegacy_LOG_LEVEL_WARNING || ORKLegacy_LOG_LEVEL_ERROR )
#  define ORKLegacy_Log_Error(fmt,...) _ORKLegacy_LogWithLevel(Error, fmt, ## __VA_ARGS__)
#else
#  define ORKLegacy_Log_Error(...)
#endif


#define ORKLegacy_NARG(...) ORKLegacy_NARG_(__VA_ARGS__,ORKLegacy_RSEQ_N())
#define ORKLegacy_NARG_(...)  ORKLegacy_ARG_N(__VA_ARGS__)
#define ORKLegacy_ARG_N( _1, _2, _3, _4, _5, _6, _7, _8, _9,_10, N, ...) N
#define ORKLegacy_RSEQ_N()   10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0

#define ORKLegacy_DECODE_OBJ(d,x)  _ ## x = [d decodeObjectForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_OBJ(c,x)  [c encodeObject:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_URL(c,x)  [c encodeObject:ORKLegacyRelativePathForURL(_ ## x) forKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_URL_BOOKMARK(c, x) [c encodeObject:ORKLegacyBookmarkDataFromURL(_ ## x) forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_OBJ_CLASS(d,x,cl)  _ ## x = (cl *)[d decodeObjectOfClass:[cl class] forKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_DECODE_OBJ_ARRAY(d,x,cl)  _ ## x = (NSArray *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class],[cl class],nil] forKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_DECODE_OBJ_MUTABLE_ORDERED_SET(d,x,cl)  _ ## x = [(NSOrderedSet *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSOrderedSet class],[cl class],nil] forKey:@ORKLegacy_STRINGIFY(x)] mutableCopy]
#define ORKLegacy_DECODE_OBJ_MUTABLE_DICTIONARY(d,x,kcl,cl)  _ ## x = [(NSDictionary *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class],[kcl class],[cl class],nil] forKey:@ORKLegacy_STRINGIFY(x)] mutableCopy]

#define ORKLegacy_ENCODE_COND_OBJ(c,x)  [c encodeConditionalObject:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_IMAGE(d,x)  _ ## x = (UIImage *)[d decodeObjectOfClass:[UIImage class] forKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_IMAGE(c,x)  { if (_ ## x) { UIImage * orkTemp_ ## x = [UIImage imageWithCGImage:[_ ## x CGImage] scale:[_ ## x scale] orientation:[_ ## x imageOrientation]]; [c encodeObject:orkTemp_ ## x forKey:@ORKLegacy_STRINGIFY(x)]; } }

#define ORKLegacy_DECODE_URL(d,x)  _ ## x = ORKLegacyURLForRelativePath((NSString *)[d decodeObjectOfClass:[NSString class] forKey:@ORKLegacy_STRINGIFY(x)])
#define ORKLegacy_DECODE_URL_BOOKMARK(d,x)  _ ## x = ORKLegacyURLFromBookmarkData((NSData *)[d decodeObjectOfClass:[NSData class] forKey:@ORKLegacy_STRINGIFY(x)])

#define ORKLegacy_DECODE_BOOL(d,x)  _ ## x = [d decodeBoolForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_BOOL(c,x)  [c encodeBool:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_DOUBLE(d,x)  _ ## x = [d decodeDoubleForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_DOUBLE(c,x)  [c encodeDouble:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_INTEGER(d,x)  _ ## x = [d decodeIntegerForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_INTEGER(c,x)  [c encodeInteger:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_ENCODE_UINT32(c,x)  [c encodeObject:[NSNumber numberWithUnsignedLongLong:_ ## x] forKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_DECODE_UINT32(d,x)  _ ## x = (uint32_t)[(NSNumber *)[d decodeObjectForKey:@ORKLegacy_STRINGIFY(x)] unsignedLongValue]

#define ORKLegacy_DECODE_ENUM(d,x)  _ ## x = [d decodeIntegerForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_ENUM(c,x)  [c encodeInteger:(NSInteger)_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_CGRECT(d,x)  _ ## x = [d decodeCGRectForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_CGRECT(c,x)  [c encodeCGRect:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_CGSIZE(d,x)  _ ## x = [d decodeCGSizeForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_CGSIZE(c,x)  [c encodeCGSize:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_CGPOINT(d,x)  _ ## x = [d decodeCGPointForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_CGPOINT(c,x)  [c encodeCGPoint:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_UIEDGEINSETS(d,x)  _ ## x = [d decodeUIEdgeInsetsForKey:@ORKLegacy_STRINGIFY(x)]
#define ORKLegacy_ENCODE_UIEDGEINSETS(c,x)  [c encodeUIEdgeInsets:_ ## x forKey:@ORKLegacy_STRINGIFY(x)]

#define ORKLegacy_DECODE_COORDINATE(d,x)  _ ## x = CLLocationCoordinate2DMake([d decodeDoubleForKey:@ORKLegacy_STRINGIFY(x.latitude)],[d decodeDoubleForKey:@ORKLegacy_STRINGIFY(x.longitude)])
#define ORKLegacy_ENCODE_COORDINATE(c,x)  [c encodeDouble:_ ## x.latitude forKey:@ORKLegacy_STRINGIFY(x.latitude)];[c encodeDouble:_ ## x.longitude forKey:@ORKLegacy_STRINGIFY(x.longitude)];

/*
 * Helpers for completions which call the block only if non-nil
 *
 */
#define ORKLegacy_BLOCK_EXEC(block, ...) if (block) { block(__VA_ARGS__); };

#define ORKLegacy_DISPATCH_EXEC(queue, block, ...) if (block) { dispatch_async(queue, ^{ block(__VA_ARGS__); } ); }

/*
 * For testing background delivery
 *
 */
#if ORKLegacy_BACKGROUND_DELIVERY_TEST
#  define ORKLegacy_HEALTH_UPDATE_FREQUENCY HKUpdateFrequencyImmediate
#else
#  define ORKLegacy_HEALTH_UPDATE_FREQUENCY HKUpdateFrequencyDaily
#endif

// Find the first object of the specified class, using method as the iterator
#define ORKLegacyFirstObjectOfClass(C,p,method) ({ id v = p; while (v != nil) { if ([v isKindOfClass:[C class]]) { break; } else { v = [v method]; } }; v; })

#define ORKLegacyStrongTypeOf(x) __strong __typeof(x)
#define ORKLegacyWeakTypeOf(x) __weak __typeof(x)

// Bundle for video assets
NSBundle *ORKLegacyAssetsBundle(void);
NSBundle *ORKLegacyBundle(void);
NSBundle *ORKLegacyDefaultLocaleBundle(void);

// Pass 0xcccccc and get color #cccccc
UIColor *ORKLegacyRGB(uint32_t x);
UIColor *ORKLegacyRGBA(uint32_t x, CGFloat alpha);

id findInArrayByKey(NSArray * array, NSString *key, id value);

NSString *ORKLegacySignatureStringFromDate(NSDate *date);

NSURL *ORKLegacyCreateRandomBaseURL(void);

// Marked extern so it is accessible to unit tests
ORKLegacy_EXTERN NSString *ORKLegacyFileProtectionFromMode(ORKLegacyFileProtectionMode mode);

CGFloat ORKLegacyExpectedLabelHeight(UILabel *label);
void ORKLegacyAdjustHeightForLabel(UILabel *label);

// build a image with color
UIImage *ORKLegacyImageWithColor(UIColor *color);

void ORKLegacyEnableAutoLayoutForViews(NSArray *views);

NSDateComponentsFormatter *ORKLegacyTimeIntervalLabelFormatter(void);
NSDateComponentsFormatter *ORKLegacyDurationStringFormatter(void);

NSDateFormatter *ORKLegacyTimeOfDayLabelFormatter(void);
NSCalendar *ORKLegacyTimeOfDayReferenceCalendar(void);

NSDateComponents *ORKLegacyTimeOfDayComponentsFromDate(NSDate *date);
NSDate *ORKLegacyTimeOfDayDateFromComponents(NSDateComponents *dateComponents);

BOOL ORKLegacyCurrentLocalePresentsFamilyNameFirst(void);

UIFont *ORKLegacyTimeFontForSize(CGFloat size);
UIFontDescriptor *ORKLegacyFontDescriptorForLightStylisticAlternative(UIFontDescriptor *descriptor);

CGFloat ORKLegacyFloorToViewScale(CGFloat value, UIView *view);

ORKLegacy_INLINE bool
ORKLegacyEqualObjects(id o1, id o2) {
    return (o1 == o2) || (o1 && o2 && [o1 isEqual:o2]);
}

ORKLegacy_INLINE BOOL
ORKLegacyEqualFileURLs(NSURL *url1, NSURL *url2) {
    return ORKLegacyEqualObjects(url1, url2) || ([url1 isFileURL] && [url2 isFileURL] && [[url1 absoluteString] isEqualToString:[url2 absoluteString]]);
}

ORKLegacy_INLINE NSMutableOrderedSet *
ORKLegacyMutableOrderedSetCopyObjects(NSOrderedSet *a) {
    if (!a) {
        return nil;
    }
    NSMutableOrderedSet *b = [NSMutableOrderedSet orderedSetWithCapacity:a.count];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [b addObject:[obj copy]];
    }];
    return b;
}

ORKLegacy_INLINE NSMutableDictionary *
ORKLegacyMutableDictionaryCopyObjects(NSDictionary *a) {
    if (!a) {
        return nil;
    }
    NSMutableDictionary *b = [NSMutableDictionary dictionaryWithCapacity:a.count];
    [a enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        b[key] = [obj copy];
    }];
    return b;
}

#define ORKLegacySuppressPerformSelectorWarning(PerformCall) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
PerformCall; \
_Pragma("clang diagnostic pop") \
} while (0)

UIFont *ORKLegacyThinFontWithSize(CGFloat size);
UIFont *ORKLegacyLightFontWithSize(CGFloat size);
UIFont *ORKLegacyMediumFontWithSize(CGFloat size);

NSURL *ORKLegacyURLFromBookmarkData(NSData *data);
NSData *ORKLegacyBookmarkDataFromURL(NSURL *url);

NSString *ORKLegacyPathRelativeToURL(NSURL *url, NSURL *baseURL);
NSURL *ORKLegacyURLForRelativePath(NSString *relativePath);
NSString *ORKLegacyRelativePathForURL(NSURL *url);

id ORKLegacyDynamicCast_(id x, Class objClass);

#define ORKLegacyDynamicCast(x, c) ((c *) ORKLegacyDynamicCast_(x, [c class]))

extern const CGFloat ORKLegacyScrollToTopAnimationDuration;

ORKLegacy_INLINE CGFloat
ORKLegacyCGFloatNearlyEqualToFloat(CGFloat f1, CGFloat f2) {
    const CGFloat ORKLegacyCGFloatEpsilon = 0.01; // 0.01 should be safe enough when dealing with screen point and pixel values
    return (ABS(f1 - f2) <= ORKLegacyCGFloatEpsilon);
}

#define ORKLegacyThrowMethodUnavailableException()  @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"method unavailable" userInfo:nil];
#define ORKLegacyThrowInvalidArgumentExceptionIfNil(argument)  if (!argument) { @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@#argument" cannot be nil." userInfo:nil]; }

void ORKLegacyValidateArrayForObjectsOfClass(NSArray *array, Class expectedObjectClass, NSString *exceptionReason);

void ORKLegacyRemoveConstraintsForRemovedViews(NSMutableArray *constraints, NSArray *removedViews);

extern const double ORKLegacyDoubleInvalidValue;

extern const CGFloat ORKLegacyCGFloatInvalidValue;

void ORKLegacyAdjustPageViewControllerNavigationDirectionForRTL(UIPageViewControllerNavigationDirection *direction);

NSString *ORKLegacyPaddingWithNumberOfSpaces(NSUInteger numberOfPaddingSpaces);

NSNumberFormatter *ORKLegacyDecimalNumberFormatter(void);

ORKLegacy_INLINE double ORKLegacyFeetAndInchesToInches(double feet, double inches) {
    return (feet * 12) + inches;
}

ORKLegacy_INLINE void ORKLegacyInchesToFeetAndInches(double inches, double *outFeet, double *outInches) {
    if (outFeet == NULL || outInches == NULL) {
        return;
    }
    *outFeet = floor(inches / 12);
    *outInches = fmod(inches, 12);
}

ORKLegacy_INLINE double ORKLegacyInchesToCentimeters(double inches) {
    return inches * 2.54;
}

ORKLegacy_INLINE double ORKLegacyCentimetersToInches(double centimeters) {
    return centimeters / 2.54;
}

ORKLegacy_INLINE void ORKLegacyCentimetersToFeetAndInches(double centimeters, double *outFeet, double *outInches) {
    double inches = ORKLegacyCentimetersToInches(centimeters);
    ORKLegacyInchesToFeetAndInches(inches, outFeet, outInches);
}

ORKLegacy_INLINE double ORKLegacyFeetAndInchesToCentimeters(double feet, double inches) {
    return ORKLegacyInchesToCentimeters(ORKLegacyFeetAndInchesToInches(feet, inches));
}

ORKLegacy_INLINE void ORKLegacyKilogramsToWholeAndFraction(double kilograms, double *outWhole, double *outFraction) {
    if (outWhole == NULL || outFraction == NULL) {
        return;
    }
    *outWhole = floor(kilograms);
    *outFraction = round((kilograms - floor(kilograms)) * 100);
}

ORKLegacy_INLINE void ORKLegacyKilogramsToPoundsAndOunces(double kilograms, double * _Nullable outPounds, double * _Nullable outOunces) {
    const double ORKLegacyPoundsPerKilogram = 2.20462262;
    double fractionalPounds = kilograms * ORKLegacyPoundsPerKilogram;
    double pounds = floor(fractionalPounds);
    double ounces = round((fractionalPounds - pounds) * 16);
    if (ounces == 16) {
        pounds += 1;
        ounces = 0;
    }
    if (outPounds != NULL) {
        *outPounds = pounds;
    }
    if (outOunces != NULL) {
        *outOunces = ounces;
    }
}

ORKLegacy_INLINE double ORKLegacyKilogramsToPounds(double kilograms) {
    double pounds;
    ORKLegacyKilogramsToPoundsAndOunces(kilograms, &pounds, NULL);
    return pounds;
}

ORKLegacy_INLINE double ORKLegacyWholeAndFractionToKilograms(double whole, double fraction) {
    double kg = (whole + (fraction / 100));
    return (round(100 * kg) / 100);
}

ORKLegacy_INLINE double ORKLegacyPoundsAndOuncesToKilograms(double pounds, double ounces) {
    const double ORKLegacyKilogramsPerPound = 0.45359237;
    double kg = (pounds + (ounces / 16)) * ORKLegacyKilogramsPerPound;
    return (round(100 * kg) / 100);
}

ORKLegacy_INLINE double ORKLegacyPoundsToKilograms(double pounds) {
    return ORKLegacyPoundsAndOuncesToKilograms(pounds, 0);
}

ORKLegacy_INLINE UIColor *ORKLegacyOpaqueColorWithReducedAlphaFromBaseColor(UIColor *baseColor, NSUInteger colorIndex, NSUInteger totalColors) {
    UIColor *color = baseColor;
    if (totalColors > 1) {
        CGFloat red = 0.0;
        CGFloat green = 0.0;
        CGFloat blue = 0.0;
        CGFloat alpha = 0.0;
        if ([baseColor getRed:&red green:&green blue:&blue alpha:&alpha]) {
            // Avoid a pure transparent color (alpha = 0)
            CGFloat targetAlphaFactor = ((1.0 / totalColors) * colorIndex);
            return [UIColor colorWithRed:red + ((1.0 - red) * targetAlphaFactor)
                                   green:green + ((1.0 - green) * targetAlphaFactor)
                                    blue:blue + ((1.0 - blue) * targetAlphaFactor)
                                   alpha:alpha];
        }
    }
    return color;
}

// Localization
ORKLegacy_EXTERN NSBundle *ORKLegacyBundle(void) ORKLegacy_AVAILABLE_DECL;
ORKLegacy_EXTERN NSBundle *ORKLegacyDefaultLocaleBundle(void);

#define ORKLegacyDefaultLocalizedValue(key) \
[ORKLegacyDefaultLocaleBundle() localizedStringForKey:key value:@"" table:@"ResearchKit"]

#define ORKLegacyLocalizedString(key, comment) \
[ORKLegacyBundle() localizedStringForKey:(key) value:ORKLegacyDefaultLocalizedValue(key) table:@"ResearchKit"]

#define ORKLegacyLocalizedStringFromNumber(number) \
[NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterNoStyle]

NS_ASSUME_NONNULL_END
