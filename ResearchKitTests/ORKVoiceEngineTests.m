/*
 Copyright (c) 2015, Denis Lebedev. All rights reserved.
 
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


@import XCTest;
@import ResearchKitLegacy.Private;

#import "ORKVoiceEngine_Internal.h"


@interface ORKLegacyMockSpeechSynthesizer : AVSpeechSynthesizer

@property (nonatomic, readonly) BOOL didStopSpeaking;
@property (nonatomic, readonly) BOOL didSpeakText;
@property (nonatomic, readonly) NSString *speech;
@property (nonatomic, readonly) AVSpeechBoundary stopBoundary;
@property (nonatomic) BOOL mockSpeaking;

@end


@implementation ORKLegacyMockSpeechSynthesizer

- (BOOL)isSpeaking {
    return self.mockSpeaking;
}

- (BOOL)stopSpeakingAtBoundary:(AVSpeechBoundary)boundary {
    _didStopSpeaking = YES;
    _stopBoundary = boundary;
    return YES;
}

- (void)speakUtterance:(AVSpeechUtterance *)utterance {
    _didSpeakText = YES;
    _speech = utterance.speechString;
}

@end


@interface ORKLegacyTestVoiceEngine : ORKLegacyVoiceEngine

@end


@implementation ORKLegacyTestVoiceEngine {
    ORKLegacyMockSpeechSynthesizer *_speechSynthesizer;
}

- (AVSpeechSynthesizer *)speechSynthesizer {
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[ORKLegacyMockSpeechSynthesizer alloc] init];
    }
    return _speechSynthesizer;
}

@end


@interface ORKLegacyVoiceEngineTests : XCTestCase

@end


@implementation ORKLegacyVoiceEngineTests {
    ORKLegacyVoiceEngine *_voiceEngine;
    ORKLegacyMockSpeechSynthesizer *_mockSpeechSynthesizer;
}

- (void)setUp {
    [super setUp];
    _voiceEngine = [[ORKLegacyTestVoiceEngine alloc] init];
    _mockSpeechSynthesizer = (ORKLegacyMockSpeechSynthesizer *)_voiceEngine.speechSynthesizer;
}

- (void)testSharedInstance {
    XCTAssertEqualObjects([ORKLegacyVoiceEngine sharedVoiceEngine], [ORKLegacyVoiceEngine sharedVoiceEngine]);
}

- (void)testSpeakText {
    [_voiceEngine speakText:@"foo"];
    
    XCTAssertTrue(_mockSpeechSynthesizer.didSpeakText);
    XCTAssertEqualObjects(@"foo", _mockSpeechSynthesizer.speech);
}

- (void)testSpeakTextWhenVoiceEngineIsAlreadySpeaking {
    _mockSpeechSynthesizer.mockSpeaking = YES;
        
    [_voiceEngine speakText:@"foo"];
        
    XCTAssertTrue(_mockSpeechSynthesizer.didStopSpeaking);
    XCTAssertTrue(_mockSpeechSynthesizer.didSpeakText);
    XCTAssertEqualObjects(@"foo", _mockSpeechSynthesizer.speech);
}

- (void)testSpeakInt {
    [_voiceEngine speakInt:42];
    
    XCTAssertTrue(_mockSpeechSynthesizer.didSpeakText);
    XCTAssertEqualObjects(@"42", _mockSpeechSynthesizer.speech);
}

- (void)testStopTalking {
    [_voiceEngine stopTalking];
    
    XCTAssertTrue(_mockSpeechSynthesizer.didStopSpeaking);
    XCTAssertEqual(_mockSpeechSynthesizer.stopBoundary, AVSpeechBoundaryWord);
}

- (void)testIsSpeaking {
    {
        _mockSpeechSynthesizer.mockSpeaking = NO;
        XCTAssertFalse(_voiceEngine.isSpeaking);
    }
    
    {
        _mockSpeechSynthesizer.mockSpeaking = YES;
        XCTAssertTrue(_voiceEngine.isSpeaking);
    }
}

@end
