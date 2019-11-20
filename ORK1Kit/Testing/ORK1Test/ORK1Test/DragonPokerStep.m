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


#import "DragonPokerStep.h"


@interface DragonPokerStep ()

@property (nonatomic) NSDate *playDate;

@end


@interface DragonPokerStepViewController : ORK1FormStepViewController

@property (nonatomic) BOOL shouldShowCancelButton;

@end


@implementation DragonPokerStep

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        ORK1FormItem *formItem = [[ORK1FormItem alloc] initWithIdentifier:@"question1" text:@"Are you tall?" answerFormat:[ORK1AnswerFormat booleanAnswerFormat]];
        self.formItems = @[formItem];
    }
    return self;
}

- (NSDate *)playDate {
    if (_playDate == nil) {
        _playDate = [NSDate date];
    }
    return _playDate;
    }

- (ORK1StepViewController *)instantiateStepViewControllerWithResult:(ORK1Result *)result {
    
    DragonPokerStepViewController *viewController = [[DragonPokerStepViewController alloc] initWithStep:self result:result];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:self.playDate];
    viewController.shouldShowCancelButton = components.weekday == 2;
    
    return viewController;
}

@end

@implementation DragonPokerStepViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide the cancel button if it should not be shown.
    if (!self.shouldShowCancelButton) {
        self.cancelButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectZero]];
    }
}

@end
