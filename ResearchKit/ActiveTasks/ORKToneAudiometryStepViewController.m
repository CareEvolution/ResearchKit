/*
 Copyright (c) 2015, Shazino SAS. All rights reserved.
 
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


#import "ORKToneAudiometryStepViewController.h"

#import "ORKActiveStepView.h"
#import "ORKAudioGenerator.h"
#import "ORKRoundTappingButton.h"
#import "ORKToneAudiometryContentView.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"

#import "ORKResult.h"
#import "ORKToneAudiometryStep.h"

#import "ORKHelpers_Internal.h"

#import <MediaPlayer/MediaPlayer.h>


@interface ORK1ToneAudiometryStepViewController ()

@property (nonatomic, strong) ORK1ToneAudiometryContentView *toneAudiometryContentView;
@property (nonatomic, strong) ORK1AudioGenerator *audioGenerator;
@property (nonatomic, assign) BOOL expired;

@property (nonatomic) NSArray *listOfFrequencies;
@property (nonatomic) NSMutableArray *frequencies;
@property (nonatomic, assign) NSUInteger currentTestIndex;
@property (nonatomic, strong) NSMutableArray *samples;

- (IBAction)buttonPressed:(id)button forEvent:(UIEvent *)event;
@property (nonatomic) ORK1AudioChannel currentTestChannel;
- (ORK1ToneAudiometryStep *)toneAudiometryStep;

@end


@implementation ORK1ToneAudiometryStepViewController

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    
    if (self) {
        self.suspendIfInactive = YES;
    }
    
    return self;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    
    // Don't show next button
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.expired = NO;
    self.listOfFrequencies = @[ @8000, @4000, @1000, @500, @250 ];
    
    [self generateFrequencyCombination];
    self.toneAudiometryContentView = [[ORK1ToneAudiometryContentView alloc] init];
    self.activeStepView.activeCustomView = self.toneAudiometryContentView;
    
    [self.toneAudiometryContentView.leftButton addTarget:self action:@selector(buttonPressed:forEvent:) forControlEvents:UIControlEventTouchDown];
    [self.toneAudiometryContentView.rightButton addTarget:self action:@selector(buttonPressed:forEvent:) forControlEvents:UIControlEventTouchDown];
    self.currentTestIndex = 0;
    self.audioGenerator = [ORK1AudioGenerator new];
}

- (void)generateFrequencyCombination {
    int numberOfChannels = 2;
    self.frequencies = [[NSMutableArray alloc] init];
    for (int i = 0; i<[self.listOfFrequencies count]; i++) {
        for (int j = 0; j < numberOfChannels; j++) {
            [self.frequencies addObject:@[self.listOfFrequencies[i], [NSNumber numberWithInt:j]]];
        }
    }
    for (int k = 0; k<[self.frequencies count]; k++) {
        [self.frequencies exchangeObjectAtIndex:(arc4random() % [self.frequencies count]) withObjectAtIndex:(arc4random() % [self.frequencies count])];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.audioGenerator stop];
}

- (ORK1StepResult *)result {
    ORK1StepResult *sResult = [super result];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
    NSDate *now = sResult.endDate;
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:sResult.results];
    
    ORK1ToneAudiometryResult *toneResult = [[ORK1ToneAudiometryResult alloc] initWithIdentifier:self.step.identifier];
    toneResult.startDate = sResult.startDate;
    toneResult.endDate = now;
    toneResult.samples = [self.samples copy];
    toneResult.outputVolume = @([AVAudioSession sharedInstance].outputVolume);
    
    [results addObject:toneResult];
    sResult.results = [results copy];
    
    return sResult;
}

- (void)stepDidFinish {
    [super stepDidFinish];
    
    self.expired = YES;
    [self.toneAudiometryContentView finishStep:self];
    [self goForward];
}

- (void)start {
    [super start];
    
    [self startCurrentTest];
}

- (IBAction)buttonPressed:(id)button forEvent:(UIEvent *)event {
    if (self.samples == nil) {
        _samples = [NSMutableArray array];
    }
    
    ORK1ToneAudiometrySample *sample = [ORK1ToneAudiometrySample new];
    NSUInteger frequencyIndex = self.currentTestIndex;
    NSNumber *frequency = self.frequencies[frequencyIndex][0];
    sample.frequency = [frequency doubleValue];
    sample.channel = self.currentTestChannel;
    sample.channelSelected = (button == self.toneAudiometryContentView.leftButton) ? ORK1AudioChannelLeft : ORK1AudioChannelRight;
    sample.amplitude = self.audioGenerator.volumeAmplitude;
    
    [self.samples addObject:sample];
    
    [self.audioGenerator stop];
    
    [self startNextTestOrFinish];
}

- (void)testExpired {
    if (self.samples == nil) {
        _samples = [NSMutableArray array];
    }
    
    ORK1ToneAudiometrySample *sample = [ORK1ToneAudiometrySample new];
    NSUInteger frequencyIndex = self.currentTestIndex;
    NSNumber *frequency = self.frequencies[frequencyIndex][0];
    sample.frequency = [frequency doubleValue];
    sample.channel = self.currentTestChannel;
    sample.channelSelected = -1;
    sample.amplitude = self.audioGenerator.volumeAmplitude;
    
    [self.samples addObject:sample];
    [self.audioGenerator stop];
    
    [self startNextTestOrFinish];
}

- (void)startNextTestOrFinish {
    self.currentTestIndex ++;
    if (self.currentTestIndex == (self.frequencies.count)) {
        [self finish];
    } else {
        [self startCurrentTest];
    }
}

- (ORK1ToneAudiometryStep *)toneAudiometryStep {
    return (ORK1ToneAudiometryStep *)self.step;
}

- (void)startCurrentTest {
    const NSTimeInterval SoundDuration = self.toneAudiometryStep.toneDuration;
    
    NSUInteger testIndex = self.currentTestIndex;
    NSUInteger frequencyIndex = testIndex;
    NSAssert(frequencyIndex < self.frequencies.count, nil);
    
    NSNumber *frequency = self.frequencies[frequencyIndex][0];
    
    self.currentTestChannel = ([self.frequencies[frequencyIndex][1] intValue] == 0) ? ORK1AudioChannelLeft : ORK1AudioChannelRight;
    
    ORK1AudioChannel channel = self.currentTestChannel;
    
    CGFloat progress = 0.001 + (CGFloat)testIndex / self.frequencies.count;
    [self.toneAudiometryContentView setProgress:progress
                                        caption:(channel == ORK1AudioChannelLeft) ? [NSString stringWithFormat:ORK1LocalizedString(@"TONE_LABEL_%@_LEFT", nil), ORK1LocalizedStringFromNumber(frequency)] : [NSString stringWithFormat:ORK1LocalizedString(@"TONE_LABEL_%@_RIGHT", nil), ORK1LocalizedStringFromNumber(frequency)]
                                       animated:YES];
    
    [self.audioGenerator playSoundAtFrequency:frequency.doubleValue
                                    onChannel:channel
                               fadeInDuration:SoundDuration];
    
    ORK1WeakTypeOf(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SoundDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ORK1StrongTypeOf(self) strongSelf = weakSelf;
        
        if (strongSelf.currentTestIndex == testIndex) {
            [strongSelf testExpired];
        }
    });
}


@end
