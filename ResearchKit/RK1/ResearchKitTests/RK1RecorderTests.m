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


@import XCTest;
@import ResearchKit.Private;

@import CoreLocation;
@import CoreMotion;


@interface RK1MockLocationManager : CLLocationManager

@end


@implementation RK1MockLocationManager

- (void)setPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically {
    
}

@end


@interface RK1MockLocationRecorder : RK1LocationRecorder

@end


@implementation RK1MockLocationRecorder

- (CLLocationManager *)createLocationManager {
    return [[RK1MockLocationManager alloc] init];
}

@end


@interface RK1MockTouch : UITouch

@end


@implementation RK1MockTouch

- (CGPoint)locationInView:(UIView *)view {
    return CGPointMake(11.0, 12.0);
}

- (NSTimeInterval)timestamp {
    return 3000.0;
}

- (UITouchPhase)phase {
    return UITouchPhaseMoved;
}

@end


@interface RK1MockMotionManager : CMMotionManager

- (void)injectMotion:(CMDeviceMotion *)motion;

- (void)injectAccelerometerData:(CMAccelerometerData *)accelerometerData;

@end


@implementation RK1MockMotionManager {
    CMDeviceMotionHandler _motionHandler;
    CMAccelerometerHandler _accelerometerHandler;
}

- (void)injectMotion:(CMDeviceMotion *)motion {
    _motionHandler(motion, nil);
}

- (void)injectAccelerometerData:(CMAccelerometerData *)accelerometerData {
    _accelerometerHandler(accelerometerData, nil);
}

- (void)startDeviceMotionUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMDeviceMotionHandler)handler {
    _motionHandler = handler;
    [super startDeviceMotionUpdatesToQueue:queue withHandler:handler];
}

- (void)startAccelerometerUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMAccelerometerHandler)handler {
    _accelerometerHandler = handler;
    [super startAccelerometerUpdatesToQueue:queue withHandler:handler];
}

- (BOOL)isAccelerometerAvailable {
    return YES;
}

- (BOOL)isDeviceMotionAvailable {
    return YES;
}

@end


@interface RK1MockPedometer : CMPedometer

- (void)injectData:(CMPedometerData *)data;

@end


@implementation RK1MockPedometer {
    CMPedometerHandler _handler;
}

- (void)injectData:(CMPedometerData *)data {
    _handler(data, nil);
}

- (void)startPedometerUpdatesFromDate:(NSDate *)start withHandler:(CMPedometerHandler)handler {
     _handler = handler;
}

+ (BOOL)isStepCountingAvailable {
    return YES;
}

@end


@interface RK1MockAccelerometerRecorder : RK1AccelerometerRecorder

@property (nonatomic, strong) RK1MockMotionManager* mockManager;

@end


@implementation RK1MockAccelerometerRecorder

- (CMMotionManager *)createMotionManager {
    return _mockManager;
}

@end


@interface RK1MockAccelerometerData : CMAccelerometerData

@end


@implementation RK1MockAccelerometerData

- (CMAcceleration)acceleration {
    return (CMAcceleration){.x=0.1, .y=0.12, .z=0.123};
}

- (NSTimeInterval)timestamp {
    return 1000.0;
}

@end


@interface RK1MockPedometerRecorder : RK1PedometerRecorder

@property (nonatomic, strong) RK1MockPedometer* mockPedometer;

@end


@implementation RK1MockPedometerRecorder

- (CMPedometer *)createPedometer {
    return _mockPedometer;
}

@end


@interface RK1MockPedometerData : CMPedometerData

@end


@implementation RK1MockPedometerData

- (NSDate *)startDate {
    return  [NSDate dateWithTimeIntervalSinceReferenceDate:1000.0];
}

- (NSDate *)endDate {
    return  [NSDate dateWithTimeIntervalSinceReferenceDate:1001.0];
}

- (NSNumber *)numberOfSteps {
    return @(2);
}

- (NSNumber *)distance {
    return @(1.2);
}

- (NSNumber *)floorsAscended {
    return @(0.1);
}

- (NSNumber *)floorsDescended {
    return @(0);
}

@end


@interface RK1MockDeviceMotionRecorder : RK1DeviceMotionRecorder

@property (nonatomic, strong) RK1MockMotionManager* mockManager;

@end


@implementation RK1MockDeviceMotionRecorder

- (CMMotionManager *)createMotionManager {
    return _mockManager;
}

@end


@interface RK1MockAttitude : CMAttitude

@end


@implementation RK1MockAttitude

- (CMQuaternion)quaternion {
    return (CMQuaternion){.x=0.1, .y=0.12, .z=0.123, .w=0.1234};
}

@end


@interface RK1MockDeviceMotion : CMDeviceMotion

@end


@implementation RK1MockDeviceMotion

- (NSTimeInterval)timestamp {
    return 1000.0;
}

- (CMAttitude *)attitude {
    return [RK1MockAttitude new];
}

- (CMRotationRate)rotationRate {
    return (CMRotationRate){.x=0.1, .y=0.12, .z=0.123};
}

- (CMAcceleration)gravity {
    return (CMAcceleration){.x=0.2, .y=0.23, .z=0.234};
}

- (CMAcceleration)userAcceleration {
    return (CMAcceleration){.x=0.3, .y=0.34, .z=0.345};
}

- (CMCalibratedMagneticField)magneticField {
    return (CMCalibratedMagneticField){.field=(CMMagneticField){.x=0.4, .y=0.45, .z=0.456}, .accuracy=CMMagneticFieldCalibrationAccuracyHigh};
}

@end


static BOOL ork_doubleEqual(double x, double y) {
    static double K = 1;
    return (fabs(x-y) < K * DBL_EPSILON * fabs(x+y) || fabs(x-y) < DBL_MIN);
}

#pragma mark - RK1RecorderTests
#pragma mark -

@interface RK1RecorderTests : XCTestCase <RK1RecorderDelegate>

@end


@implementation RK1RecorderTests {
    NSString  *_outputPath;
    RK1Recorder *_recorder;
    RK1Result *_result;
    NSArray   *_items;
}

static const NSInteger kNumberOfSamples = 5;

- (void)setUp {
    [super setUp];
    
    if (_outputPath == nil) {
        
        _outputPath = [NSBundle bundleForClass:[self class]].bundlePath;
        _outputPath = [_outputPath stringByAppendingPathExtension:@"testdir"];
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:_outputPath withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            NSLog(@"Failed to create directory %@", error);
        }
    }
    
    _recorder = nil;
    _result = nil;
    _items = nil;
}

- (void)tearDown {
    [super tearDown];
}

- (void)recorder:(RK1Recorder *)recorder didCompleteWithResult:(RK1Result *)result {
     NSLog(@"didCompleteWithResult: %@", result);
    _recorder = recorder;
    _result = result;
}

- (void)recorder:(RK1Recorder *)recorder didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error);
    _recorder = nil;
    _result = nil;
}

- (RK1Recorder *)createRecorder:(RK1RecorderConfiguration *)recorderConfiguration {
    RK1Recorder *recorder = [recorderConfiguration recorderForStep:[[RK1Step alloc] initWithIdentifier:@"step"]
                                                   outputDirectory:[NSURL fileURLWithPath:_outputPath]];
    XCTAssert([recorder.identifier isEqualToString:recorderConfiguration.identifier], @"");
    recorder.delegate = self;
    return recorder;
}

- (void)checkResult {
    
    XCTAssertNotNil(_result, @"");
    XCTAssert([_result isKindOfClass:[RK1FileResult class]], @"");
    XCTAssert([_recorder.identifier isEqualToString:_result.identifier], @"");
    
    RK1FileResult *fileResult = (RK1FileResult *)_result;
    
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:fileResult.fileURL ] options:(NSJSONReadingOptions)0 error:&error];
    XCTAssertNil(error, @"");
    XCTAssertNotNil(dict, @"");
    
    NSArray *items = dict[@"items"];
    XCTAssertEqual(items.count, kNumberOfSamples, @"");
    
    _items = items;
}

- (void)testLocationRecorder {
    
    RK1LocationRecorder *recorder = (RK1LocationRecorder *)[self createRecorder:[[RK1LocationRecorderConfiguration alloc] initWithIdentifier:@"location"]];
    XCTAssertTrue([recorder isKindOfClass:[RK1LocationRecorder class]], @"");
    
    recorder = [[RK1MockLocationRecorder alloc] initWithIdentifier:@"location"
                                                              step:recorder.step
                                                   outputDirectory:recorder.outputDirectory];
    recorder.delegate = self;
    [recorder start];
    
    id<CLLocationManagerDelegate> clDelegate = (id<CLLocationManagerDelegate>)recorder;
    
    double latitude = 37.31317;
    double longitude = -122.07238159997;
    double altitude = 11.0;
    double horizontalAccuracy = 12.0;
    double verticalAccuracy = 13.0;
    double course = 14.0;
    double speed = 15.0;
    NSDate *timestamp = [NSDate date];
    
    CLLocationManager *currentLocationManager = [recorder locationManager];
    
    for (NSInteger i = 0; i < kNumberOfSamples; i++) {
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                                                             altitude:altitude
                                                   horizontalAccuracy:horizontalAccuracy
                                                     verticalAccuracy:verticalAccuracy
                                                               course:course
                                                                speed:speed
                                                            timestamp:timestamp];
        
        [clDelegate locationManager:currentLocationManager didUpdateLocations:@[location]];
    }
    
    [recorder stop];
    [self checkResult];

    for (NSDictionary *sample in _items) {
        
        XCTAssertTrue(ork_doubleEqual(altitude, ((NSNumber *)sample[@"altitude"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(horizontalAccuracy, ((NSNumber *)sample[@"horizontalAccuracy"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(verticalAccuracy, ((NSNumber *)sample[@"verticalAccuracy"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(course, ((NSNumber *)sample[@"course"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(speed, ((NSNumber *)sample[@"speed"]).doubleValue), @"");
        XCTAssertEqualObjects(RK1StringFromDateISO8601(timestamp), sample[@"timestamp"], @"");
        XCTAssertTrue(ork_doubleEqual(latitude, ((NSNumber *)sample[@"coordinate"][@"latitude"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(longitude, ((NSNumber *)sample[@"coordinate"][@"longitude"]).doubleValue), @"");
    }
}

- (void)testAccelerometerRecorder {
    
    RK1AccelerometerRecorderConfiguration *recorderConfiguration = [[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"accelerometer" frequency:60.0];
    Class recorderClass = [RK1AccelerometerRecorder class];
    RK1AccelerometerRecorder *recorder = (RK1AccelerometerRecorder *)[self createRecorder:recorderConfiguration];
    
    XCTAssertTrue([recorder isKindOfClass:recorderClass], @"");
    XCTAssertTrue([recorder.identifier isEqualToString:recorderConfiguration.identifier], @"");
    
    recorder = [[RK1MockAccelerometerRecorder alloc] initWithIdentifier:@"accelerometer" frequency:recorder.frequency step:recorder.step outputDirectory:recorder.outputDirectory];
    recorder.delegate = self;
    RK1MockMotionManager *manager = [RK1MockMotionManager new];
    [(RK1MockAccelerometerRecorder*)recorder setMockManager:manager];
    
    [recorder start];
    
    RK1MockAccelerometerData *data = [RK1MockAccelerometerData new];
    for (NSInteger i = 0; i < kNumberOfSamples; i++) {
        [manager injectAccelerometerData:data];
    }
    
    [recorder stop];
    [self checkResult];
    
    for (NSDictionary *sample in _items) {
        XCTAssertTrue(ork_doubleEqual(data.timestamp, ((NSNumber *)sample[@"timestamp"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(data.acceleration.x, ((NSNumber *)sample[@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(data.acceleration.y, ((NSNumber *)sample[@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(data.acceleration.z, ((NSNumber *)sample[@"z"]).doubleValue), @"");
    }
}

- (void)testDeviceMotionRecorder {
    
    RK1DeviceMotionRecorderConfiguration *recorderConfiguration = [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"deviceMotion" frequency:60.0];
    Class recorderClass = [RK1DeviceMotionRecorder class];
    RK1DeviceMotionRecorder *recorder = (RK1DeviceMotionRecorder *)[self createRecorder:recorderConfiguration];
    
    XCTAssertTrue([recorder isKindOfClass:recorderClass], @"");
    
    recorder = [[RK1MockDeviceMotionRecorder alloc] initWithIdentifier:@"deviceMotion" frequency:recorder.frequency step:recorder.step outputDirectory:recorder.outputDirectory];
    recorder.delegate = self;
    RK1MockMotionManager *manager = [RK1MockMotionManager new];
    [(RK1MockAccelerometerRecorder*)recorder setMockManager:manager];
    
    [recorder start];
    
    RK1MockDeviceMotion *motion = [RK1MockDeviceMotion new];
    for (NSInteger i = 0; i < kNumberOfSamples; i++) {
        [manager injectMotion:motion];
    }
    
    [recorder stop];
    [self checkResult];
    
    for (NSDictionary *sample in _items) {
        XCTAssertTrue(ork_doubleEqual(motion.timestamp, ((NSNumber *)sample[@"timestamp"]).doubleValue), @"");
        
        XCTAssertTrue(ork_doubleEqual(motion.attitude.quaternion.x, ((NSNumber *)sample[@"attitude"][@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.attitude.quaternion.y, ((NSNumber *)sample[@"attitude"][@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.attitude.quaternion.z, ((NSNumber *)sample[@"attitude"][@"z"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.attitude.quaternion.w, ((NSNumber *)sample[@"attitude"][@"w"]).doubleValue), @"");
        
        XCTAssertTrue(ork_doubleEqual(motion.gravity.x, ((NSNumber *)sample[@"gravity"][@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.gravity.y, ((NSNumber *)sample[@"gravity"][@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.gravity.z, ((NSNumber *)sample[@"gravity"][@"z"]).doubleValue), @"");
        
        XCTAssertTrue(ork_doubleEqual(motion.magneticField.accuracy, ((NSNumber *)sample[@"magneticField"][@"accuracy"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.magneticField.field.x, ((NSNumber *)sample[@"magneticField"][@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.magneticField.field.y, ((NSNumber *)sample[@"magneticField"][@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.magneticField.field.z, ((NSNumber *)sample[@"magneticField"][@"z"]).doubleValue), @"");
        
        XCTAssertTrue(ork_doubleEqual(motion.rotationRate.x, ((NSNumber *)sample[@"rotationRate"][@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.rotationRate.y, ((NSNumber *)sample[@"rotationRate"][@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.rotationRate.z, ((NSNumber *)sample[@"rotationRate"][@"z"]).doubleValue), @"");
        
        XCTAssertTrue(ork_doubleEqual(motion.userAcceleration.x, ((NSNumber *)sample[@"userAcceleration"][@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.userAcceleration.y, ((NSNumber *)sample[@"userAcceleration"][@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(motion.userAcceleration.z, ((NSNumber *)sample[@"userAcceleration"][@"z"]).doubleValue), @"");
    }
}

- (void)testPedometerRecorder {
    
    Class recorderClass = [RK1PedometerRecorder class];
    RK1PedometerRecorder *recorder = (RK1PedometerRecorder *)[self createRecorder:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:@"pedometer"]];
    
    XCTAssertTrue([recorder isKindOfClass:recorderClass], @"");
    
    recorder = [[RK1MockPedometerRecorder alloc] initWithIdentifier:@"pedometer" step:recorder.step outputDirectory:recorder.outputDirectory];
    recorder.delegate = self;
    RK1MockPedometer *pedometer = [RK1MockPedometer new];
    [(RK1MockPedometerRecorder*)recorder setMockPedometer:pedometer];
    
    [recorder start];
    
    RK1MockPedometerData *data = [RK1MockPedometerData new];
    for (NSInteger i = 0; i < kNumberOfSamples; i++) {
        [pedometer injectData:data];
    }
    
    [recorder stop];
    [self checkResult];
    
    for (NSDictionary *sample in _items) {
        
        XCTAssertEqualObjects(RK1StringFromDateISO8601(data.startDate), sample[@"startDate"], @"");
        XCTAssertEqualObjects(RK1StringFromDateISO8601(data.endDate), sample[@"endDate"], @"");
        
        XCTAssertTrue(ork_doubleEqual(data.distance.doubleValue, ((NSNumber *)sample[@"distance"]).doubleValue), @"");
        XCTAssertEqual(data.numberOfSteps.integerValue, ((NSNumber *)sample[@"numberOfSteps"]).integerValue, @"");
        XCTAssertTrue(ork_doubleEqual(data.floorsAscended.doubleValue, ((NSNumber *)sample[@"floorsAscended"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual(data.floorsDescended.doubleValue, ((NSNumber *)sample[@"floorsDescended"]).doubleValue), @"");
    }
}

- (void)testTouchRecorder {
    
    Class recorderClass = [RK1TouchRecorder class];
    RK1TouchRecorder *recorder = (RK1TouchRecorder *)[self createRecorder:[[RK1TouchRecorderConfiguration alloc] initWithIdentifier:@"touch"]];
    
    XCTAssertTrue([recorder isKindOfClass:recorderClass], @"");
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    [recorder viewController:[UIViewController new] willStartStepWithView:view];
    [recorder start];
    
    RK1MockTouch *touch = [RK1MockTouch new];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    for (NSInteger i = 0; i < kNumberOfSamples; i++) {
        [recorder performSelector:@selector(view:didDetectTouch:) withObject:view withObject:touch];
    }
    
#pragma clang diagnostic pop
    
    [recorder stop];
    [self checkResult];
    
    for (NSDictionary *sample in _items) {
        
        XCTAssertTrue(ork_doubleEqual([touch locationInView:nil].x, ((NSNumber *)sample[@"x"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual([touch locationInView:nil].y, ((NSNumber *)sample[@"y"]).doubleValue), @"");
        XCTAssertTrue(ork_doubleEqual([touch timestamp], ((NSNumber *)sample[@"timestamp"]).doubleValue), @"");
        XCTAssertEqual(view.bounds.size.width, ((NSNumber *)sample[@"width"]).floatValue, @"");
        XCTAssertEqual(view.bounds.size.height, ((NSNumber *)sample[@"height"]).floatValue, @"");
        XCTAssertEqual(0, ((NSNumber *)sample[@"index"]).integerValue, @"");
        XCTAssertEqual([touch phase], ((NSNumber *)sample[@"phase"]).integerValue, @"");
    }
}

- (void)testAudioRecorder {
    
    RK1AudioRecorderConfiguration *recorderConfiguration = [[RK1AudioRecorderConfiguration alloc] initWithIdentifier:@"audio" recorderSettings:@{}];
    Class recorderClass = [RK1AudioRecorder class];
    RK1AudioRecorder *recorder = (RK1AudioRecorder *)[self createRecorder:recorderConfiguration];
    
    XCTAssertTrue([recorder isKindOfClass:recorderClass], @"");
}

- (void)testHealthQuantityTypeRecorder {
    
    HKUnit *bpmUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
    HKQuantityType *hbQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    RK1HealthQuantityTypeRecorderConfiguration *recorderConfiguration = [[RK1HealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:@"healtQuantityTypeRecorder" healthQuantityType:hbQuantityType unit:bpmUnit];
    Class recorderClass = [RK1HealthQuantityTypeRecorder class];
    RK1HealthQuantityTypeRecorder *recorder = (RK1HealthQuantityTypeRecorder *)[self createRecorder:recorderConfiguration];
    
    XCTAssertTrue([recorder isKindOfClass:recorderClass], @"");
}

@end
