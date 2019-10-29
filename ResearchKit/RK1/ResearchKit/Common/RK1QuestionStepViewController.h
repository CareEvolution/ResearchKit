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


@import UIKit;
#import <ResearchKit/RK1Defines.h>
#import <ResearchKit/RK1StepViewController.h>


NS_ASSUME_NONNULL_BEGIN

/**
 The `RK1QuestionStepViewController` class is the concrete `RK1StepViewController`
 implementation for `RK1QuestionStep`.
 
 You should not need to instantiate an `RK1QuestionStepViewController` object
 directly. Instead, create an `RK1QuestionStep` object, include it in a task
 the task using a task view controller. The task view
 controller automatically instantiates the question step view controller
 when it needs to present a question step.
 
 To use `RK1QuestionStepViewController` directly, create an `RK1QuestionStep` object and use
 `initWithStep:` to initialize it. To receive the result of the question, and to determine
 when to dismiss the view controller, implement `RK1StepViewControllerDelegate`.
 */

RK1_CLASS_AVAILABLE
@interface RK1QuestionStepViewController : RK1StepViewController

@end

NS_ASSUME_NONNULL_END
