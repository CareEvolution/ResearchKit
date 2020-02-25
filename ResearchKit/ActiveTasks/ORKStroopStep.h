/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import <ResearchKit/ORKDefines.h>
#import <ResearchKit/ORKActiveStep.h>
#import <ResearchKit/ORKStroopResult.h>

NS_ASSUME_NONNULL_BEGIN

ORK_EXTERN NSString *const ORKStroopColorIdentifierRed ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKStroopColorIdentifierGreen ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKStroopColorIdentifierBlue ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKStroopColorIdentifierYellow ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKStroopColorIdentifierBlack ORK_AVAILABLE_DECL;

ORK_CLASS_AVAILABLE
@interface ORKStroopColor : NSObject

- (instancetype __nullable)initWithIdentifier:(NSString *)identifier;

@property (nonatomic, copy) UIColor *color;
@property (nonatomic, copy) NSString *title;

@end


ORK_CLASS_AVAILABLE
@interface ORKStroopTest : NSObject
/**
 The `color` property is the color of the question string.
 */
@property (nonatomic, strong) ORKStroopColor *color;

/**
 The `text` property is the text of the question string.
 */
@property (nonatomic, strong) ORKStroopColor *text;

/**
 The Stroop style displayed. NOTE: ORKStroopStyleColoredTextRandomlyUnderlined
 in this context means the text is definitively underlined. ORKStroopStyleColoredText
 would be for the non-underlined case.
 */
@property (nonatomic, assign) ORKStroopStyle stroopStyle;

@end


ORK_CLASS_AVAILABLE
@interface ORKStroopStep : ORKActiveStep

@property (nonatomic, assign) NSInteger numberOfAttempts;

/**
 A number from 0 (never) to 1 (always) indicating randomized probability for the visual and color of each stroop
 question to be in alignment..
 This means that the color of the text displayed and the text may not match, which makes for a harder stroop test.
 
 By default, this property is set to `0.5`
*/
@property (nonatomic, strong) NSNumber *probabilityOfVisualAndColorAlignment;

/**
 The type of Stroop test to display. Default = `ORKStroopStyleText`
*/
@property (nonatomic, assign) ORKStroopStyle stroopStyle;

/**
 A Boolean value indicating whether this task will use a 2x2 grid of buttons

 By default, this property is set to `NO`
*/
@property (nonatomic, assign) BOOL useGridLayoutForButtons;

/**
 When supplied, will run the test using the characteristics of this array. This aids in testing or
 to provide a specific practice example set. If set, this overrides the randomizeVisualAndColorAlignment,
 stroopStyle and numberOfAttempts properties.
 */
@property (nonatomic, strong, nullable) NSArray<ORKStroopTest *> *nonRandomizedTests;

@end

NS_ASSUME_NONNULL_END
