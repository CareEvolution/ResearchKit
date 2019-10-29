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
#import "RK1Helpers_Private.h"
#import "RK1Types.h"
#import "RK1Errors.h"


NS_ASSUME_NONNULL_BEGIN

// Logging
#if ( defined(RK1_LOG_LEVEL_NONE) && RK1_LOG_LEVEL_NONE )
#  undef RK1_LOG_LEVEL_DEBUG
#  undef RK1_LOG_LEVEL_WARNING
#  undef RK1_LOG_LEVEL_ERROR
#endif

#if ( !defined(RK1_LOG_LEVEL_NONE) && !defined(RK1_LOG_LEVEL_DEBUG) && !defined(RK1_LOG_LEVEL_WARNING) && !defined(RK1_LOG_LEVEL_ERROR) )
#  define RK1_LOG_LEVEL_WARNING 1
#endif

#define _RK1_LogWithLevel(level,fmt,...) NSLog(@"[ResearchKit]["#level"] %s " fmt, __PRETTY_FUNCTION__, ## __VA_ARGS__)

#if ( RK1_LOG_LEVEL_DEBUG )
#  define RK1_Log_Debug(fmt,...) _RK1_LogWithLevel(Debug, fmt, ## __VA_ARGS__)
#else
#  define RK1_Log_Debug(...)
#endif

#if ( RK1_LOG_LEVEL_DEBUG || RK1_LOG_LEVEL_WARNING )
#  define RK1_Log_Warning(fmt,...) _RK1_LogWithLevel(Warning, fmt, ## __VA_ARGS__)
#else
#  define RK1_Log_Warning(...)
#endif

#if ( RK1_LOG_LEVEL_DEBUG || RK1_LOG_LEVEL_WARNING || RK1_LOG_LEVEL_ERROR )
#  define RK1_Log_Error(fmt,...) _RK1_LogWithLevel(Error, fmt, ## __VA_ARGS__)
#else
#  define RK1_Log_Error(...)
#endif


#define RK1_NARG(...) RK1_NARG_(__VA_ARGS__,RK1_RSEQ_N())
#define RK1_NARG_(...)  RK1_ARG_N(__VA_ARGS__)
#define RK1_ARG_N( _1, _2, _3, _4, _5, _6, _7, _8, _9,_10, N, ...) N
#define RK1_RSEQ_N()   10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0

#define RK1_DECODE_OBJ(d,x)  _ ## x = [d decodeObjectForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_OBJ(c,x)  [c encodeObject:_ ## x forKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_URL(c,x)  [c encodeObject:RK1RelativePathForURL(_ ## x) forKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_URL_BOOKMARK(c, x) [c encodeObject:RK1BookmarkDataFromURL(_ ## x) forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_OBJ_CLASS(d,x,cl)  _ ## x = (cl *)[d decodeObjectOfClass:[cl class] forKey:@RK1_STRINGIFY(x)]
#define RK1_DECODE_OBJ_ARRAY(d,x,cl)  _ ## x = (NSArray *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class],[cl class],nil] forKey:@RK1_STRINGIFY(x)]
#define RK1_DECODE_OBJ_MUTABLE_ORDERED_SET(d,x,cl)  _ ## x = [(NSOrderedSet *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSOrderedSet class],[cl class],nil] forKey:@RK1_STRINGIFY(x)] mutableCopy]
#define RK1_DECODE_OBJ_MUTABLE_DICTIONARY(d,x,kcl,cl)  _ ## x = [(NSDictionary *)[d decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class],[kcl class],[cl class],nil] forKey:@RK1_STRINGIFY(x)] mutableCopy]

#define RK1_ENCODE_COND_OBJ(c,x)  [c encodeConditionalObject:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_IMAGE(d,x)  _ ## x = (UIImage *)[d decodeObjectOfClass:[UIImage class] forKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_IMAGE(c,x)  { if (_ ## x) { UIImage * orkTemp_ ## x = [UIImage imageWithCGImage:[_ ## x CGImage] scale:[_ ## x scale] orientation:[_ ## x imageOrientation]]; [c encodeObject:orkTemp_ ## x forKey:@RK1_STRINGIFY(x)]; } }

#define RK1_DECODE_URL(d,x)  _ ## x = RK1URLForRelativePath((NSString *)[d decodeObjectOfClass:[NSString class] forKey:@RK1_STRINGIFY(x)])
#define RK1_DECODE_URL_BOOKMARK(d,x)  _ ## x = RK1URLFromBookmarkData((NSData *)[d decodeObjectOfClass:[NSData class] forKey:@RK1_STRINGIFY(x)])

#define RK1_DECODE_BOOL(d,x)  _ ## x = [d decodeBoolForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_BOOL(c,x)  [c encodeBool:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_DOUBLE(d,x)  _ ## x = [d decodeDoubleForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_DOUBLE(c,x)  [c encodeDouble:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_INTEGER(d,x)  _ ## x = [d decodeIntegerForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_INTEGER(c,x)  [c encodeInteger:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_ENCODE_UINT32(c,x)  [c encodeObject:[NSNumber numberWithUnsignedLongLong:_ ## x] forKey:@RK1_STRINGIFY(x)]
#define RK1_DECODE_UINT32(d,x)  _ ## x = (uint32_t)[(NSNumber *)[d decodeObjectForKey:@RK1_STRINGIFY(x)] unsignedLongValue]

#define RK1_DECODE_ENUM(d,x)  _ ## x = [d decodeIntegerForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_ENUM(c,x)  [c encodeInteger:(NSInteger)_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_CGRECT(d,x)  _ ## x = [d decodeCGRectForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_CGRECT(c,x)  [c encodeCGRect:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_CGSIZE(d,x)  _ ## x = [d decodeCGSizeForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_CGSIZE(c,x)  [c encodeCGSize:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_CGPOINT(d,x)  _ ## x = [d decodeCGPointForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_CGPOINT(c,x)  [c encodeCGPoint:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_UIEDGEINSETS(d,x)  _ ## x = [d decodeUIEdgeInsetsForKey:@RK1_STRINGIFY(x)]
#define RK1_ENCODE_UIEDGEINSETS(c,x)  [c encodeUIEdgeInsets:_ ## x forKey:@RK1_STRINGIFY(x)]

#define RK1_DECODE_COORDINATE(d,x)  _ ## x = CLLocationCoordinate2DMake([d decodeDoubleForKey:@RK1_STRINGIFY(x.latitude)],[d decodeDoubleForKey:@RK1_STRINGIFY(x.longitude)])
#define RK1_ENCODE_COORDINATE(c,x)  [c encodeDouble:_ ## x.latitude forKey:@RK1_STRINGIFY(x.latitude)];[c encodeDouble:_ ## x.longitude forKey:@RK1_STRINGIFY(x.longitude)];

/*
 * Helpers for completions which call the block only if non-nil
 *
 */
#define RK1_BLOCK_EXEC(block, ...) if (block) { block(__VA_ARGS__); };

#define RK1_DISPATCH_EXEC(queue, block, ...) if (block) { dispatch_async(queue, ^{ block(__VA_ARGS__); } ); }

/*
 * For testing background delivery
 *
 */
#if RK1_BACKGROUND_DELIVERY_TEST
#  define RK1_HEALTH_UPDATE_FREQUENCY HKUpdateFrequencyImmediate
#else
#  define RK1_HEALTH_UPDATE_FREQUENCY HKUpdateFrequencyDaily
#endif

// Find the first object of the specified class, using method as the iterator
#define RK1FirstObjectOfClass(C,p,method) ({ id v = p; while (v != nil) { if ([v isKindOfClass:[C class]]) { break; } else { v = [v method]; } }; v; })

#define RK1StrongTypeOf(x) __strong __typeof(x)
#define RK1WeakTypeOf(x) __weak __typeof(x)

// Bundle for video assets
NSBundle *RK1AssetsBundle(void);
NSBundle *RK1Bundle(void);
NSBundle *RK1DefaultLocaleBundle(void);

// Pass 0xcccccc and get color #cccccc
UIColor *RK1RGB(uint32_t x);
UIColor *RK1RGBA(uint32_t x, CGFloat alpha);

id findInArrayByKey(NSArray * array, NSString *key, id value);

NSString *RK1SignatureStringFromDate(NSDate *date);

NSURL *RK1CreateRandomBaseURL(void);

// Marked extern so it is accessible to unit tests
RK1_EXTERN NSString *RK1FileProtectionFromMode(RK1FileProtectionMode mode);

CGFloat RK1ExpectedLabelHeight(UILabel *label);
void RK1AdjustHeightForLabel(UILabel *label);

// build a image with color
UIImage *RK1ImageWithColor(UIColor *color);

void RK1EnableAutoLayoutForViews(NSArray *views);

NSDateComponentsFormatter *RK1TimeIntervalLabelFormatter(void);
NSDateComponentsFormatter *RK1DurationStringFormatter(void);

NSDateFormatter *RK1TimeOfDayLabelFormatter(void);
NSCalendar *RK1TimeOfDayReferenceCalendar(void);

NSDateComponents *RK1TimeOfDayComponentsFromDate(NSDate *date);
NSDate *RK1TimeOfDayDateFromComponents(NSDateComponents *dateComponents);

BOOL RK1CurrentLocalePresentsFamilyNameFirst(void);

UIFont *RK1TimeFontForSize(CGFloat size);
UIFontDescriptor *RK1FontDescriptorForLightStylisticAlternative(UIFontDescriptor *descriptor);

CGFloat RK1FloorToViewScale(CGFloat value, UIView *view);

RK1_INLINE bool
RK1EqualObjects(id o1, id o2) {
    return (o1 == o2) || (o1 && o2 && [o1 isEqual:o2]);
}

RK1_INLINE BOOL
RK1EqualFileURLs(NSURL *url1, NSURL *url2) {
    return RK1EqualObjects(url1, url2) || ([url1 isFileURL] && [url2 isFileURL] && [[url1 absoluteString] isEqualToString:[url2 absoluteString]]);
}

RK1_INLINE NSMutableOrderedSet *
RK1MutableOrderedSetCopyObjects(NSOrderedSet *a) {
    if (!a) {
        return nil;
    }
    NSMutableOrderedSet *b = [NSMutableOrderedSet orderedSetWithCapacity:a.count];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [b addObject:[obj copy]];
    }];
    return b;
}

RK1_INLINE NSMutableDictionary *
RK1MutableDictionaryCopyObjects(NSDictionary *a) {
    if (!a) {
        return nil;
    }
    NSMutableDictionary *b = [NSMutableDictionary dictionaryWithCapacity:a.count];
    [a enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        b[key] = [obj copy];
    }];
    return b;
}

#define RK1SuppressPerformSelectorWarning(PerformCall) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
PerformCall; \
_Pragma("clang diagnostic pop") \
} while (0)

UIFont *RK1ThinFontWithSize(CGFloat size);
UIFont *RK1LightFontWithSize(CGFloat size);
UIFont *RK1MediumFontWithSize(CGFloat size);

NSURL *RK1URLFromBookmarkData(NSData *data);
NSData *RK1BookmarkDataFromURL(NSURL *url);

NSString *RK1PathRelativeToURL(NSURL *url, NSURL *baseURL);
NSURL *RK1URLForRelativePath(NSString *relativePath);
NSString *RK1RelativePathForURL(NSURL *url);

id RK1DynamicCast_(id x, Class objClass);

#define RK1DynamicCast(x, c) ((c *) RK1DynamicCast_(x, [c class]))

extern const CGFloat RK1ScrollToTopAnimationDuration;

RK1_INLINE CGFloat
RK1CGFloatNearlyEqualToFloat(CGFloat f1, CGFloat f2) {
    const CGFloat RK1CGFloatEpsilon = 0.01; // 0.01 should be safe enough when dealing with screen point and pixel values
    return (ABS(f1 - f2) <= RK1CGFloatEpsilon);
}

#define RK1ThrowMethodUnavailableException()  @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"method unavailable" userInfo:nil];
#define RK1ThrowInvalidArgumentExceptionIfNil(argument)  if (!argument) { @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@#argument" cannot be nil." userInfo:nil]; }

void RK1ValidateArrayForObjectsOfClass(NSArray *array, Class expectedObjectClass, NSString *exceptionReason);

void RK1RemoveConstraintsForRemovedViews(NSMutableArray *constraints, NSArray *removedViews);

extern const double RK1DoubleInvalidValue;

extern const CGFloat RK1CGFloatInvalidValue;

void RK1AdjustPageViewControllerNavigationDirectionForRTL(UIPageViewControllerNavigationDirection *direction);

NSString *RK1PaddingWithNumberOfSpaces(NSUInteger numberOfPaddingSpaces);

NSNumberFormatter *RK1DecimalNumberFormatter(void);

RK1_INLINE double RK1FeetAndInchesToInches(double feet, double inches) {
    return (feet * 12) + inches;
}

RK1_INLINE void RK1InchesToFeetAndInches(double inches, double *outFeet, double *outInches) {
    if (outFeet == NULL || outInches == NULL) {
        return;
    }
    *outFeet = floor(inches / 12);
    *outInches = fmod(inches, 12);
}

RK1_INLINE double RK1InchesToCentimeters(double inches) {
    return inches * 2.54;
}

RK1_INLINE double RK1CentimetersToInches(double centimeters) {
    return centimeters / 2.54;
}

RK1_INLINE void RK1CentimetersToFeetAndInches(double centimeters, double *outFeet, double *outInches) {
    double inches = RK1CentimetersToInches(centimeters);
    RK1InchesToFeetAndInches(inches, outFeet, outInches);
}

RK1_INLINE double RK1FeetAndInchesToCentimeters(double feet, double inches) {
    return RK1InchesToCentimeters(RK1FeetAndInchesToInches(feet, inches));
}

RK1_INLINE void RK1KilogramsToWholeAndFraction(double kilograms, double *outWhole, double *outFraction) {
    if (outWhole == NULL || outFraction == NULL) {
        return;
    }
    *outWhole = floor(kilograms);
    *outFraction = round((kilograms - floor(kilograms)) * 100);
}

RK1_INLINE void RK1KilogramsToPoundsAndOunces(double kilograms, double * _Nullable outPounds, double * _Nullable outOunces) {
    const double RK1PoundsPerKilogram = 2.20462262;
    double fractionalPounds = kilograms * RK1PoundsPerKilogram;
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

RK1_INLINE double RK1KilogramsToPounds(double kilograms) {
    double pounds;
    RK1KilogramsToPoundsAndOunces(kilograms, &pounds, NULL);
    return pounds;
}

RK1_INLINE double RK1WholeAndFractionToKilograms(double whole, double fraction) {
    double kg = (whole + (fraction / 100));
    return (round(100 * kg) / 100);
}

RK1_INLINE double RK1PoundsAndOuncesToKilograms(double pounds, double ounces) {
    const double RK1KilogramsPerPound = 0.45359237;
    double kg = (pounds + (ounces / 16)) * RK1KilogramsPerPound;
    return (round(100 * kg) / 100);
}

RK1_INLINE double RK1PoundsToKilograms(double pounds) {
    return RK1PoundsAndOuncesToKilograms(pounds, 0);
}

RK1_INLINE UIColor *RK1OpaqueColorWithReducedAlphaFromBaseColor(UIColor *baseColor, NSUInteger colorIndex, NSUInteger totalColors) {
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
RK1_EXTERN NSBundle *RK1Bundle(void) RK1_AVAILABLE_DECL;
RK1_EXTERN NSBundle *RK1DefaultLocaleBundle(void);

#define RK1DefaultLocalizedValue(key) \
[RK1DefaultLocaleBundle() localizedStringForKey:key value:@"" table:@"ResearchKit"]

#define RK1LocalizedString(key, comment) \
[RK1Bundle() localizedStringForKey:(key) value:RK1DefaultLocalizedValue(key) table:@"ResearchKit"]

#define RK1LocalizedStringFromNumber(number) \
[NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterNoStyle]

NS_ASSUME_NONNULL_END
