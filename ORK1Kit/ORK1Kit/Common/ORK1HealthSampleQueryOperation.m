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


#import "ORK1HealthSampleQueryOperation.h"
#import "ORK1Collector.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1Collector_Internal.h"
#import "ORK1DataCollectionManager_Internal.h"


static NSUInteger const QueryLimitSize = 1000;

@implementation ORK1HealthSampleQueryOperation {
    // All of these are strong references created at init time
    ORK1Collector<ORK1HealthCollectable> *_collector;
    __weak ORK1DataCollectionManager *_manager;
    HKQueryAnchor *_currentAnchor;
    dispatch_semaphore_t _sem;
}


// Run this only on the manager work queue
- (BOOL)_shouldContinue {
    BOOL shouldContinue = YES;
    
    if (!_manager || !_collector) {
        shouldContinue = NO;
    }
    if (![_manager.collectors containsObject:_collector]) {
        shouldContinue = NO;
    }
    
    return shouldContinue;
}

- (instancetype)initWithCollector:(ORK1Collector<ORK1HealthCollectable> *)collector mananger:(ORK1DataCollectionManager *)manager {
    NSParameterAssert(collector);
    NSParameterAssert(manager);
    
    self = [super init];
    if (self) {
        _collector = collector;
        _manager = manager;
        _currentAnchor = nil;
        _sem = dispatch_semaphore_create(0);
        
        self.startBlock = ^void(ORK1Operation* operation) {
            [(ORK1HealthSampleQueryOperation*)operation doNextQuery];
        };
        
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@(%p):%@>",NSStringFromClass([self class]), self, _collector];
}

- (void)finishWithErrorCode:(ORK1ErrorCode)error {
    self.error = [NSError errorWithDomain:ORK1ErrorDomain code:error userInfo:nil];
    [self safeFinish];
}

- (void)doNextQuery {
    [self.lock lock];
    
    __block HKSampleType *sampleType = nil;
    __block NSDate *startDate = nil;
    
    __block HKQueryAnchor *lastAnchor = nil;
    __block NSString *itemIdentifier = nil;
    
    // Check if everything's valid and we should continue with collection
    __block BOOL shouldContinue = YES;
    
    [_manager onWorkQueueSync:^BOOL(ORK1DataCollectionManager *manager) {
        
        shouldContinue = [self _shouldContinue];
        
        BOOL changed = NO;
        if (shouldContinue) {
            // _currentAnchor will be NSNotFound on the first pass of the operation
            if (_currentAnchor != nil) {
                changed = YES;
                // Update the anchor if we have one
                _collector.lastAnchor = [_currentAnchor copy];
            }
            
            lastAnchor = _collector.lastAnchor;
            sampleType = _collector.sampleType;
            startDate = _collector.startDate;
            itemIdentifier = _collector.identifier;
        }
        
        return changed;
    }];

    if (_currentAnchor == nil) {
        _currentAnchor = lastAnchor;
    }
    
    if (!shouldContinue) {
        [self finishWithErrorCode:ORK1ErrorInvalidObject];
        [self.lock unlock];
        return;
    }
    
    __weak ORK1HealthSampleQueryOperation * weakSelf = self;
    
    NSPredicate *predicate = nil;
    if (startDate) {
        predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:nil options:HKQueryOptionStrictStartDate];
    }
    
    HKQueryAnchor *anchor = _currentAnchor;
    HKAnchoredObjectQuery *syncQuery = [[HKAnchoredObjectQuery alloc] initWithType:sampleType
                                                                         predicate:predicate
                                                                            anchor:anchor
                                                                             limit:QueryLimitSize
                                                                    resultsHandler:^(HKAnchoredObjectQuery *query,
                                                                                     NSArray<__kindof HKSample *> *sampleObjects,
                                                                                     NSArray<HKDeletedObject *> *deletedObjects,
                                                                                     HKQueryAnchor *newAnchor,
                                                                                     NSError *error) {
                                                                        
                                                                        ORK1HealthSampleQueryOperation *op = weakSelf;
                                                                        ORK1_Log_Debug(@"\nHK Query returned: %@\n", @{@"sampleType": sampleType, @"items":@([sampleObjects count]), @"newAnchor":[newAnchor description]?:@"nil"});
                                                                        // Signal that query returned
                                                                        dispatch_semaphore_signal(_sem);
                                                                        [op handleResults:sampleObjects newAnchor:newAnchor error:error itemIdentifier:itemIdentifier];
                                                                 }];

    
    ORK1_Log_Debug(@"\nHK Query: %@ \n", @{@"identifier": sampleType.identifier, @"anchor": anchor.description ? :@"", @"startDate": [NSDateFormatter localizedStringFromDate:startDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]});
    [_manager.healthStore executeQuery:syncQuery];
    
    [self.lock unlock];
    
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC));
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (dispatch_semaphore_wait(_sem, timeout)) {
            [self timeoutForAnchor:anchor];
        }
    });
    
}

- (void)timeoutForAnchor:(HKQueryAnchor *)anchor {
    ORK1_Log_Debug(@"Query timeout: cancel operation %@", self);
    [self.lock lock];
    
    if ([self isExecuting] && ![self isCancelled] && [anchor isEqual:_currentAnchor]) {
        self.error = [NSError errorWithDomain:ORK1ErrorDomain code:ORK1ErrorException userInfo:@{NSLocalizedDescriptionKey:@"Query timeout"}];
        [self safeFinish];
    }
    
    [self.lock unlock];
}

/*
 Handles the result of an HKAnchoredObjectQuery, and starts a new query if needed
 */
- (void)handleResults:(NSArray<HKSample *> *)results
            newAnchor:(HKQueryAnchor *)newAnchor
                error:(NSError *)error
       itemIdentifier:(NSString *)itemIdentifier {
    [self.lock lock];
    // Check our actual state under the lock
    
    if (![self isExecuting] || [self isCancelled]) {
        // Give up immediately if we've been cancelled or are no longer executing
        [self.lock unlock];
        return;
    }
    if (error) {
        // Give up if there was an error performing the query
        self.error = error;
        [self safeFinish];
        [self.lock unlock];
        return;
    }
    
    [self.lock unlock];
    
    BOOL doContinue = (results && [results count] > 0);
    if (doContinue) {        
        id<ORK1DataCollectionManagerDelegate> delegate = _manager.delegate;
        
        BOOL handoutSuccess = NO;
        
        if (delegate) {
            if ([_collector isKindOfClass:[ORK1HealthCollector class]]
                && [delegate respondsToSelector:@selector(healthCollector:didCollectSamples:)]) {
                handoutSuccess = [delegate healthCollector:(ORK1HealthCollector *)_collector didCollectSamples:results];
            } else if ([_collector isKindOfClass:[ORK1HealthCorrelationCollector class]]
                       && [delegate respondsToSelector:@selector(healthCorrelationCollector:didCollectCorrelations:)]) {
                handoutSuccess = [delegate healthCorrelationCollector:(ORK1HealthCorrelationCollector *)_collector didCollectCorrelations:(NSArray<HKCorrelation *> *)results];
            }
        }
        
        if (!handoutSuccess) {
            doContinue = NO;
            self.error = [NSError errorWithDomain:ORK1ErrorDomain code:ORK1ErrorException userInfo:@{NSLocalizedFailureReasonErrorKey: @"Results were not properly delivered to the data collection manager delegate."}];
        }
    }
    
    if (doContinue) {
        // Do the next fetch
        self->_currentAnchor = newAnchor;
        [self doNextQuery];

    } else {
        // Stop for now (even if maybe we haven't fetched all the records)
        [self safeFinish];
    }
}

@end
