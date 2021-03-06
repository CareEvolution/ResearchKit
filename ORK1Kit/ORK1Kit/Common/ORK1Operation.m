/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
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


#import "ORK1Operation.h"
#import "ORK1Errors.h"
#import "ORK1Helpers_Internal.h"


static NSString *keyPathFromOperationState(ORK1OperationState state) {
    switch (state) {
        case ORK1OperationReady:
            return @"isReady";
        case ORK1OperationExecuting:
            return @"isExecuting";
        case ORK1OperationFinished:
            return @"isFinished";
        default:
            return @"state";
    }
}

static BOOL stateTransitionIsValid(ORK1OperationState fromState, ORK1OperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case ORK1OperationReady:
            switch (toState) {
                case ORK1OperationExecuting:
                    return YES;
                case ORK1OperationFinished:
                    return isCancelled;
                default:
                    return NO;
            }
        case ORK1OperationExecuting:
            switch (toState) {
                case ORK1OperationFinished:
                    return YES;
                default:
                    return NO;
            }
        case ORK1OperationFinished:
            return NO;
        default:
            return YES;
    }
}


@implementation ORK1Operation

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = @"com.apple.ORK1Kit.Operation";
        self.state = ORK1OperationReady;
    }
    return self;
}

- (void)setState:(ORK1OperationState)state {
    [self.lock lock];
    if (stateTransitionIsValid(self.state, state, [self isCancelled])) {
        NSString *oldStateKey = keyPathFromOperationState(self.state);
        NSString *newStateKey = keyPathFromOperationState(state);
        
        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
        
    }
    [self.lock unlock];
}


#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == ORK1OperationReady && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == ORK1OperationExecuting;
}

- (BOOL)isFinished {
    return self.state == ORK1OperationFinished;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    
    if ([self isCancelled]) {
        [self finish];
    } else if ([self isReady]) {
        self.state = ORK1OperationExecuting;
        
        ORK1_Log_Debug(@"%@ start", self.class);
        _startBlock(self);
    }
    [self.lock unlock];
}

- (void)finish {
    ORK1_Log_Debug(@"%@ finish: %@", self, (self.error ? : @"OK"));
    self.state = ORK1OperationFinished;
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        if (! self.error) {
            self.error = [NSError errorWithDomain:ORK1ErrorDomain code:ORK1ErrorException userInfo:nil];
        }
        [self willChangeValueForKey:@"isCancelled"];
        [super cancel];
        [self didChangeValueForKey:@"isCancelled"];
    }
    [self.lock unlock];
}

- (void)safeFinish {
    [self.lock lock];
    if ([self isExecuting]) {
        [self finish];
    }
    [self.lock unlock];
}

- (void)doTimeout {
    [self.lock lock];
    if (self.state == ORK1OperationExecuting) {
        self.error = [NSError errorWithDomain:ORK1ErrorDomain code:ORK1ErrorException userInfo:nil];
        [self finish];
    }
    [self.lock unlock];
}

@end
