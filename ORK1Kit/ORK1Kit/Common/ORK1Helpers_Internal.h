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
#import "ORK1Helpers_Private.h"
#import "ORK1Types.h"
#import "ORK1Errors.h"


NS_ASSUME_NONNULL_BEGIN

// Logging
#if ( defined(ORK1_LOG_LEVEL_NONE) && ORK1_LOG_LEVEL_NONE )
#  undef ORK1_LOG_LEVEL_DEBUG
#  undef ORK1_LOG_LEVEL_WARNING
#  undef ORK1_LOG_LEVEL_ERROR
#endif

#if ( !defined(ORK1_LOG_LEVEL_NONE) && !defined(ORK1_LOG_LEVEL_DEBUG) && !defined(ORK1_LOG_LEVEL_WARNING) && !defined(ORK1_LOG_LEVEL_ERROR) )
#  define ORK1_LOG_LEVEL_WARNING 1
#endif

#define _ORK1_LogWithLevel(level,fmt,...) NSLog(@"[ORK1Kit]["#level"] %s " fmt, __PRETTY_FUNCTION__, ## __VA_ARGS__)

#if ( ORK1_LOG_LEVEL_DEBUG )
#  define ORK1_Log_Debug(fmt,...) _ORK1_LogWithLevel(Debug, fmt, ## __VA_ARGS__)
#else
#  define ORK1_Log_Debug(...)
#endif

#if ( ORK1_LOG_LEVEL_DEBUG || ORK1_LOG_LEVEL_WARNING )
#  define ORK1_Log_Warning(fmt,...) _ORK1_LogWithLevel(Warning, fmt, ## __VA_ARGS__)
#else
#  define ORK1_Log_Warning(...)
#endif

#if ( ORK1_LOG_LEVEL_DEBUG || ORK1_LOG_LEVEL_WARNING || ORK1_LOG_LEVEL_ERROR )
#  define ORK1_Log_Error(fmt,...) _ORK1_LogWithLevel(Error, fmt, ## __VA_ARGS__)
#else
#  define ORK1_Log_Error(...)
#endif


#define ORK1_NARG(...) ORK1_NARG_(__VA_ARGS__,ORK1_RSEQ_N())
#define ORK1_NARG_(...)  ORK1_ARG_N(__VA_ARGS__)
#define ORK1_ARG_N( _1, _2, _3, _4, _5, _6, _7, _8, _9,_10, N, ...) N
#define ORK1_RSEQ_N()   10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0

#define ORK1_DECODE_OBJ(d,x)  _ ## x = [d decodeObjectForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_OBJ(c,x)  [c encodeObject:_ ## x forKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_URL(c,x)  [c encodeObject:ORK1RelativePathForURL(_ ## x) forKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_URL_BOOKMARK(c, x) [c encodeObject:ORK1BookmarkDataFromURL(_ ## x) forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_OBJ_CLASS(d,x,cl)  _ ## x = (cl *)[d decodeObjectOfClass:[cl class] forKey:@ORK1_STRINGIFY(x)]
#define ORK1_DECODE_OBJ_ARRAY(d,x,cl)  _ ## x = (NSArray *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class],[cl class],nil] forKey:@ORK1_STRINGIFY(x)]
#define ORK1_DECODE_OBJ_MUTABLE_ORDERED_SET(d,x,cl)  _ ## x = [(NSOrderedSet *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSOrderedSet class],[cl class],nil] forKey:@ORK1_STRINGIFY(x)] mutableCopy]
#define ORK1_DECODE_OBJ_MUTABLE_DICTIONARY(d,x,kcl,cl)  _ ## x = [(NSDictionary *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class],[kcl class],[cl class],nil] forKey:@ORK1_STRINGIFY(x)] mutableCopy]

#define ORK1_ENCODE_COND_OBJ(c,x)  [c encodeConditionalObject:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_IMAGE(d,x)  _ ## x = (UIImage *)[d decodeObjectOfClass:[UIImage class] forKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_IMAGE(c,x)  { if (_ ## x) { UIImage * orkTemp_ ## x = [UIImage imageWithCGImage:[_ ## x CGImage] scale:[_ ## x scale] orientation:[_ ## x imageOrientation]]; [c encodeObject:orkTemp_ ## x forKey:@ORK1_STRINGIFY(x)]; } }

#define ORK1_DECODE_URL(d,x)  _ ## x = ORK1URLForRelativePath((NSString *)[d decodeObjectOfClass:[NSString class] forKey:@ORK1_STRINGIFY(x)])
#define ORK1_DECODE_URL_BOOKMARK(d,x)  _ ## x = ORK1URLFromBookmarkData((NSData *)[d decodeObjectOfClass:[NSData class] forKey:@ORK1_STRINGIFY(x)])

#define ORK1_DECODE_BOOL(d,x)  _ ## x = [d decodeBoolForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_BOOL(c,x)  [c encodeBool:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_DOUBLE(d,x)  _ ## x = [d decodeDoubleForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_DOUBLE(c,x)  [c encodeDouble:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_INTEGER(d,x)  _ ## x = [d decodeIntegerForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_INTEGER(c,x)  [c encodeInteger:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_ENCODE_UINT32(c,x)  [c encodeObject:[NSNumber numberWithUnsignedLongLong:_ ## x] forKey:@ORK1_STRINGIFY(x)]
#define ORK1_DECODE_UINT32(d,x)  _ ## x = (uint32_t)[(NSNumber *)[d decodeObjectForKey:@ORK1_STRINGIFY(x)] unsignedLongValue]

#define ORK1_DECODE_ENUM(d,x)  _ ## x = [d decodeIntegerForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_ENUM(c,x)  [c encodeInteger:(NSInteger)_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_CGRECT(d,x)  _ ## x = [d decodeCGRectForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_CGRECT(c,x)  [c encodeCGRect:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_CGSIZE(d,x)  _ ## x = [d decodeCGSizeForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_CGSIZE(c,x)  [c encodeCGSize:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_CGPOINT(d,x)  _ ## x = [d decodeCGPointForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_CGPOINT(c,x)  [c encodeCGPoint:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_UIEDGEINSETS(d,x)  _ ## x = [d decodeUIEdgeInsetsForKey:@ORK1_STRINGIFY(x)]
#define ORK1_ENCODE_UIEDGEINSETS(c,x)  [c encodeUIEdgeInsets:_ ## x forKey:@ORK1_STRINGIFY(x)]

#define ORK1_DECODE_COORDINATE(d,x)  _ ## x = CLLocationCoordinate2DMake([d decodeDoubleForKey:@ORK1_STRINGIFY(x.latitude)],[d decodeDoubleForKey:@ORK1_STRINGIFY(x.longitude)])
#define ORK1_ENCODE_COORDINATE(c,x)  [c encodeDouble:_ ## x.latitude forKey:@ORK1_STRINGIFY(x.latitude)];[c encodeDouble:_ ## x.longitude forKey:@ORK1_STRINGIFY(x.longitude)];

/*
 * Helpers for completions which call the block only if non-nil
 *
 */
#define ORK1_BLOCK_EXEC(block, ...) if (block) { block(__VA_ARGS__); };

#define ORK1_DISPATCH_EXEC(queue, block, ...) if (block) { dispatch_async(queue, ^{ block(__VA_ARGS__); } ); }

/*
 * For testing background delivery
 *
 */
#if ORK1_BACKGROUND_DELIVERY_TEST
#  define ORK1_HEALTH_UPDATE_FREQUENCY HKUpdateFrequencyImmediate
#else
#  define ORK1_HEALTH_UPDATE_FREQUENCY HKUpdateFrequencyDaily
#endif

// Find the first object of the specified class, using method as the iterator
#define ORK1FirstObjectOfClass(C,p,method) ({ id v = p; while (v != nil) { if ([v isKindOfClass:[C class]]) { break; } else { v = [v method]; } }; v; })

#define ORK1StrongTypeOf(x) __strong __typeof(x)
#define ORK1WeakTypeOf(x) __weak __typeof(x)

// Bundle for video assets
NSBundle *ORK1AssetsBundle(void);
NSBundle *ORK1Bundle(void);
NSBundle *ORK1DefaultLocaleBundle(void);

// Pass 0xcccccc and get color #cccccc
UIColor *ORK1RGB(uint32_t x);
UIColor *ORK1RGBA(uint32_t x, CGFloat alpha);

id findInArrayByKey(NSArray * array, NSString *key, id value);

NSString *ORK1SignatureStringFromDate(NSDate *date);

NSURL *ORK1CreateRandomBaseURL(void);

// Marked extern so it is accessible to unit tests
ORK1_EXTERN NSString *ORK1FileProtectionFromMode(ORK1FileProtectionMode mode);

CGFloat ORK1ExpectedLabelHeight(UILabel *label);
void ORK1AdjustHeightForLabel(UILabel *label);

// build a image with color
UIImage *ORK1ImageWithColor(UIColor *color);

void ORK1EnableAutoLayoutForViews(NSArray *views);

NSDateComponentsFormatter *ORK1TimeIntervalLabelFormatter(void);
NSDateComponentsFormatter *ORK1DurationStringFormatter(void);

NSDateFormatter *ORK1TimeOfDayLabelFormatter(void);
NSCalendar *ORK1TimeOfDayReferenceCalendar(void);

NSDateComponents *ORK1TimeOfDayComponentsFromDate(NSDate *date);
NSDate *ORK1TimeOfDayDateFromComponents(NSDateComponents *dateComponents);

BOOL ORK1CurrentLocalePresentsFamilyNameFirst(void);

UIFont *ORK1TimeFontForSize(CGFloat size);
UIFontDescriptor *ORK1FontDescriptorForLightStylisticAlternative(UIFontDescriptor *descriptor);

CGFloat ORK1FloorToViewScale(CGFloat value, UIView *view);

ORK1_INLINE bool
ORK1EqualObjects(id o1, id o2) {
    return (o1 == o2) || (o1 && o2 && [o1 isEqual:o2]);
}

ORK1_INLINE BOOL
ORK1EqualFileURLs(NSURL *url1, NSURL *url2) {
    return ORK1EqualObjects(url1, url2) || ([url1 isFileURL] && [url2 isFileURL] && [[url1 absoluteString] isEqualToString:[url2 absoluteString]]);
}

ORK1_INLINE NSMutableOrderedSet *
ORK1MutableOrderedSetCopyObjects(NSOrderedSet *a) {
    if (!a) {
        return nil;
    }
    NSMutableOrderedSet *b = [NSMutableOrderedSet orderedSetWithCapacity:a.count];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [b addObject:[obj copy]];
    }];
    return b;
}

ORK1_INLINE NSMutableDictionary *
ORK1MutableDictionaryCopyObjects(NSDictionary *a) {
    if (!a) {
        return nil;
    }
    NSMutableDictionary *b = [NSMutableDictionary dictionaryWithCapacity:a.count];
    [a enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        b[key] = [obj copy];
    }];
    return b;
}

#define ORK1SuppressPerformSelectorWarning(PerformCall) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
PerformCall; \
_Pragma("clang diagnostic pop") \
} while (0)

UIFont *ORK1ThinFontWithSize(CGFloat size);
UIFont *ORK1LightFontWithSize(CGFloat size);
UIFont *ORK1MediumFontWithSize(CGFloat size);

NSURL *ORK1URLFromBookmarkData(NSData *data);
NSData *ORK1BookmarkDataFromURL(NSURL *url);

NSString *ORK1PathRelativeToURL(NSURL *url, NSURL *baseURL);
NSURL *ORK1URLForRelativePath(NSString *relativePath);
NSString *ORK1RelativePathForURL(NSURL *url);

id ORK1DynamicCast_(id x, Class objClass);

#define ORK1DynamicCast(x, c) ((c *) ORK1DynamicCast_(x, [c class]))

extern const CGFloat ORK1ScrollToTopAnimationDuration;

ORK1_INLINE CGFloat
ORK1CGFloatNearlyEqualToFloat(CGFloat f1, CGFloat f2) {
    const CGFloat ORK1CGFloatEpsilon = 0.01; // 0.01 should be safe enough when dealing with screen point and pixel values
    return (ABS(f1 - f2) <= ORK1CGFloatEpsilon);
}

#define ORK1ThrowMethodUnavailableException()  @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"method unavailable" userInfo:nil];
#define ORK1ThrowInvalidArgumentExceptionIfNil(argument)  if (!argument) { @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@#argument" cannot be nil." userInfo:nil]; }

void ORK1ValidateArrayForObjectsOfClass(NSArray *array, Class expectedObjectClass, NSString *exceptionReason);

void ORK1RemoveConstraintsForRemovedViews(NSMutableArray *constraints, NSArray *removedViews);

extern const double ORK1DoubleInvalidValue;

extern const CGFloat ORK1CGFloatInvalidValue;

void ORK1AdjustPageViewControllerNavigationDirectionForRTL(UIPageViewControllerNavigationDirection *direction);

NSString *ORK1PaddingWithNumberOfSpaces(NSUInteger numberOfPaddingSpaces);

NSNumberFormatter *ORK1DecimalNumberFormatter(void);

ORK1_INLINE double ORK1FeetAndInchesToInches(double feet, double inches) {
    return (feet * 12) + inches;
}

ORK1_INLINE void ORK1InchesToFeetAndInches(double inches, double *outFeet, double *outInches) {
    if (outFeet == NULL || outInches == NULL) {
        return;
    }
    *outFeet = floor(inches / 12);
    *outInches = fmod(inches, 12);
}

ORK1_INLINE double ORK1InchesToCentimeters(double inches) {
    return inches * 2.54;
}

ORK1_INLINE double ORK1CentimetersToInches(double centimeters) {
    return centimeters / 2.54;
}

ORK1_INLINE void ORK1CentimetersToFeetAndInches(double centimeters, double *outFeet, double *outInches) {
    double inches = ORK1CentimetersToInches(centimeters);
    ORK1InchesToFeetAndInches(inches, outFeet, outInches);
}

ORK1_INLINE double ORK1FeetAndInchesToCentimeters(double feet, double inches) {
    return ORK1InchesToCentimeters(ORK1FeetAndInchesToInches(feet, inches));
}

ORK1_INLINE void ORK1KilogramsToWholeAndFraction(double kilograms, double *outWhole, double *outFraction) {
    if (outWhole == NULL || outFraction == NULL) {
        return;
    }
    *outWhole = floor(kilograms);
    *outFraction = round((kilograms - floor(kilograms)) * 100);
}

ORK1_INLINE void ORK1KilogramsToPoundsAndOunces(double kilograms, double * _Nullable outPounds, double * _Nullable outOunces) {
    const double ORK1PoundsPerKilogram = 2.20462262;
    double fractionalPounds = kilograms * ORK1PoundsPerKilogram;
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

ORK1_INLINE double ORK1KilogramsToPounds(double kilograms) {
    double pounds;
    ORK1KilogramsToPoundsAndOunces(kilograms, &pounds, NULL);
    return pounds;
}

ORK1_INLINE double ORK1WholeAndFractionToKilograms(double whole, double fraction) {
    double kg = (whole + (fraction / 100));
    return (round(100 * kg) / 100);
}

ORK1_INLINE double ORK1PoundsAndOuncesToKilograms(double pounds, double ounces) {
    const double ORK1KilogramsPerPound = 0.45359237;
    double kg = (pounds + (ounces / 16)) * ORK1KilogramsPerPound;
    return (round(100 * kg) / 100);
}

ORK1_INLINE double ORK1PoundsToKilograms(double pounds) {
    return ORK1PoundsAndOuncesToKilograms(pounds, 0);
}

ORK1_INLINE UIColor *ORK1OpaqueColorWithReducedAlphaFromBaseColor(UIColor *baseColor, NSUInteger colorIndex, NSUInteger totalColors) {
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
ORK1_EXTERN NSBundle *ORK1Bundle(void) ORK1_AVAILABLE_DECL;
ORK1_EXTERN NSBundle *ORK1DefaultLocaleBundle(void);

#define ORK1DefaultLocalizedValue(key) \
[ORK1DefaultLocaleBundle() localizedStringForKey:key value:@"" table:@"ORK1Kit"]

#define ORK1LocalizedString(key, comment) \
[ORK1Bundle() localizedStringForKey:(key) value:ORK1DefaultLocalizedValue(key) table:@"ORK1Kit"]

#define ORK1LocalizedStringFromNumber(number) \
[NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterNoStyle]

NS_ASSUME_NONNULL_END
