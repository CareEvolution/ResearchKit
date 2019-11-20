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
@import ORK1Kit.Private;

#import "ORK1ESerialization.h"

#import <objc/runtime.h>


@interface ClassProperty : NSObject

@property (nonatomic, copy) NSString *propertyName;
@property (nonatomic, strong) Class propertyClass;
@property (nonatomic) BOOL isPrimitiveType;
@property (nonatomic) BOOL isBoolType;

- (instancetype)initWithObjcProperty:(objc_property_t)property;

@end


@implementation ClassProperty

- (instancetype)initWithObjcProperty:(objc_property_t)property {
    
    self = [super init];
    if (self) {
        const char *name = property_getName(property);
        self.propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        
        const char *type = property_getAttributes(property);
        NSString *typeString = [NSString stringWithUTF8String:type];
        NSArray *attributes = [typeString componentsSeparatedByString:@","];
        NSString *typeAttribute = attributes[0];
        
        _isPrimitiveType = YES;
        if ([typeAttribute hasPrefix:@"T@"]) {
             _isPrimitiveType = NO;
            Class typeClass = nil;
            if (typeAttribute.length > 4) {
                NSString *typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, typeAttribute.length-4)];  //turns @"NSDate" into NSDate
                typeClass = NSClassFromString(typeClassName);
            } else {
                typeClass = [NSObject class];
            }
            self.propertyClass = typeClass;
           
        } else if ([@[@"Ti", @"Tq", @"TI", @"TQ"] containsObject:typeAttribute]) {
            self.propertyClass = [NSNumber class];
        }
        else if ([typeAttribute isEqualToString:@"TB"]) {
            self.propertyClass = [NSNumber class];
            _isBoolType = YES;
        }
    }
    return self;
}

@end


@interface MockCountingDictionary : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (void)startObserving;

- (void)stopObserving;

- (NSArray *)unTouchedKeys;

@property (nonatomic, strong) NSMutableSet *touchedKeys;

@end


@implementation MockCountingDictionary {
    NSDictionary *_d;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    _d = dictionary;
    return self;
}

- (BOOL)isKindOfClass:(Class)aClass {
    if ([aClass isSubclassOfClass:[NSDictionary class]]) {
        return YES;
    }
    return [super isKindOfClass:aClass];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [_d methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_d respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_d];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (void)startObserving {
    self.touchedKeys = [NSMutableSet new];
}

- (void)stopObserving {
    self.touchedKeys = nil;
}

- (NSArray *)unTouchedKeys {
    NSMutableArray *unTouchedKeys = [NSMutableArray new];
    NSArray *keys = [_d allKeys];
    for (NSString *key in keys) {
        if ([self.touchedKeys containsObject:key] == NO) {
            [unTouchedKeys addObject:key];
        }
    }
    return [unTouchedKeys copy];
}

- (id)objectForKey:(id)aKey {
    if (aKey && self.touchedKeys) {
        [self.touchedKeys addObject:aKey];
    }
    return [_d objectForKey:aKey];
}

- (id)objectForKeyedSubscript:(id)key {
    if (key && self.touchedKeys) {
        [self.touchedKeys addObject:key];
    }
    return [_d objectForKeyedSubscript:key];
}

@end

#define ORK1_MAKE_TEST_INIT(class, block) \
@interface class (ORK1Test) \
- (instancetype)orktest_init; \
@end \
\
@implementation class (ORK1Test) \
- (instancetype)orktest_init { \
    return block(); \
} \
@end \


/*
 Add an orktest_init method to all the classes which make init unavailable. This
 allows us to write very short code to instantiate valid objects during these tests.
 */
ORK1_MAKE_TEST_INIT(ORK1StepNavigationRule, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1SkipStepNavigationRule, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1StepModifier, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1KeyValueStepModifier, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1AnswerFormat, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1LoginStep, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString title:@"title" text:@"text" loginViewControllerClass:NSClassFromString(@"ORK1LoginStepViewController") ];});
ORK1_MAKE_TEST_INIT(ORK1VerificationStep, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString text:@"text" verificationViewControllerClass:NSClassFromString(@"ORK1VerificationStepViewController") ];});
ORK1_MAKE_TEST_INIT(ORK1Step, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString];});
ORK1_MAKE_TEST_INIT(ORK1ReviewStep, ^{return [[self class] standaloneReviewStepWithIdentifier:[NSUUID UUID].UUIDString steps:@[] resultSource:[ORK1TaskResult new]];});
ORK1_MAKE_TEST_INIT(ORK1OrderedTask, ^{return [self initWithIdentifier:@"test1" steps:nil];});
ORK1_MAKE_TEST_INIT(ORK1ImageChoice, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1TextChoice, ^{return [super init];});
ORK1_MAKE_TEST_INIT(ORK1PredicateStepNavigationRule, ^{return [self initWithResultPredicates:@[[ORK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:[ORK1ResultSelector selectorWithResultIdentifier:@"test"] expectedAnswer:YES]] destinationStepIdentifiers:@[@"test2"]];});
ORK1_MAKE_TEST_INIT(ORK1ResultSelector, ^{return [self initWithResultIdentifier:@"resultIdentifier"];});
ORK1_MAKE_TEST_INIT(ORK1RecorderConfiguration, ^{return [self initWithIdentifier:@"testRecorder"];});
ORK1_MAKE_TEST_INIT(ORK1AccelerometerRecorderConfiguration, ^{return [super initWithIdentifier:@"testRecorder"];});
ORK1_MAKE_TEST_INIT(ORK1HealthQuantityTypeRecorderConfiguration, ^{ return [super initWithIdentifier:@"testRecorder"];});
ORK1_MAKE_TEST_INIT(ORK1AudioRecorderConfiguration, ^{ return [super initWithIdentifier:@"testRecorder"];});
ORK1_MAKE_TEST_INIT(ORK1DeviceMotionRecorderConfiguration, ^{ return [super initWithIdentifier:@"testRecorder"];});
ORK1_MAKE_TEST_INIT(ORK1Location, (^{
    ORK1Location *location = [self initWithCoordinate:CLLocationCoordinate2DMake(2.0, 3.0) region:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(2.0, 3.0) radius:100.0 identifier:@"identifier"] userInput:@"addressString" addressDictionary:@{@"city":@"city", @"street":@"street"}];
    return location;
}));
ORK1_MAKE_TEST_INIT(HKSampleType, (^{
    return [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
}))
ORK1_MAKE_TEST_INIT(HKQuantityType, (^{
    return [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
}))
ORK1_MAKE_TEST_INIT(HKCorrelationType, (^{
    return [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierBloodPressure];
}))
ORK1_MAKE_TEST_INIT(HKCharacteristicType, (^{
    return [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType];
}))
ORK1_MAKE_TEST_INIT(CLCircularRegion, (^{
    return [self initWithCenter:CLLocationCoordinate2DMake(2.0, 3.0) radius:100.0 identifier:@"identifier"];
}))
ORK1_MAKE_TEST_INIT(NSNumber, (^{
    return [self initWithInt:123];
}))
ORK1_MAKE_TEST_INIT(HKUnit, (^{
    return [HKUnit unitFromString:@"kg"];
}))
ORK1_MAKE_TEST_INIT(NSURL, (^{
    return [self initFileURLWithPath:@"/usr"];
}))
ORK1_MAKE_TEST_INIT(NSTimeZone, (^{
    return [NSTimeZone timeZoneForSecondsFromGMT:60*60];
}))
ORK1_MAKE_TEST_INIT(NSCalendar, (^{
    return [self initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}))
ORK1_MAKE_TEST_INIT(NSRegularExpression, (^{
    return [self initWithPattern:@"." options:0 error:nil];
}))


@interface ORK1JSONSerializationTests : XCTestCase <NSKeyedUnarchiverDelegate>

@end


@implementation ORK1JSONSerializationTests

- (Class)unarchiver:(NSKeyedUnarchiver *)unarchiver cannotDecodeObjectOfClassName:(NSString *)name originalClasses:(NSArray *)classNames {
    NSLog(@"Cannot decode object with class: %@ (original classes: %@)", name, classNames);
    return nil;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTaskResult {
    
    //ORK1TaskResult *result = [[ORK1TaskResult alloc] initWithTaskIdentifier:@"a000012" taskRunUUID:[NSUUID UUID] outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    
    ORK1QuestionResult *qr = [[ORK1QuestionResult alloc] init];
    qr.answer = @(1010);
    qr.questionType = ORK1QuestionTypeInteger;
    qr.identifier = @"a000012.s05";
    
    ORK1StepResult *stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:@"stepIdentifier" results:@[qr]];
    stepResult.results = @[qr];
}

- (void)testTaskModel {
    
    ORK1ActiveStep *activeStep = [[ORK1ActiveStep alloc] initWithIdentifier:@"id"];
    activeStep.shouldPlaySoundOnStart = YES;
    activeStep.shouldVibrateOnStart = YES;
    activeStep.stepDuration = 100.0;
    activeStep.recorderConfigurations =
    @[[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"id.accelerometer" frequency:11.0],
      [[ORK1TouchRecorderConfiguration alloc] initWithIdentifier:@"id.touch"],
      [[ORK1AudioRecorderConfiguration alloc] initWithIdentifier:@"id.audio" recorderSettings:@{}]];
    
    ORK1QuestionStep *questionStep = [ORK1QuestionStep questionStepWithIdentifier:@"id1" title:@"question" answer:[ORK1AnswerFormat choiceAnswerFormatWithStyle:ORK1ChoiceAnswerStyleMultipleChoice textChoices:@[[[ORK1TextChoice alloc] initWithText:@"test1" detailText:nil value:@(1) exclusive:NO]  ]]];
    
    ORK1QuestionStep *questionStep2 = [ORK1QuestionStep questionStepWithIdentifier:@"id2"
                                                                     title:@"question" answer:[ORK1NumericAnswerFormat decimalAnswerFormatWithUnit:@"kg"]];

    ORK1QuestionStep *questionStep3 = [ORK1QuestionStep questionStepWithIdentifier:@"id3"
                                                                           title:@"question" answer:[ORK1ScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10.0 minimumValue:1.0 defaultValue:5.0 step:1.0 vertical:YES maximumValueDescription:@"High value" minimumValueDescription:@"Low value"]];

    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:@"id" steps:@[activeStep, questionStep, questionStep2, questionStep3]];
    
    NSDictionary *dict1 = [ORK1ESerializer JSONObjectForObject:task error:nil];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict1 options:NSJSONWritingPrettyPrinted error:nil];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"json"]];
    [data writeToFile:tempPath atomically:YES];
    NSLog(@"JSON file at %@", tempPath);
    
    ORK1OrderedTask *task2 = [ORK1ESerializer objectFromJSONObject:dict1 error:nil];
    
    NSDictionary *dict2 = [ORK1ESerializer JSONObjectForObject:task2 error:nil];
    
    XCTAssertTrue([dict1 isEqualToDictionary:dict2], @"Should be equal");
    
}

- (NSArray<Class> *)classesWithSecureCoding {
    
    NSArray *classesExcluded = @[]; // classes not intended to be serialized standalone
    NSMutableArray *stringsForClassesExcluded = [NSMutableArray array];
    for (Class c in classesExcluded) {
        [stringsForClassesExcluded addObject:NSStringFromClass(c)];
    }
    
    // Find all classes that conform to NSSecureCoding
    NSMutableArray<Class> *classesWithSecureCoding = [NSMutableArray new];
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    numClasses = objc_getClassList(classes, numClasses);
    for (int index = 0; index < numClasses; index++) {
        Class aClass = classes[index];
        if ([stringsForClassesExcluded containsObject:NSStringFromClass(aClass)]) {
            continue;
        }
        
        if ([NSStringFromClass(aClass) hasPrefix:@"ORK1"] &&
            [aClass conformsToProtocol:@protocol(NSSecureCoding)]) {
            [classesWithSecureCoding addObject:aClass];
        }
    }
    
    return [classesWithSecureCoding copy];
}

// JSON Serialization
- (void)testORK1Serialization {
    
    // Find all classes that are serializable this way
    NSArray *classesWithORK1Serialization = [ORK1ESerializer serializableClasses];
    
    // All classes that conform to NSSecureCoding should also support ORK1ESerialization
    NSArray *classesWithSecureCoding = [self classesWithSecureCoding];
    
    NSArray *classesExcludedForORK1ESerialization = @[
                                                     [ORK1StepNavigationRule class],     // abstract base class
                                                     [ORK1SkipStepNavigationRule class],     // abstract base class
                                                     [ORK1StepModifier class],     // abstract base class
                                                     [ORK1PredicateSkipStepNavigationRule class],     // NSPredicate doesn't yet support JSON serialzation
                                                     [ORK1KeyValueStepModifier class],     // NSPredicate doesn't yet support JSON serialzation
                                                     [ORK1Collector class], // ORK1Collector doesn't support JSON serialzation
                                                     [ORK1HealthCollector class],
                                                     [ORK1HealthCorrelationCollector class],
                                                     [ORK1MotionActivityCollector class]
                                                     ];
    
    if ((classesExcludedForORK1ESerialization.count + classesWithORK1Serialization.count) != classesWithSecureCoding.count) {
        NSMutableArray *unregisteredList = [classesWithSecureCoding mutableCopy];
        [unregisteredList removeObjectsInArray:classesWithORK1Serialization];
        [unregisteredList removeObjectsInArray:classesExcludedForORK1ESerialization];
        XCTAssertEqual(unregisteredList.count, 0, @"Classes didn't implement ORK1Serialization %@", unregisteredList);
    }
    
    // Predefined exception
    NSArray *propertyExclusionList = @[
                                       @"superclass",
                                       @"description",
                                       @"descriptionSuffix",
                                       @"debugDescription",
                                       @"hash",
                                       @"requestedHealthKitTypesForReading",
                                       @"requestedHealthKitTypesForWriting",
                                       @"healthKitUnit",
                                       @"answer",
                                       @"firstResult",
                                       @"ORK1PageStep.steps",
                                       @"ORK1NavigablePageStep.steps",
                                       @"ORK1TextAnswerFormat.validationRegex",
                                       @"ORK1RegistrationStep.passcodeValidationRegex",
                                       ];
    NSArray *knownNotSerializedProperties = @[
                                              @"ORK1Step.task",
                                              @"ORK1Step.restorable",
                                              @"ORK1ReviewStep.isStandalone",
                                              @"ORK1AnswerFormat.questionType",
                                              @"ORK1QuestionStep.questionType",
                                              @"ORK1ActiveStep.image",
                                              @"ORK1ConsentSection.customImage",
                                              @"ORK1ConsentSection.escapedContent",
                                              @"ORK1ConsentSignature.signatureImage",
                                              @"ORK1ConsentDocument.writer",
                                              @"ORK1ConsentDocument.signatureFormatter",
                                              @"ORK1ConsentDocument.sectionFormatter",
                                              @"ORK1ConsentDocument.sections",
                                              @"ORK1ConsentDocument.signatures",
                                              @"ORK1ContinuousScaleAnswerFormat.numberFormatter",
                                              @"ORK1FormItem.step",
                                              @"ORK1TimeIntervalAnswerFormat.maximumInterval",
                                              @"ORK1TimeIntervalAnswerFormat.defaultInterval",
                                              @"ORK1TimeIntervalAnswerFormat.step",
                                              @"ORK1TextAnswerFormat.maximumLength",
                                              @"ORK1TextAnswerFormat.autocapitalizationType",
                                              @"ORK1TextAnswerFormat.autocorrectionType",
                                              @"ORK1TextAnswerFormat.spellCheckingType",
                                              @"ORK1InstructionStep.image",
                                              @"ORK1InstructionStep.auxiliaryImage",
                                              @"ORK1InstructionStep.iconImage",
                                              @"ORK1ImageChoice.normalStateImage",
                                              @"ORK1ImageChoice.selectedStateImage",
                                              @"ORK1ImageCaptureStep.templateImage",
                                              @"ORK1VideoCaptureStep.templateImage",
                                              @"ORK1Step.requestedPermissions",
                                              @"ORK1OrderedTask.providesBackgroundAudioPrompts",
                                              @"ORK1ScaleAnswerFormat.numberFormatter",
                                              @"ORK1SpatialSpanMemoryStep.customTargetImage",
                                              @"ORK1Step.allowsBackNavigation",
                                              @"ORK1AnswerFormat.healthKitUserUnit",
                                              @"ORK1OrderedTask.requestedPermissions",
                                              @"ORK1Step.showsProgress",
                                              @"ORK1Result.saveable",
                                              @"ORK1CollectionResult.firstResult",
                                              @"ORK1ScaleAnswerFormat.minimumImage",
                                              @"ORK1ScaleAnswerFormat.maximumImage",
                                              @"ORK1ContinuousScaleAnswerFormat.minimumImage",
                                              @"ORK1ContinuousScaleAnswerFormat.maximumImage",
                                              @"ORK1HeightAnswerFormat.useMetricSystem",
                                              @"ORK1WeightAnswerFormat.useMetricSystem",
                                              @"ORK1DataResult.data",
                                              @"ORK1VerificationStep.verificationViewControllerClass",
                                              @"ORK1LoginStep.loginViewControllerClass",
                                              @"ORK1RegistrationStep.passcodeValidationRegularExpression",
                                              @"ORK1RegistrationStep.passcodeInvalidMessage",
                                              @"ORK1SignatureResult.signatureImage",
                                              @"ORK1SignatureResult.signaturePath",
                                              @"ORK1PageStep.steps",
                                              @"ORK1NavigablePageStep.steps",
                                              ];
    NSArray *allowedUnTouchedKeys = @[@"_class"];
    
    // Test Each class
    for (Class aClass in classesWithORK1Serialization) {
        
        id instance = [self instanceForClass:aClass];
        
        // Find all properties of this class
        NSMutableArray *propertyNames = [NSMutableArray array];
        NSMutableDictionary *dottedPropertyNames = [NSMutableDictionary dictionary];
        unsigned int count;
        
        // Walk superclasses of this class, looking at all properties.
        // Otherwise we don't catch failures to base-call in initWithDictionary (etc)
        Class currentClass = aClass;
        while ([classesWithORK1Serialization containsObject:currentClass]) {
            
            objc_property_t *props = class_copyPropertyList(currentClass, &count);
            for (int i = 0; i < count; i++) {
                objc_property_t property = props[i];
                ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
                
                NSString *dottedPropertyName = [NSString stringWithFormat:@"%@.%@",NSStringFromClass(currentClass),p.propertyName];
                if ([propertyExclusionList containsObject: p.propertyName] == NO &&
                    [propertyExclusionList containsObject: dottedPropertyName] == NO) {
                    if (p.isPrimitiveType == NO) {
                        // Assign value to object type property
                        if (p.propertyClass == [NSObject class] && (aClass == [ORK1TextChoice class] || aClass == [ORK1ImageChoice class]))
                        {
                            // Map NSObject to string, since it's used where either a string or a number is acceptable
                            [instance setValue:@"test" forKey:p.propertyName];
                        } else {
                            id itemInstance = [self instanceForClass:p.propertyClass];
                            [instance setValue:itemInstance forKey:p.propertyName];
                        }
                    }
                    [propertyNames addObject:p.propertyName];
                    dottedPropertyNames[p.propertyName] = dottedPropertyName;
                }
            }
            currentClass = [currentClass superclass];

        }
        
        if ([aClass isSubclassOfClass:[ORK1TextScaleAnswerFormat class]]) {
            [instance setValue:@[[ORK1TextChoice choiceWithText:@"Poor" value:@1], [ORK1TextChoice choiceWithText:@"Excellent" value:@2]] forKey:@"textChoices"];
        }
        if ([aClass isSubclassOfClass:[ORK1ContinuousScaleAnswerFormat class]]) {
            [instance setValue:@(100) forKey:@"maximum"];
            [instance setValue:@(ORK1NumberFormattingStylePercent) forKey:@"numberStyle"];
        } else if ([aClass isSubclassOfClass:[ORK1ScaleAnswerFormat class]]) {
            [instance setValue:@(0) forKey:@"minimum"];
            [instance setValue:@(100) forKey:@"maximum"];
            [instance setValue:@(10) forKey:@"step"];
        } else if ([aClass isSubclassOfClass:[ORK1ImageChoice class]] || [aClass isSubclassOfClass:[ORK1TextChoice class]]) {
            [instance setValue:@"blah" forKey:@"value"];
        } else if ([aClass isSubclassOfClass:[ORK1ConsentSection class]]) {
            [instance setValue:[NSURL URLWithString:@"http://www.apple.com/"] forKey:@"customAnimationURL"];
        } else if ([aClass isSubclassOfClass:[ORK1ImageCaptureStep class]] || [aClass isSubclassOfClass:[ORK1VideoCaptureStep class]]) {
            [instance setValue:[NSValue valueWithUIEdgeInsets:(UIEdgeInsets){1,1,1,1}] forKey:@"templateImageInsets"];
        } else if ([aClass isSubclassOfClass:[ORK1TimeIntervalAnswerFormat class]]) {
            [instance setValue:@(1) forKey:@"step"];
        } else if ([aClass isSubclassOfClass:[ORK1LoginStep class]]) {
            [instance setValue:NSStringFromClass([ORK1LoginStepViewController class]) forKey:@"loginViewControllerString"];
        } else if ([aClass isSubclassOfClass:[ORK1VerificationStep class]]) {
            [instance setValue:NSStringFromClass([ORK1VerificationStepViewController class]) forKey:@"verificationViewControllerString"];
        } else if ([aClass isSubclassOfClass:[ORK1ReviewStep class]]) {
            [instance setValue:[ORK1TaskResult new] forKey:@"resultSource"]; // Manually add here because it's a protocol and hence property doesn't have a class
        }
        
        // Serialization
        id mockDictionary = [[MockCountingDictionary alloc] initWithDictionary:[ORK1ESerializer JSONObjectForObject:instance error:NULL]];
        
        // Must contain corrected _class field
        XCTAssertTrue([NSStringFromClass(aClass) isEqualToString:mockDictionary[@"_class"]]);
        
        // All properties should have matching fields in dictionary (allow predefined exceptions)
        for (NSString *pName in propertyNames) {
            if (mockDictionary[pName] == nil) {
                NSString *notSerializedProperty = dottedPropertyNames[pName];
                BOOL success = [knownNotSerializedProperties containsObject:notSerializedProperty];
                if (!success) {
                    XCTAssertTrue(success, "Unexpected notSerializedProperty = %@ (%@)", notSerializedProperty, NSStringFromClass(aClass));
                }
            }
        }
        
        [mockDictionary startObserving];
       
        id instance2 = [ORK1ESerializer objectFromJSONObject:mockDictionary error:NULL];
       
        NSArray *unTouchedKeys = [mockDictionary unTouchedKeys];
        
        // Make sure all keys are touched by initializer
        for (NSString *key in unTouchedKeys) {
            XCTAssertTrue([allowedUnTouchedKeys containsObject:key], @"untouched %@", key);
        }
        
        [mockDictionary stopObserving];
        
        // Serialize again, the output ought to be equal
        NSDictionary *dictionary2 = [ORK1ESerializer JSONObjectForObject:instance2 error:NULL];
        BOOL isMatch = [mockDictionary isEqualToDictionary:dictionary2];
        if (!isMatch) {
            XCTAssertTrue(isMatch, @"Should be equal for class: %@", NSStringFromClass(aClass));
        }
    }

}

- (BOOL)applySomeValueToClassProperty:(ClassProperty *)p forObject:(id)instance index:(NSInteger)index forEqualityCheck:(BOOL)equality {
    // return YES if the index makes it distinct
    
    if (p.isPrimitiveType) {
        if (p.propertyClass == [NSNumber class]) {
            if (p.isBoolType) {
                XCTAssertNoThrow([instance setValue:index?@YES:@NO forKey:p.propertyName]);
            } else {
                XCTAssertNoThrow([instance setValue:index?@(12):@(123) forKey:p.propertyName]);
            }
            return YES;
        } else {
            return NO;
        }
    }
    
    Class aClass = [instance class];
    // Assign value to object type property
    if (p.propertyClass == [NSObject class] && (aClass == [ORK1TextChoice class]|| aClass == [ORK1ImageChoice class] || (aClass == [ORK1QuestionResult class])))
    {
        // Map NSObject to string, since it's used where either a string or a number is acceptable
        [instance setValue:index?@"blah":@"test" forKey:p.propertyName];
    } else if (p.propertyClass == [NSNumber class]) {
        [instance setValue:index?@(12):@(123) forKey:p.propertyName];
    } else if (p.propertyClass == [NSURL class]) {
        NSURL *url = [NSURL fileURLWithFileSystemRepresentation:[index?@"xxx":@"blah" UTF8String]  isDirectory:NO relativeToURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
        [instance setValue:url forKey:p.propertyName];
        [[NSFileManager defaultManager] createFileAtPath:[url path] contents:nil attributes:nil];
    } else if (p.propertyClass == [HKUnit class]) {
        [instance setValue:[HKUnit unitFromString:index?@"g":@"kg"] forKey:p.propertyName];
    } else if (p.propertyClass == [HKQuantityType class]) {
        [instance setValue:[HKQuantityType quantityTypeForIdentifier:index?HKQuantityTypeIdentifierActiveEnergyBurned : HKQuantityTypeIdentifierBodyMass] forKey:p.propertyName];
    } else if (p.propertyClass == [HKCharacteristicType class]) {
        [instance setValue:[HKCharacteristicType characteristicTypeForIdentifier:index?HKCharacteristicTypeIdentifierBiologicalSex: HKCharacteristicTypeIdentifierBloodType] forKey:p.propertyName];
    } else if (p.propertyClass == [NSCalendar class]) {
        [instance setValue:index?[NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese]:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] forKey:p.propertyName];
    } else if (p.propertyClass == [NSTimeZone class]) {
        [instance setValue:index?[NSTimeZone timeZoneWithName:[NSTimeZone knownTimeZoneNames][0]]:[NSTimeZone timeZoneForSecondsFromGMT:1000] forKey:p.propertyName];
    } else if (p.propertyClass == [ORK1Location class]) {
        [instance setValue:[[ORK1Location alloc] initWithCoordinate:CLLocationCoordinate2DMake(index? 2.0 : 3.0, 3.0) region:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(2.0, 3.0) radius:100.0 identifier:@"identifier"] userInput:@"addressString" addressDictionary:@{@"city":@"city", @"street":@"street"}] forKey:p.propertyName];
    } else if (p.propertyClass == [CLCircularRegion class]) {
        [instance setValue:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(index? 2.0 : 3.0, 3.0) radius:100.0 identifier:@"identifier"] forKey:p.propertyName];
    } else if (p.propertyClass == [NSPredicate class]) {
        [instance setValue:[NSPredicate predicateWithFormat:index?@"1 == 1":@"1 == 2"] forKey:p.propertyName];
    } else if (p.propertyClass == [NSRegularExpression class]) {
        [instance setValue:[NSRegularExpression regularExpressionWithPattern:index ? @"." : @"[A-Z]"
                                                                     options:index ? 0 : NSRegularExpressionCaseInsensitive
                                                                       error:nil] forKey:p.propertyName];
    } else if (equality && (p.propertyClass == [UIImage class])) {
        // do nothing - meaningless for the equality check
        return NO;
    } else if (aClass == [ORK1ReviewStep class] && [p.propertyName isEqualToString:@"resultSource"]) {
        [instance setValue:[[ORK1TaskResult alloc] initWithIdentifier:@"blah"] forKey:p.propertyName];
        return NO;
    } else {
        id instanceForChild = [self instanceForClass:p.propertyClass];
        [instance setValue:instanceForChild forKey:p.propertyName];
        return NO;
    }
    return YES;
}

- (void)testSecureCoding {
    
    NSArray<Class> *classesWithSecureCoding = [self classesWithSecureCoding];
    
    // Predefined exception
    NSArray *propertyExclusionList = @[@"superclass",
                                       @"description",
                                       @"descriptionSuffix",
                                       @"debugDescription",
                                       @"hash",
                                       @"requestedHealthKitTypesForReading",
                                       @"requestedHealthKitTypesForWriting",
                                       @"healthKitUnit",
                                       @"firstResult",
                                       @"correlationType",
                                       @"sampleType",
                                       @"unit",
                                       @"ORK1PageStep.steps",
                                       @"ORK1NavigablePageStep.steps",
                                       @"ORK1TextAnswerFormat.validationRegex",
                                       @"ORK1RegistrationStep.passcodeValidationRegex",
                                       ];
    NSArray *knownNotSerializedProperties = @[@"ORK1ConsentDocument.writer", // created on demand
                                              @"ORK1ConsentDocument.signatureFormatter", // created on demand
                                              @"ORK1ConsentDocument.sectionFormatter", // created on demand
                                              @"ORK1Step.task", // weak ref - object will be nil
                                              @"ORK1FormItem.step",  // weak ref - object will be nil
                                              
                                              // id<> properties - these are actually serialized, but we can't fill them in properly for this test
                                              @"ORK1TextChoice.value",
                                              @"ORK1ImageChoice.value",
                                              @"ORK1QuestionResult.answer",
                                              @"ORK1VerificationStep.verificationViewControllerClass",
                                              @"ORK1LoginStep.loginViewControllerClass",
                                              
                                              // Not serialized - computed property
                                              @"ORK1AnswerFormat.healthKitUnit",
                                              @"ORK1AnswerFormat.healthKitUserUnit",
                                              @"ORK1CollectionResult.firstResult",
                                              
                                              // Images: ignored so we can do the equality test and pass
                                              @"ORK1ImageChoice.normalStateImage",
                                              @"ORK1ImageChoice.selectedStateImage",
                                              @"ORK1ImageCaptureStep.templateImage",
                                              @"ORK1VideoCaptureStep.templateImage",
                                              @"ORK1ConsentSignature.signatureImage",
                                              @"ORK1ConsentSection.customImage",
                                              @"ORK1InstructionStep.image",
                                              @"ORK1InstructionStep.auxiliaryImage",
                                              @"ORK1InstructionStep.iconImage",
                                              @"ORK1ActiveStep.image",
                                              @"ORK1SpatialSpanMemoryStep.customTargetImage",
                                              @"ORK1ScaleAnswerFormat.minimumImage",
                                              @"ORK1ScaleAnswerFormat.maximumImage",
                                              @"ORK1ContinuousScaleAnswerFormat.minimumImage",
                                              @"ORK1ContinuousScaleAnswerFormat.maximumImage",
                                              @"ORK1SignatureResult.signatureImage",
                                              @"ORK1SignatureResult.signaturePath",
                                              @"ORK1PageStep.steps",
                                              @"ORK1NavigablePageStep.steps",
                                              ];
    
    // Test Each class
    for (Class aClass in classesWithSecureCoding) {
        id instance = [self instanceForClass:aClass];
        
        // Find all properties of this class
        NSMutableArray *propertyNames = [NSMutableArray array];
        unsigned int count;
        objc_property_t *props = class_copyPropertyList(aClass, &count);
        for (int i = 0; i < count; i++) {
            objc_property_t property = props[i];
            ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
            
            NSString *dottedPropertyName = [NSString stringWithFormat:@"%@.%@",NSStringFromClass(aClass),p.propertyName];
            if ([propertyExclusionList containsObject: p.propertyName] == NO &&
                [propertyExclusionList containsObject: dottedPropertyName] == NO) {
                if (p.isPrimitiveType == NO) {
                    [self applySomeValueToClassProperty:p forObject:instance index:0 forEqualityCheck:YES];
                }
                [propertyNames addObject:p.propertyName];
            }
        }
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:instance];
        XCTAssertNotNil(data);
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        unarchiver.requiresSecureCoding = YES;
        unarchiver.delegate = self;
        NSMutableSet<Class> *decodingClasses = [NSMutableSet setWithArray:classesWithSecureCoding];
        [decodingClasses addObject:[NSDate class]];
        [decodingClasses addObject:[HKQueryAnchor class]];
        
        id newInstance = [unarchiver decodeObjectOfClasses:decodingClasses forKey:NSKeyedArchiveRootObjectKey];
        
        // Set of classes we can check for equality. Would like to get rid of this once we implement
        NSSet *checkableClasses = [NSSet setWithObjects:[NSNumber class], [NSString class], [NSDictionary class], [NSURL class], nil];
        // All properties should have matching fields in dictionary (allow predefined exceptions)
        for (NSString *pName in propertyNames) {
            id newValue = [newInstance valueForKey:pName];
            id oldValue = [instance valueForKey:pName];
            
            if (newValue == nil) {
                NSString *notSerializedProperty = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(aClass), pName];
                BOOL success = [knownNotSerializedProperties containsObject:notSerializedProperty];
                if (!success) {
                    XCTAssertTrue(success, "Unexpected notSerializedProperty = %@", notSerializedProperty);
                }
            }
            for (Class c in checkableClasses) {
                if ([oldValue isKindOfClass:c]) {
                    if ([newValue isKindOfClass:[NSURL class]] || [oldValue isKindOfClass:[NSURL class]]) {
                        if (![[newValue absoluteString] isEqualToString:[oldValue absoluteString]]) {
                            XCTAssertTrue([[newValue absoluteString] isEqualToString:[oldValue absoluteString]]);
                        }
                    } else {
                        XCTAssertEqualObjects(newValue, oldValue);
                    }
                    break;
                }
            }
        }
    
        // NSData and NSDateComponents in your properties mess up the following test.
        // NSDateComponents - seems to be due to serializing and then deserializing introducing a leap month:no flag.
        if (aClass == [NSDateComponents class] || aClass == [ORK1DateQuestionResult class] || aClass == [ORK1DateAnswerFormat class] || aClass == [ORK1DataResult class]) {
            continue;
        }
        
        NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:newInstance];
        
        NSKeyedUnarchiver *unarchiver2 = [[NSKeyedUnarchiver alloc] initForReadingWithData:data2];
        unarchiver2.requiresSecureCoding = YES;
        unarchiver2.delegate = self;
        id newInstance2 = [unarchiver2 decodeObjectOfClasses:decodingClasses forKey:NSKeyedArchiveRootObjectKey];
        NSData *data3 = [NSKeyedArchiver archivedDataWithRootObject:newInstance2];
        
        if (![data isEqualToData:data2]) { // allow breakpointing
            if (![aClass isSubclassOfClass:[ORK1ConsentSection class]]
                // ORK1ConsentSection mis-matches, but it is still "equal" because
                // the net custom animation URL is a match.
                && ![aClass isSubclassOfClass:[ORK1NavigableOrderedTask class]]
                // ORK1NavigableOrderedTask contains ORK1StepModifiers which is an abstract class
                // with no encoded properties, but encoded/decoded objects are still equal.
                && ![aClass isSubclassOfClass:[ORK1KeyValueStepModifier class]]
                // ORK1KeyValueStepModifier si a subclass of ORK1StepModifier which is an abstract class
                // with no encoded properties, but encoded/decoded objects are still equal.
                ) {
                XCTAssertEqualObjects(data, data2, @"data mismatch for %@", NSStringFromClass(aClass));
            }
        }
        if (![data2 isEqualToData:data3]) { // allow breakpointing
            XCTAssertEqualObjects(data2, data3, @"data mismatch for %@", NSStringFromClass(aClass));
        }
        
        if (![newInstance isEqual:instance]) {
            XCTAssertEqualObjects(newInstance, instance, @"equality mismatch for %@", NSStringFromClass(aClass));
        }
        if (![newInstance2 isEqual:instance]) {
            XCTAssertEqualObjects(newInstance2, instance, @"equality mismatch for %@", NSStringFromClass(aClass));
        }
    }
}

- (id)instanceForClass:(Class)c {
    id result = nil;
    @try {
        if ([c instancesRespondToSelector:@selector(orktest_init)])
        {
            result = [[c alloc] orktest_init];
        } else {
            result = [[c alloc] init];
        }
    } @catch (NSException *exception) {
        XCTAssert(NO, @"Exception throw in init for %@. Exception: %@", NSStringFromClass(c), exception);
    }
    return result;
}

- (void)testEquality {
    NSArray *classesExcluded = @[
                                 [ORK1StepNavigationRule class],     // abstract base class
                                 [ORK1SkipStepNavigationRule class],     // abstract base class
                                 [ORK1StepModifier class],     // abstract base class
                                 ];
    
    
    // Each time ORK1RegistrationStep returns a new date in its answer fromat, cannot be tested.
    NSMutableArray *stringsForClassesExcluded = [NSMutableArray arrayWithObjects:NSStringFromClass([ORK1RegistrationStep class]), nil];
    for (Class c in classesExcluded) {
        [stringsForClassesExcluded addObject:NSStringFromClass(c)];
    }
    
    // Find all classes that conform to NSSecureCoding
    NSMutableArray *classesWithSecureCodingAndCopying = [NSMutableArray new];
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    numClasses = objc_getClassList(classes, numClasses);
    for (int index = 0; index < numClasses; index++) {
        Class aClass = classes[index];
        if ([stringsForClassesExcluded containsObject:NSStringFromClass(aClass)]) {
            continue;
        }
        
        if ([NSStringFromClass(aClass) hasPrefix:@"ORK1"] &&
            [aClass conformsToProtocol:@protocol(NSSecureCoding)] &&
            [aClass conformsToProtocol:@protocol(NSCopying)]) {
            
            [classesWithSecureCodingAndCopying addObject:aClass];
        }
    }
    
    // Predefined exception
    NSArray *propertyExclusionList = @[@"superclass",
                                       @"description",
                                       @"descriptionSuffix",
                                       @"debugDescription",
                                       @"hash",
                                       
                                       // ORK1Kit specific
                                       @"answer",
                                       @"firstResult",
                                       @"healthKitUnit",
                                       @"providesBackgroundAudioPrompts",
                                       @"questionType",
                                       @"requestedHealthKitTypesForReading",
                                       @"requestedHealthKitTypesForWriting",
                                       @"requestedPermissions",
                                       @"shouldReportProgress",
                                       
                                       // For a specific class
                                       @"ORK1HeightAnswerFormat.useMetricSystem",
                                       @"ORK1WeightAnswerFormat.useMetricSystem",
                                       @"ORK1NavigablePageStep.steps",
                                       @"ORK1PageStep.steps",
                                       @"ORK1Result.saveable",
                                       @"ORK1ReviewStep.isStandalone",
                                       @"ORK1Step.allowsBackNavigation",
                                       @"ORK1Step.restorable",
                                       @"ORK1Step.showsProgress",
                                       @"ORK1StepResult.isPreviousResult",
                                       @"ORK1TextAnswerFormat.validationRegex",
                                       @"ORK1VideoCaptureStep.duration",
                                       ];
    
    NSArray *hashExclusionList = @[
                                   @"ORK1DateQuestionResult.calendar",
                                   @"ORK1DateQuestionResult.timeZone",
                                   @"ORK1ToneAudiometryResult.outputVolume",
                                   @"ORK1ConsentSection.contentURL",
                                   @"ORK1ConsentSection.customAnimationURL",
                                   @"ORK1NumericAnswerFormat.minimum",
                                   @"ORK1NumericAnswerFormat.maximum",
                                   @"ORK1VideoCaptureStep.duration",
                                   @"ORK1TextAnswerFormat.validationRegularExpression",
                                   ];
    
    // Test Each class
    for (Class aClass in classesWithSecureCodingAndCopying) {
        id instance = [self instanceForClass:aClass];
        
        // Find all properties of this class
        NSMutableArray *propertyNames = [NSMutableArray array];
        unsigned int count;
        objc_property_t *props = class_copyPropertyList(aClass, &count);
        for (int i = 0; i < count; i++) {
            objc_property_t property = props[i];
            ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
            
            NSString *dottedPropertyName = [NSString stringWithFormat:@"%@.%@",NSStringFromClass(aClass),p.propertyName];
            if ([propertyExclusionList containsObject: p.propertyName] == NO &&
                [propertyExclusionList containsObject: dottedPropertyName] == NO) {
                if (p.isPrimitiveType || [instance valueForKey:p.propertyName] == nil) {
                    [self applySomeValueToClassProperty:p forObject:instance index:0 forEqualityCheck:YES];
                }
                [propertyNames addObject:p.propertyName];
            }
        }
        
        id copiedInstance = [instance copy];
        if (![copiedInstance isEqual:instance]) {
            XCTAssertEqualObjects(copiedInstance, instance);
        }
       
        for (int i = 0; i < count; i++) {
            objc_property_t property = props[i];
            ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
            
            NSString *dottedPropertyName = [NSString stringWithFormat:@"%@.%@",NSStringFromClass(aClass),p.propertyName];
            if ([propertyExclusionList containsObject: p.propertyName] == NO &&
                [propertyExclusionList containsObject: dottedPropertyName] == NO) {
                    copiedInstance = [instance copy];
                    if (instance == copiedInstance) {
                        // Totally immutable object.
                        continue;
                    }
                    if ([self applySomeValueToClassProperty:p forObject:copiedInstance index:1 forEqualityCheck:YES])
                    {
                        if ([copiedInstance isEqual:instance]) {
                            XCTAssertNotEqualObjects(copiedInstance, instance, @"%@", dottedPropertyName);
                        }
                        if (!p.isPrimitiveType &&
                            ![hashExclusionList containsObject:p.propertyName] &&
                            ![hashExclusionList containsObject:dottedPropertyName]) {
                            // Only check the hash for non-primitive type properties because often the
                            // hash into a table can be referenced using a subset of the properties used to test equality.
                            XCTAssertNotEqual([instance hash], [copiedInstance hash], @"%@", dottedPropertyName);
                        }
                        
                        [self applySomeValueToClassProperty:p forObject:copiedInstance index:0 forEqualityCheck:YES];
                        XCTAssertEqualObjects(copiedInstance, instance, @"%@", dottedPropertyName);
                        
                        if (p.isPrimitiveType == NO) {
                            [copiedInstance setValue:nil forKey:p.propertyName];
                            XCTAssertNotEqualObjects(copiedInstance, instance);
                        }
                    }
            }
        }
    }
}

- (void)testDateComponentsSerialization {
    
    // Trying to get NSDateComponents to change when you serialize / deserialize twice. But the test passes here.
    
    NSDateComponents *a = [NSDateComponents new];
    NSData *d1 = [NSKeyedArchiver archivedDataWithRootObject:a];
    NSDateComponents *b = [NSKeyedUnarchiver unarchiveObjectWithData:d1];
    NSData *d2 = [NSKeyedArchiver archivedDataWithRootObject:b];
    
    XCTAssertEqualObjects(d1, d2);
    XCTAssertEqualObjects(a, b);
}

- (void)testAddResult {
    
    // Classes for which tests are not currently implemented
    NSArray <NSString *> *excludedClassNames = @[
                                                 @"ORK1VisualConsentStepViewController",     // Requires step with scenes
                                                 ];
    
    // Classes that do not allow adding a result should throw an exception
    NSArray <NSString *> *exceptionClassNames = @[
                                                  @"ORK1PasscodeStepViewController",
                                                 ];
    
    NSDictionary <NSString *, NSString *> *mapStepClassForViewController = @{ // classes that require custom step class
                                                                             @"ORK1ActiveStepViewController" : @"ORK1ActiveStep",
                                                                             @"ORK1ConsentReviewStepViewController" : @"ORK1ConsentReviewStep",
                                                                             @"ORK1FormStepViewController" : @"ORK1FormStep",
                                                                             @"ORK1HolePegTestPlaceStepViewController" : @"ORK1HolePegTestPlaceStep",
                                                                             @"ORK1HolePegTestRemoveStepViewController" : @"ORK1HolePegTestRemoveStep",
                                                                             @"ORK1ImageCaptureStepViewController" : @"ORK1ImageCaptureStep",
                                                                             @"ORK1PSATStepViewController" : @"ORK1PSATStep",
                                                                             @"ORK1QuestionStepViewController" : @"ORK1QuestionStep",
                                                                             @"ORK1SpatialSpanMemoryStepViewController" : @"ORK1SpatialSpanMemoryStep",
                                                                             @"ORK1StroopStepViewController" : @"ORK1StroopStep",
                                                                             @"ORK1TimedWalkStepViewController" : @"ORK1TimedWalkStep",
                                                                             @"ORK1TowerOfHanoiViewController" : @"ORK1TowerOfHanoiStep",
                                                                             @"ORK1VideoCaptureStepViewController" : @"ORK1VideoCaptureStep",
                                                                             @"ORK1VideoInstructionStepViewController" : @"ORK1VideoInstructionStep",
                                                                             @"ORK1VisualConsentStepViewController" : @"ORK1VisualConsentStep",
                                                                             @"ORK1WalkingTaskStepViewController" : @"ORK1WalkingTaskStep",
                                                                             };
    
    NSDictionary <NSString *, NSDictionary *> *kvMapForStep = @{ // Steps that require modification to validate
                                                                   @"ORK1HolePegTestPlaceStep" : @{@"numberOfPegs" : @2,
                                                                                                  @"stepDuration" : @2.0f },
                                                                   @"ORK1HolePegTestRemoveStep" : @{@"numberOfPegs" : @2,
                                                                                                  @"stepDuration" : @2.0f },
                                                                   @"ORK1PSATStep" : @{@"interStimulusInterval" : @1.0,
                                                                                      @"seriesLength" : @10,
                                                                                      @"stepDuration" : @11.0f,
                                                                                      @"presentationMode" : @(ORK1PSATPresentationModeAuditory)},
                                                                   @"ORK1SpatialSpanMemoryStep" : @{@"initialSpan" : @2,
                                                                                                   @"maximumSpan" : @5,
                                                                                                   @"playSpeed" : @1.0,
                                                                                                   @"maximumTests" : @3,
                                                                                                   @"maximumConsecutiveFailures" : @1},
                                                                   @"ORK1StroopStep" : @{@"numberOfAttempts" : @15},
                                                                   @"ORK1TimedWalkStep" : @{@"distanceInMeters" : @30.0,
                                                                                           @"stepDuration" : @2.0},
                                                                   @"ORK1WalkingTaskStep" : @{@"numberOfStepsPerLeg" : @2},
    };
    
    // Find all classes that subclass from ORK1StepViewController
    NSMutableArray *stepViewControllerClassses = [NSMutableArray new];
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    numClasses = objc_getClassList(classes, numClasses);
    for (int index = 0; index < numClasses; index++) {
        Class aClass = classes[index];
        if ([excludedClassNames containsObject:NSStringFromClass(aClass)]) {
            continue;
        }
        
        if ([NSStringFromClass(aClass) hasPrefix:@"ORK1"] &&
            [aClass isSubclassOfClass:[ORK1StepViewController class]]) {
            
            [stepViewControllerClassses addObject:aClass];
        }
    }
    
    // Test Each class
    for (Class aClass in stepViewControllerClassses) {
        
        // Instantiate the step view controller
        NSString *stepClassName = mapStepClassForViewController[NSStringFromClass(aClass)];
        if (stepClassName == nil) {
            for (NSString *vcClassName in mapStepClassForViewController.allKeys) {
                if ([aClass isSubclassOfClass:NSClassFromString(vcClassName)]) {
                    stepClassName = mapStepClassForViewController[vcClassName];
                }
            }
        }
        Class stepClass = stepClassName ? NSClassFromString(stepClassName) : [ORK1Step class];
        ORK1Step *step = [self instanceForClass:stepClass];
        NSDictionary *kv = nil;
        if (stepClassName && (kv = kvMapForStep[stepClassName])) {
            [step setValuesForKeysWithDictionary:kv];
        }
        ORK1StepViewController *stepViewController = [[aClass alloc] initWithStep:step];
        
        // Create a result
        ORK1BooleanQuestionResult *result = [[ORK1BooleanQuestionResult alloc] initWithIdentifier:@"test"];
        result.booleanAnswer = @YES;
        
        // -- Call method under test
        if ([exceptionClassNames containsObject:NSStringFromClass(aClass)]) {
            XCTAssertThrows([stepViewController addResult:result]);
            continue;
        } else {
            XCTAssertNoThrow([stepViewController addResult:result]);
        }
        
        ORK1StepResult *stepResult = stepViewController.result;
        XCTAssertNotNil(stepResult, @"Step result is nil for %@", NSStringFromClass([stepViewController class]));
        XCTAssertTrue([stepResult isKindOfClass:[ORK1StepResult class]], @"Step result is not subclass of ORK1StepResult for %@", NSStringFromClass([stepViewController class]));
        if ([stepResult isKindOfClass:[ORK1StepResult class]]) {
            XCTAssertNotNil(stepResult.results, @"Step result.results is nil for %@", NSStringFromClass([stepViewController class]));
            XCTAssertTrue([stepResult.results containsObject:result], @"Step result does not contain added result for %@", NSStringFromClass([stepViewController class]));
        }
    }
}

@end
