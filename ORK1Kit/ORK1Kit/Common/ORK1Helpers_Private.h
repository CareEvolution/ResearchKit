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
#import <ORK1Kit/ORK1Defines.h>


NS_ASSUME_NONNULL_BEGIN

#if !defined(ORK1_INLINE)
#  if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#    define ORK1_INLINE static inline
#  elif defined(__cplusplus)
#    define ORK1_INLINE static inline
#  elif defined(__GNUC__)
#    define ORK1_INLINE static __inline__
#  else
#    define ORK1_INLINE static
#  endif
#endif

#define ORK1_STRINGIFY2( x) #x
#define ORK1_STRINGIFY(x) ORK1_STRINGIFY2(x)

#define ORK1DefineStringKey(x) static NSString *const x = @ORK1_STRINGIFY(x)

ORK1_INLINE NSArray *ORK1ArrayCopyObjects(NSArray *a) {
    if (!a) {
        return nil;
    }
    NSMutableArray *b = [NSMutableArray arrayWithCapacity:a.count];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [b addObject:[obj copy]];
    }];
    return [b copy];
}

ORK1_EXTERN NSString *ORK1StringFromDateISO8601(NSDate *date) ORK1_AVAILABLE_DECL;
ORK1_EXTERN NSDate *ORK1DateFromStringISO8601(NSString *string) ORK1_AVAILABLE_DECL;

ORK1_EXTERN NSString *ORK1TimeOfDayStringFromComponents(NSDateComponents *dateComponents) ORK1_AVAILABLE_DECL;
ORK1_EXTERN NSDateComponents *ORK1TimeOfDayComponentsFromString(NSString *string) ORK1_AVAILABLE_DECL;

ORK1_EXTERN NSDateFormatter *ORK1ResultDateTimeFormatter(void) ORK1_AVAILABLE_DECL;
ORK1_EXTERN NSDateFormatter *ORK1ResultTimeFormatter(void) ORK1_AVAILABLE_DECL;
ORK1_EXTERN NSDateFormatter *ORK1ResultDateFormatter(void) ORK1_AVAILABLE_DECL;

NS_ASSUME_NONNULL_END
