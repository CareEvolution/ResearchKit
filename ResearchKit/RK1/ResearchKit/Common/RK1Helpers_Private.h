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
#import <ResearchKit/RK1Defines.h>


NS_ASSUME_NONNULL_BEGIN

#if !defined(RK1_INLINE)
#  if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#    define RK1_INLINE static inline
#  elif defined(__cplusplus)
#    define RK1_INLINE static inline
#  elif defined(__GNUC__)
#    define RK1_INLINE static __inline__
#  else
#    define RK1_INLINE static
#  endif
#endif

#define RK1_STRINGIFY2( x) #x
#define RK1_STRINGIFY(x) RK1_STRINGIFY2(x)

#define RK1DefineStringKey(x) static NSString *const x = @RK1_STRINGIFY(x)

RK1_INLINE NSArray *RK1ArrayCopyObjects(NSArray *a) {
    if (!a) {
        return nil;
    }
    NSMutableArray *b = [NSMutableArray arrayWithCapacity:a.count];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [b addObject:[obj copy]];
    }];
    return [b copy];
}

RK1_EXTERN NSString *RK1StringFromDateISO8601(NSDate *date) RK1_AVAILABLE_DECL;
RK1_EXTERN NSDate *RK1DateFromStringISO8601(NSString *string) RK1_AVAILABLE_DECL;

RK1_EXTERN NSString *RK1TimeOfDayStringFromComponents(NSDateComponents *dateComponents) RK1_AVAILABLE_DECL;
RK1_EXTERN NSDateComponents *RK1TimeOfDayComponentsFromString(NSString *string) RK1_AVAILABLE_DECL;

RK1_EXTERN NSDateFormatter *RK1ResultDateTimeFormatter(void) RK1_AVAILABLE_DECL;
RK1_EXTERN NSDateFormatter *RK1ResultTimeFormatter(void) RK1_AVAILABLE_DECL;
RK1_EXTERN NSDateFormatter *RK1ResultDateFormatter(void) RK1_AVAILABLE_DECL;

NS_ASSUME_NONNULL_END
