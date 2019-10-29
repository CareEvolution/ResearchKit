/*
 Copyright (c) 2016, Sage Bionetworks
 
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

#import <ResearchKit/RK1PageStep.h>
#import <ResearchKit/RK1OrderedTask.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `RK1NavigablePageStep` class is a concrete subclass of `RK1PageStep`, used for presenting a subgrouping of
 `RK1StepViewController` views using a `UIPageViewController`. It allows for using an `RK1OrderedTask` as
 the model object used to define navigation, and has been added specifically to allow developers to use 
 `RK1NavigableOrderedTask` and other subclasses of RK1OrderedTask with the `RK1PageStep`.
 
 To use `RK1NavigablePageStep`, instantiate the object, fill in its properties, and include it in a task.
 Next, create a task view controller for the task and present it.
 
 The base class implementation will instatiate a read-only `RK1PageStepViewController` to display
 a series of substeps. For each substep, the `RK1StepViewController` will be instantiated and added
 as a child of the `UIPageViewController` contained by the parent `RK1PageStepViewController`..
 
 Customization can be handled by overriding the base class implementations in either `RK1NavigablePageStep`
 or `RK1PageStepViewController`.
 */

RK1_CLASS_AVAILABLE
@interface RK1NavigablePageStep : RK1PageStep

/**
 The subtask used to determine the next/previous steps that are in this grouping
 */
@property (nonatomic, copy, readonly) RK1OrderedTask *pageTask;

/**
 Returns an initialized page step using the specified identifier and task.
 
 @param identifier  The unique identifier for the step.
 @param task        The task used to run the subtask.
 
 @return An initialized navigable page step.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                          pageTask:(RK1OrderedTask *)task NS_DESIGNATED_INITIALIZER;

/**
 Returns a page step initialized from data in the given unarchiver.
 
 A page step can be serialized and deserialized with `NSKeyedArchiver`. Note
 that this serialization includes strings that might need to be localized.
 
 @param aDecoder    The coder from which to initialize the ordered task.
 
 @return An initialized navigable page step.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
