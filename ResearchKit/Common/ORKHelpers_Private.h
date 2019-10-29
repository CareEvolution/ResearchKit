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


@import Foundation;
#import <ResearchKitLegacy/ORKDefines.h>


NS_ASSUME_NONNULL_BEGIN

#if !defined(ORKLegacy_INLINE)
#  if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#    define ORKLegacy_INLINE static inline
#  elif defined(__cplusplus)
#    define ORKLegacy_INLINE static inline
#  elif defined(__GNUC__)
#    define ORKLegacy_INLINE static __inline__
#  else
#    define ORKLegacy_INLINE static
#  endif
#endif

#define ORKLegacy_STRINGIFY2( x) #x
#define ORKLegacy_STRINGIFY(x) ORKLegacy_STRINGIFY2(x)

#define ORKLegacyDefineStringKey(x) static NSString *const x = @ORKLegacy_STRINGIFY(x)

ORKLegacy_INLINE NSArray *ORKLegacyArrayCopyObjects(NSArray *a) {
    if (!a) {
        return nil;
    }
    NSMutableArray *b = [NSMutableArray arrayWithCapacity:a.count];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [b addObject:[obj copy]];
    }];
    return [b copy];
}

ORKLegacy_EXTERN NSString *ORKLegacyStringFromDateISO8601(NSDate *date) ORKLegacy_AVAILABLE_DECL;
ORKLegacy_EXTERN NSDate *ORKLegacyDateFromStringISO8601(NSString *string) ORKLegacy_AVAILABLE_DECL;

ORKLegacy_EXTERN NSString *ORKLegacyTimeOfDayStringFromComponents(NSDateComponents *dateComponents) ORKLegacy_AVAILABLE_DECL;
ORKLegacy_EXTERN NSDateComponents *ORKLegacyTimeOfDayComponentsFromString(NSString *string) ORKLegacy_AVAILABLE_DECL;

ORKLegacy_EXTERN NSDateFormatter *ORKLegacyResultDateTimeFormatter(void) ORKLegacy_AVAILABLE_DECL;
ORKLegacy_EXTERN NSDateFormatter *ORKLegacyResultTimeFormatter(void) ORKLegacy_AVAILABLE_DECL;
ORKLegacy_EXTERN NSDateFormatter *ORKLegacyResultDateFormatter(void) ORKLegacy_AVAILABLE_DECL;

NS_ASSUME_NONNULL_END
