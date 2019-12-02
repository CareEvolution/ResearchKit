/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.

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


#import "ORK1ESerialization.h"

@import ORK1Kit;
@import ORK1Kit.Private;

@import MapKit;


static NSString *ORK1EStringFromDateISO8601(NSDate *date) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [formatter stringFromDate:date];
}

static NSDate *ORK1EDateFromStringISO8601(NSString *string) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [formatter dateFromString:string];
}

static NSArray *ORK1NumericAnswerStyleTable() {
    static NSArray *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[@"decimal", @"integer"];
    });
    return table;
}

static id tableMapForward(NSInteger index, NSArray *table) {
    return table[index];
}

static NSInteger tableMapReverse(id value, NSArray *table) {
    NSUInteger idx = [table indexOfObject:value];
    if (idx == NSNotFound)
    {
        idx = 0;
    }
    return idx;
}

static NSDictionary *dictionaryFromCGPoint(CGPoint p) {
    return @{ @"x": @(p.x), @"y": @(p.y) };
}

static NSDictionary *dictionaryFromCGSize(CGSize s) {
    return @{ @"h": @(s.height), @"w": @(s.width) };
}

static NSDictionary *dictionaryFromCGRect(CGRect r) {
    return @{ @"origin": dictionaryFromCGPoint(r.origin), @"size": dictionaryFromCGSize(r.size) };
}

static NSDictionary *dictionaryFromUIEdgeInsets(UIEdgeInsets i) {
    return @{ @"top": @(i.top), @"left": @(i.left), @"bottom": @(i.bottom), @"right": @(i.right) };
}

static CGSize sizeFromDictionary(NSDictionary *dict) {
    return (CGSize){.width = ((NSNumber *)dict[@"w"]).doubleValue, .height = ((NSNumber *)dict[@"h"]).doubleValue };
}

static CGPoint pointFromDictionary(NSDictionary *dict) {
    return (CGPoint){.x = ((NSNumber *)dict[@"x"]).doubleValue, .y = ((NSNumber *)dict[@"y"]).doubleValue};
}

static CGRect rectFromDictionary(NSDictionary *dict) {
    return (CGRect){.origin = pointFromDictionary(dict[@"origin"]), .size = sizeFromDictionary(dict[@"size"])};
}

static UIEdgeInsets edgeInsetsFromDictionary(NSDictionary *dict) {
    return (UIEdgeInsets){.top = ((NSNumber *)dict[@"top"]).doubleValue, .left = ((NSNumber *)dict[@"left"]).doubleValue, .bottom = ((NSNumber *)dict[@"bottom"]).doubleValue, .right = ((NSNumber *)dict[@"right"]).doubleValue};
}

static NSDictionary *dictionaryFromCoordinate (CLLocationCoordinate2D coordinate) {
    return @{ @"latitude": @(coordinate.latitude), @"longitude": @(coordinate.longitude) };
}

static CLLocationCoordinate2D coordinateFromDictionary(NSDictionary *dict) {
    return (CLLocationCoordinate2D){.latitude = ((NSNumber *)dict[@"latitude"]).doubleValue, .longitude = ((NSNumber *)dict[@"longitude"]).doubleValue };
}

static ORK1NumericAnswerStyle ORK1NumericAnswerStyleFromString(NSString *s) {
    return tableMapReverse(s, ORK1NumericAnswerStyleTable());
}

static NSString *ORK1NumericAnswerStyleToString(ORK1NumericAnswerStyle style) {
    return tableMapForward(style, ORK1NumericAnswerStyleTable());
}

static NSDictionary *dictionaryFromCircularRegion(CLCircularRegion *region) {
    NSDictionary *dictionary = region ?
    @{
      @"coordinate": dictionaryFromCoordinate(region.center),
      @"radius": @(region.radius),
      @"identifier": region.identifier
      } :
    @{};
    return dictionary;
}

static CLCircularRegion *circularRegionFromDictionary(NSDictionary *dict) {
    CLCircularRegion *circularRegion;
    if (dict.count == 3) {
        circularRegion = [[CLCircularRegion alloc] initWithCenter:coordinateFromDictionary(dict[@"coordinate"])
                                                           radius:((NSNumber *)dict[@"radius"]).doubleValue
                                                       identifier:dict[@"identifier"]];
    }
    return circularRegion;
}

static NSArray *arrayFromRegularExpressionOptions(NSRegularExpressionOptions regularExpressionOptions) {
    NSMutableArray *optionsArray = [NSMutableArray new];
    if (regularExpressionOptions & NSRegularExpressionCaseInsensitive) {
        [optionsArray addObject:@"NSRegularExpressionCaseInsensitive"];
    }
    if (regularExpressionOptions & NSRegularExpressionAllowCommentsAndWhitespace) {
        [optionsArray addObject:@"NSRegularExpressionAllowCommentsAndWhitespace"];
    }
    if (regularExpressionOptions & NSRegularExpressionIgnoreMetacharacters) {
        [optionsArray addObject:@"NSRegularExpressionIgnoreMetacharacters"];
    }
    if (regularExpressionOptions & NSRegularExpressionDotMatchesLineSeparators) {
        [optionsArray addObject:@"NSRegularExpressionDotMatchesLineSeparators"];
    }
    if (regularExpressionOptions & NSRegularExpressionAnchorsMatchLines) {
        [optionsArray addObject:@"NSRegularExpressionAnchorsMatchLines"];
    }
    if (regularExpressionOptions & NSRegularExpressionUseUnixLineSeparators) {
        [optionsArray addObject:@"NSRegularExpressionUseUnixLineSeparators"];
    }
    if (regularExpressionOptions & NSRegularExpressionUseUnicodeWordBoundaries) {
        [optionsArray addObject:@"NSRegularExpressionUseUnicodeWordBoundaries"];
    }
    return [optionsArray copy];
}

static NSRegularExpressionOptions regularExpressionOptionsFromArray(NSArray *array) {
    NSRegularExpressionOptions regularExpressionOptions = 0;
    for (NSString *optionString in array) {
        if ([optionString isEqualToString:@"NSRegularExpressionCaseInsensitive"]) {
            regularExpressionOptions |= NSRegularExpressionCaseInsensitive;
        }
        else if ([optionString isEqualToString:@"NSRegularExpressionAllowCommentsAndWhitespace"]) {
            regularExpressionOptions |= NSRegularExpressionAllowCommentsAndWhitespace;
        }
        else if ([optionString isEqualToString:@"NSRegularExpressionIgnoreMetacharacters"]) {
            regularExpressionOptions |= NSRegularExpressionIgnoreMetacharacters;
        }
        else if ([optionString isEqualToString:@"NSRegularExpressionDotMatchesLineSeparators"]) {
            regularExpressionOptions |= NSRegularExpressionDotMatchesLineSeparators;
        }
        else if ([optionString isEqualToString:@"NSRegularExpressionAnchorsMatchLines"]) {
            regularExpressionOptions |= NSRegularExpressionAnchorsMatchLines;
        }
        else if ([optionString isEqualToString:@"NSRegularExpressionUseUnixLineSeparators"]) {
            regularExpressionOptions |= NSRegularExpressionUseUnixLineSeparators;
        }
        else if ([optionString isEqualToString:@"NSRegularExpressionUseUnicodeWordBoundaries"]) {
            regularExpressionOptions |= NSRegularExpressionUseUnicodeWordBoundaries;
        }
    }
    return regularExpressionOptions;
}

static NSDictionary *dictionaryFromRegularExpression(NSRegularExpression *regularExpression) {
    NSDictionary *dictionary = regularExpression ?
    @{
      @"pattern": regularExpression.pattern ?: @"",
      @"options": arrayFromRegularExpressionOptions(regularExpression.options)
      } :
    @{};
    return dictionary;
}

static NSRegularExpression *regularExpressionsFromDictionary(NSDictionary *dict) {
    NSRegularExpression *regularExpression;
    if (dict.count == 2) {
        regularExpression = [NSRegularExpression regularExpressionWithPattern:dict[@"pattern"]
                                                  options:regularExpressionOptionsFromArray(dict[@"options"])
                                                    error:nil];
    }
    return regularExpression;
}

static NSMutableDictionary *ORK1ESerializationEncodingTable();
static id propFromDict(NSDictionary *dict, NSString *propName);
static NSArray *classEncodingsForClass(Class c) ;
static id objectForJsonObject(id input, Class expectedClass, ORK1ESerializationJSONToObjectBlock converterBlock) ;

#define ESTRINGIFY2( x) #x
#define ESTRINGIFY(x) ESTRINGIFY2(x)

#define ENTRY(entryName, bb, props) @ESTRINGIFY(entryName) : [[ORK1ESerializableTableEntry alloc] initWithClass:[entryName class] initBlock:bb properties: props]

#define PROPERTY(x, vc, cc, ww, jb, ob) @ESTRINGIFY(x) : ([[ORK1ESerializableProperty alloc] initWithPropertyName:@ESTRINGIFY(x) valueClass:[vc class] containerClass:[cc class] writeAfterInit:ww objectToJSONBlock:jb jsonToObjectBlock:ob ])


#define DYNAMICCAST(x, c) ((c *) ([x isKindOfClass:[c class]] ? x : nil))


@interface ORK1ESerializableTableEntry : NSObject

- (instancetype)initWithClass:(Class)class
                    initBlock:(ORK1ESerializationInitBlock)initBlock
                   properties:(NSDictionary *)properties;

@property (nonatomic) Class class;
@property (nonatomic, copy) ORK1ESerializationInitBlock initBlock;
@property (nonatomic, strong) NSMutableDictionary *properties;

@end


@interface ORK1ESerializableProperty : NSObject

- (instancetype)initWithPropertyName:(NSString *)propertyName
                          valueClass:(Class)valueClass
                      containerClass:(Class)containerClass
                      writeAfterInit:(BOOL)writeAfterInit
                   objectToJSONBlock:(ORK1ESerializationObjectToJSONBlock)objectToJSON
                   jsonToObjectBlock:(ORK1ESerializationJSONToObjectBlock)jsonToObjectBlock;

@property (nonatomic, copy) NSString *propertyName;
@property (nonatomic) Class valueClass;
@property (nonatomic) Class containerClass;
@property (nonatomic) BOOL writeAfterInit;
@property (nonatomic, copy) ORK1ESerializationObjectToJSONBlock objectToJSONBlock;
@property (nonatomic, copy) ORK1ESerializationJSONToObjectBlock jsonToObjectBlock;

@end


@implementation ORK1ESerializableTableEntry

- (instancetype)initWithClass:(Class)class
                    initBlock:(ORK1ESerializationInitBlock)initBlock
                   properties:(NSDictionary *)properties {
    self = [super init];
    if (self) {
        _class = class;
        self.initBlock = initBlock;
        self.properties = [properties mutableCopy];
    }
    return self;
}

@end


@implementation ORK1ESerializableProperty

- (instancetype)initWithPropertyName:(NSString *)propertyName
                          valueClass:(Class)valueClass
                      containerClass:(Class)containerClass
                      writeAfterInit:(BOOL)writeAfterInit
                   objectToJSONBlock:(ORK1ESerializationObjectToJSONBlock)objectToJSON
                   jsonToObjectBlock:(ORK1ESerializationJSONToObjectBlock)jsonToObjectBlock {
    self = [super init];
    if (self) {
        self.propertyName = propertyName;
        self.valueClass = valueClass;
        self.containerClass = containerClass;
        self.writeAfterInit = writeAfterInit;
        self.objectToJSONBlock = objectToJSON;
        self.jsonToObjectBlock = jsonToObjectBlock;
    }
    return self;
}

@end


static NSString *_ClassKey = @"_class";

static id propFromDict(NSDictionary *dict, NSString *propName) {
    NSArray *classEncodings = classEncodingsForClass(NSClassFromString(dict[_ClassKey]));
    ORK1ESerializableProperty *propertyEntry = nil;
    for (ORK1ESerializableTableEntry *classEncoding in classEncodings) {
        
        NSDictionary *propertyEncoding = classEncoding.properties;
        propertyEntry = propertyEncoding[propName];
        if (propertyEntry != nil) {
            break;
        }
    }
    NSCAssert(propertyEntry != nil, @"Unexpected property %@ for class %@", propName, dict[_ClassKey]);
    
    Class containerClass = propertyEntry.containerClass;
    Class propertyClass = propertyEntry.valueClass;
    ORK1ESerializationJSONToObjectBlock converterBlock = propertyEntry.jsonToObjectBlock;
    
    id input = dict[propName];
    id output = nil;
    if (input != nil) {
        if ([containerClass isSubclassOfClass:[NSArray class]]) {
            NSMutableArray *outputArray = [NSMutableArray array];
            for (id value in DYNAMICCAST(input, NSArray)) {
                id convertedValue = objectForJsonObject(value, propertyClass, converterBlock);
                NSCAssert(convertedValue != nil, @"Could not convert to object of class %@", propertyClass);
                [outputArray addObject:convertedValue];
            }
            output = outputArray;
        } else if ([containerClass isSubclassOfClass:[NSDictionary class]]) {
            NSMutableDictionary *outputDictionary = [NSMutableDictionary dictionary];
            for (NSString *key in [DYNAMICCAST(input, NSDictionary) allKeys]) {
                id convertedValue = objectForJsonObject(DYNAMICCAST(input, NSDictionary)[key], propertyClass, converterBlock);
                NSCAssert(convertedValue != nil, @"Could not convert to object of class %@", propertyClass);
                outputDictionary[key] = convertedValue;
            }
            output = outputDictionary;
        } else {
            NSCAssert(containerClass == [NSObject class], @"Unexpected container class %@", containerClass);
            
            output = objectForJsonObject(input, propertyClass, converterBlock);
        }
    }
    return output;
}


#define NUMTOSTRINGBLOCK(table) ^id(id num) { return table[((NSNumber *)num).integerValue]; }
#define STRINGTONUMBLOCK(table) ^id(id string) { NSUInteger index = [table indexOfObject:string]; \
    NSCAssert(index != NSNotFound, @"Expected valid entry from table %@", table); \
    return @(index); \
}

@implementation ORK1ESerializer

static NSArray *ORK1ChoiceAnswerStyleTable() {
    static NSArray *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[@"singleChoice", @"multipleChoice"];
    });
    
    return table;
}

static NSArray *ORK1DateAnswerStyleTable() {
    static NSArray *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[@"dateTime", @"date"];
    });
    return table;
}

static NSArray *buttonIdentifierTable() {
    static NSArray *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[@"none", @"left", @"right"];
    });
    return table;
}

static NSArray *memoryGameStatusTable() {
    static NSArray *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[@"unknown", @"success", @"failure", @"timeout"];
    });
    return table;
}

static NSArray *numberFormattingStyleTable() {
    static NSArray *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[@"default", @"percent"];
    });
    return table;
}

#define GETPROP(d,x) getter(d, @ESTRINGIFY(x))
static NSMutableDictionary *ORK1ESerializationEncodingTable() {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *encondingTable = nil;
    dispatch_once(&onceToken, ^{
encondingTable =
[@{
   ENTRY(ORK1ResultSelector,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1ResultSelector *selector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:GETPROP(dict, taskIdentifier)
                                                                          stepIdentifier:GETPROP(dict, stepIdentifier)
                                                                        resultIdentifier:GETPROP(dict, resultIdentifier)];
             return selector;
         },(@{
            PROPERTY(taskIdentifier, NSString, NSObject, YES, nil, nil),
            PROPERTY(stepIdentifier, NSString, NSObject, YES, nil, nil),
            PROPERTY(resultIdentifier, NSString, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1PredicateStepNavigationRule,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1PredicateStepNavigationRule *rule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:GETPROP(dict, resultPredicates)
                                                                                          destinationStepIdentifiers:GETPROP(dict, destinationStepIdentifiers)
                                                                                               defaultStepIdentifier:GETPROP(dict, defaultStepIdentifier)
                                                                                                      validateArrays:NO];
             return rule;
         },(@{
              PROPERTY(resultPredicates, NSPredicate, NSArray, NO, nil, nil),
              PROPERTY(destinationStepIdentifiers, NSString, NSArray, NO, nil, nil),
              PROPERTY(defaultStepIdentifier, NSString, NSObject, NO, nil, nil),
              PROPERTY(additionalTaskResults, ORK1TaskResult, NSArray, YES, nil, nil)
              })),
   ENTRY(ORK1DirectStepNavigationRule,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1DirectStepNavigationRule *rule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:GETPROP(dict, destinationStepIdentifier)];
             return rule;
         },(@{
              PROPERTY(destinationStepIdentifier, NSString, NSObject, NO, nil, nil),
              })),
   ENTRY(ORK1AudioLevelNavigationRule,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1AudioLevelNavigationRule *rule = [[ORK1AudioLevelNavigationRule alloc] initWithAudioLevelStepIdentifier:GETPROP(dict, audioLevelStepIdentifier)                                                                                             destinationStepIdentifier:GETPROP(dict, destinationStepIdentifier)
                                                                                                     recordingSettings:GETPROP(dict, recordingSettings)];
             return rule;
         },(@{
              PROPERTY(audioLevelStepIdentifier, NSString, NSObject, NO, nil, nil),
              PROPERTY(destinationStepIdentifier, NSString, NSObject, NO, nil, nil),
              PROPERTY(recordingSettings, NSDictionary, NSObject, NO, nil, nil),
              })),
   ENTRY(ORK1OrderedTask,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:GETPROP(dict, identifier)
                                                                         steps:GETPROP(dict, steps)];
             return task;
         },(@{
              PROPERTY(identifier, NSString, NSObject, NO, nil, nil),
              PROPERTY(steps, ORK1Step, NSArray, NO, nil, nil)
              })),
   ENTRY(ORK1NavigableOrderedTask,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1NavigableOrderedTask *task = [[ORK1NavigableOrderedTask alloc] initWithIdentifier:GETPROP(dict, identifier)
                                                                                           steps:GETPROP(dict, steps)];
             return task;
         },(@{
              PROPERTY(stepNavigationRules, ORK1StepNavigationRule, NSMutableDictionary, YES, nil, nil),
              PROPERTY(skipStepNavigationRules, ORK1SkipStepNavigationRule, NSMutableDictionary, YES, nil, nil),
              PROPERTY(stepModifiers, ORK1StepModifier, NSMutableDictionary, YES, nil, nil),
              PROPERTY(shouldReportProgress, NSNumber, NSObject, YES, nil, nil),
              })),
   ENTRY(ORK1Step,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1Step *step = [[ORK1Step alloc] initWithIdentifier:GETPROP(dict, identifier)];
             return step;
         },
         (@{
            PROPERTY(identifier, NSString, NSObject, NO, nil, nil),
            PROPERTY(optional, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(title, NSString, NSObject, YES, nil, nil),
            PROPERTY(text, NSString, NSObject, YES, nil, nil),
            PROPERTY(shouldTintImages, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(useSurveyMode, NSNumber, NSObject, YES, nil, nil)
            })),
   ENTRY(ORK1ReviewStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1ReviewStep *reviewStep = [ORK1ReviewStep standaloneReviewStepWithIdentifier:GETPROP(dict, identifier)
                                                                                     steps:GETPROP(dict, steps)
                                                                              resultSource:GETPROP(dict, resultSource)];
             return reviewStep;
         },
         (@{
            PROPERTY(steps, ORK1Step, NSArray, NO, nil, nil),
            PROPERTY(resultSource, ORK1TaskResult, NSObject, NO, nil, nil),
            PROPERTY(excludeInstructionSteps, NSNumber, NSObject, YES, nil, nil)
            })),
   ENTRY(ORK1VisualConsentStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1VisualConsentStep alloc] initWithIdentifier:GETPROP(dict, identifier)
                                                            document:GETPROP(dict, consentDocument)];
         },
         @{
           PROPERTY(consentDocument, ORK1ConsentDocument, NSObject, NO, nil, nil)
           }),
   ENTRY(ORK1PasscodeStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1PasscodeStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
           PROPERTY(passcodeType, NSNumber, NSObject, YES, nil, nil),
           PROPERTY(passcodeFlow, NSNumber, NSObject, YES, nil, nil)
           })),
   ENTRY(ORK1WaitStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1WaitStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
           PROPERTY(indicatorType, NSNumber, NSObject, YES, nil, nil)
           })),
   ENTRY(ORK1RecorderConfiguration,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1RecorderConfiguration *recorderConfiguration = [[ORK1RecorderConfiguration alloc] initWithIdentifier:GETPROP(dict, identifier)];
             return recorderConfiguration;
         },
         (@{
            PROPERTY(identifier, NSString, NSObject, NO, nil, nil),
            })),
   ENTRY(ORK1QuestionStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1QuestionStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(answerFormat, ORK1AnswerFormat, NSObject, YES, nil, nil),
            PROPERTY(placeholder, NSString, NSObject, YES, nil, nil)
            })),
   ENTRY(ORK1InstructionStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1InstructionStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(detailText, NSString, NSObject, YES, nil, nil),
            PROPERTY(footnote, NSString, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1VideoInstructionStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1VideoInstructionStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(videoURL, NSURL, NSObject, YES,
                     ^id(id url) { return [(NSURL *)url absoluteString]; },
                     ^id(id string) { return [NSURL URLWithString:string]; }),
            PROPERTY(thumbnailTime, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1CompletionStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1CompletionStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            })),
   ENTRY(ORK1CountdownStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1CountdownStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            })),
   ENTRY(ORK1TouchAnywhereStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TouchAnywhereStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            })),
   ENTRY(ORK1HealthQuantityTypeRecorderConfiguration,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1HealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict, identifier) healthQuantityType:GETPROP(dict, quantityType) unit:GETPROP(dict, unit)];
         },
         (@{
            PROPERTY(quantityType, HKQuantityType, NSObject, NO,
                     ^id(id type) { return [(HKQuantityType *)type identifier]; },
                     ^id(id string) { return [HKQuantityType quantityTypeForIdentifier:string]; }),
            PROPERTY(unit, HKUnit, NSObject, NO,
                     ^id(id unit) { return [(HKUnit *)unit unitString]; },
                     ^id(id string) { return [HKUnit unitFromString:string]; }),
            })),
   ENTRY(ORK1ActiveStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1ActiveStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(stepDuration, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldShowDefaultTimer, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldSpeakCountDown, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldSpeakRemainingTimeAtHalfway, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldStartTimerAutomatically, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldPlaySoundOnStart, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldPlaySoundOnFinish, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldVibrateOnStart, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldVibrateOnFinish, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldUseNextAsSkipButton, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(shouldContinueOnFinish, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(spokenInstruction, NSString, NSObject, YES, nil, nil),
            PROPERTY(finishedSpokenInstruction, NSString, NSObject, YES, nil, nil),
            PROPERTY(recorderConfigurations, ORK1RecorderConfiguration, NSArray, YES, nil, nil),
            })),
   ENTRY(ORK1AudioStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1AudioStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            })),
  ENTRY(ORK1ToneAudiometryStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ToneAudiometryStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
           PROPERTY(toneDuration, NSNumber, NSObject, YES, nil, nil),
           })),
   ENTRY(ORK1ToneAudiometryPracticeStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1ToneAudiometryPracticeStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{})),
   ENTRY(ORK1HolePegTestPlaceStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1HolePegTestPlaceStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(movingDirection, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(dominantHandTested, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(numberOfPegs, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(threshold, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(rotated, NSNumber, NSObject, YES, nil, nil)
            })),
   ENTRY(ORK1HolePegTestRemoveStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1HolePegTestRemoveStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(movingDirection, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(dominantHandTested, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(numberOfPegs, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(threshold, NSNumber, NSObject, YES, nil, nil)
            })),
   ENTRY(ORK1ImageCaptureStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ImageCaptureStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
            PROPERTY(templateImageInsets, NSValue, NSObject, YES,
                ^id(id value) { return value?dictionaryFromUIEdgeInsets(((NSValue *)value).UIEdgeInsetsValue):nil; },
                ^id(id dict) { return [NSValue valueWithUIEdgeInsets:edgeInsetsFromDictionary(dict)]; }),
            PROPERTY(accessibilityHint, NSString, NSObject, YES, nil, nil),
            PROPERTY(accessibilityInstructions, NSString, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1VideoCaptureStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1VideoCaptureStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(templateImageInsets, NSValue, NSObject, YES,
                     ^id(id value) { return value?dictionaryFromUIEdgeInsets(((NSValue *)value).UIEdgeInsetsValue):nil; },
                     ^id(id dict) { return [NSValue valueWithUIEdgeInsets:edgeInsetsFromDictionary(dict)]; }),
            PROPERTY(duration, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(audioMute, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(flashMode, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(devicePosition, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(accessibilityHint, NSString, NSObject, YES, nil, nil),
            PROPERTY(accessibilityInstructions, NSString, NSObject, YES, nil, nil),
            })),
  ENTRY(ORK1SignatureStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1SignatureStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            })),
  ENTRY(ORK1SpatialSpanMemoryStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1SpatialSpanMemoryStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
          PROPERTY(initialSpan, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(minimumSpan, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(maximumSpan, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(playSpeed, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(maximumTests, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(maximumConsecutiveFailures, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(requireReversal, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(customTargetPluralName, NSString, NSObject, YES, nil, nil),
          })),
  ENTRY(ORK1WalkingTaskStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1WalkingTaskStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
          PROPERTY(numberOfStepsPerLeg, NSNumber, NSObject, YES, nil, nil),
          })),
   ENTRY(ORK1TableStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TableStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(items, NSObject, NSArray, YES, nil, nil),
            })),
   ENTRY(ORK1TimedWalkStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TimedWalkStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(distanceInMeters, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1PSATStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1PSATStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(presentationMode, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(interStimulusInterval, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(stimulusDuration, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(seriesLength, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1RangeOfMotionStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1RangeOfMotionStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(limbOption, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1ShoulderRangeOfMotionStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1ShoulderRangeOfMotionStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(limbOption, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1ReactionTimeStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1ReactionTimeStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(maximumStimulusInterval, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(minimumStimulusInterval, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(timeout, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(numberOfAttempts, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(thresholdAcceleration, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(successSound, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(timeoutSound, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(failureSound, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1StroopStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1StroopStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(numberOfAttempts, NSNumber, NSObject, YES, nil, nil)})),
   ENTRY(ORK1TappingIntervalStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TappingIntervalStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            })),
   ENTRY(ORK1TrailmakingStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TrailmakingStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(trailType, NSString, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1TowerOfHanoiStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TowerOfHanoiStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
         },
         (@{
            PROPERTY(numberOfDisks, NSNumber, NSObject, YES, nil, nil),
            })),
  ENTRY(ORK1AccelerometerRecorderConfiguration,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict, identifier) frequency:((NSNumber *)GETPROP(dict, frequency)).doubleValue];
        },
        (@{
          PROPERTY(frequency, NSNumber, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1AudioRecorderConfiguration,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1AudioRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict, identifier) recorderSettings:GETPROP(dict, recorderSettings)];
        },
        (@{
          PROPERTY(recorderSettings, NSDictionary, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1ConsentDocument,
        nil,
        (@{
          PROPERTY(title, NSString, NSObject, NO, nil, nil),
          PROPERTY(sections, ORK1ConsentSection, NSArray, NO, nil, nil),
          PROPERTY(signaturePageTitle, NSString, NSObject, NO, nil, nil),
          PROPERTY(signaturePageContent, NSString, NSObject, NO, nil, nil),
          PROPERTY(signatures, ORK1ConsentSignature, NSArray, NO, nil, nil),
          PROPERTY(htmlReviewContent, NSString, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1ConsentSharingStep,
        ^(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ConsentSharingStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
           PROPERTY(localizedLearnMoreHTMLContent, NSString, NSObject, YES, nil, nil),
           })),
  ENTRY(ORK1ConsentReviewStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ConsentReviewStep alloc] initWithIdentifier:GETPROP(dict, identifier) signature:GETPROP(dict, signature) inDocument:GETPROP(dict,consentDocument)];
        },
        (@{
          PROPERTY(consentDocument, ORK1ConsentDocument, NSObject, NO, nil, nil),
          PROPERTY(reasonForConsent, NSString, NSObject, YES, nil, nil),
          PROPERTY(signature, ORK1ConsentSignature, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1FitnessStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1FitnessStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
           })),
  ENTRY(ORK1ConsentSection,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ConsentSection alloc] initWithType:((NSNumber *)GETPROP(dict, type)).integerValue];
        },
        (@{
          PROPERTY(type, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(title, NSString, NSObject, YES, nil, nil),
          PROPERTY(formalTitle, NSString, NSObject, YES, nil, nil),
          PROPERTY(summary, NSString, NSObject, YES, nil, nil),
          PROPERTY(content, NSString, NSObject, YES, nil, nil),
          PROPERTY(htmlContent, NSString, NSObject, YES, nil, nil),
          PROPERTY(contentURL, NSURL, NSObject, YES,
                   ^id(id url) { return [(NSURL *)url absoluteString]; },
                   ^id(id string) { return [NSURL URLWithString:string]; }),
          PROPERTY(customLearnMoreButtonTitle, NSString, NSObject, YES, nil, nil),
          PROPERTY(customAnimationURL, NSURL, NSObject, YES,
                   ^id(id url) { return [(NSURL *)url absoluteString]; },
                   ^id(id string) { return [NSURL URLWithString:string]; }),
          PROPERTY(omitFromDocument, NSNumber, NSObject, YES, nil, nil),
          })),
  ENTRY(ORK1ConsentSignature,
        nil,
        (@{
          PROPERTY(identifier, NSString, NSObject, YES, nil, nil),
          PROPERTY(title, NSString, NSObject, YES, nil, nil),
          PROPERTY(givenName, NSString, NSObject, YES, nil, nil),
          PROPERTY(familyName, NSString, NSObject, YES, nil, nil),
          PROPERTY(signatureDate, NSString, NSObject, YES, nil, nil),
          PROPERTY(requiresName, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(requiresSignatureImage, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(signatureDateFormatString, NSString, NSObject, YES, nil, nil),
          })),
  ENTRY(ORK1RegistrationStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1RegistrationStep alloc] initWithIdentifier:GETPROP(dict, identifier) title:GETPROP(dict, title) text:GETPROP(dict, text) options:((NSNumber *)GETPROP(dict, options)).integerValue];
        },
        (@{
           PROPERTY(options, NSNumber, NSObject, NO, nil, nil)
           })),
   ENTRY(ORK1VerificationStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1VerificationStep alloc] initWithIdentifier:GETPROP(dict, identifier) text:GETPROP(dict, text) verificationViewControllerClass:NSClassFromString(GETPROP(dict, verificationViewControllerString))];
         },
         (@{
            PROPERTY(verificationViewControllerString, NSString, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1LoginStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1LoginStep alloc] initWithIdentifier:GETPROP(dict, identifier) title:GETPROP(dict, title) text:GETPROP(dict, text) loginViewControllerClass:NSClassFromString(GETPROP(dict, loginViewControllerString))];
         },
         (@{
            PROPERTY(loginViewControllerString, NSString, NSObject, NO, nil, nil)
            })),
  ENTRY(ORK1DeviceMotionRecorderConfiguration,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict, identifier) frequency:((NSNumber *)GETPROP(dict, frequency)).doubleValue];
        },
        (@{
          PROPERTY(frequency, NSNumber, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1FormStep,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1FormStep alloc] initWithIdentifier:GETPROP(dict, identifier)];
        },
        (@{
          PROPERTY(formItems, ORK1FormItem, NSArray, YES, nil, nil),
          PROPERTY(footnote, NSString, NSObject, YES, nil, nil),
          })),
  ENTRY(ORK1FormItem,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1FormItem alloc] initWithIdentifier:GETPROP(dict, identifier) text:GETPROP(dict, text) answerFormat:GETPROP(dict, answerFormat)];
        },
        (@{
          PROPERTY(identifier, NSString, NSObject, NO, nil, nil),
          PROPERTY(optional, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(text, NSString, NSObject, NO, nil, nil),
          PROPERTY(placeholder, NSString, NSObject, YES, nil, nil),
          PROPERTY(answerFormat, ORK1AnswerFormat, NSObject, NO, nil, nil),
          })),
   ENTRY(ORK1PageStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1PageStep *step = [[ORK1PageStep alloc] initWithIdentifier:GETPROP(dict, identifier) pageTask:GETPROP(dict, pageTask)];
             return step;
         },
         (@{
            PROPERTY(pageTask, ORK1OrderedTask, NSObject, NO, nil, nil),
            })),
   ENTRY(ORK1NavigablePageStep,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             ORK1NavigablePageStep *step = [[ORK1NavigablePageStep alloc] initWithIdentifier:GETPROP(dict, identifier) pageTask:GETPROP(dict, pageTask)];
             return step;
         },
         (@{
            PROPERTY(pageTask, ORK1OrderedTask, NSObject, NO, nil, nil),
            })),
  ENTRY(ORK1HealthKitCharacteristicTypeAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1HealthKitCharacteristicTypeAnswerFormat alloc] initWithCharacteristicType:GETPROP(dict, characteristicType)];
        },
        (@{
          PROPERTY(characteristicType, HKCharacteristicType, NSObject, NO,
                   ^id(id type) { return [(HKCharacteristicType *)type identifier]; },
                   ^id(id string) { return [HKCharacteristicType characteristicTypeForIdentifier:string]; }),
          PROPERTY(defaultDate, NSDate, NSObject, YES,
                   ^id(id date) { return [ORK1ResultDateTimeFormatter() stringFromDate:date]; },
                   ^id(id string) { return [ORK1ResultDateTimeFormatter() dateFromString:string]; }),
          PROPERTY(minimumDate, NSDate, NSObject, YES,
                   ^id(id date) { return [ORK1ResultDateTimeFormatter() stringFromDate:date]; },
                   ^id(id string) { return [ORK1ResultDateTimeFormatter() dateFromString:string]; }),
          PROPERTY(maximumDate, NSDate, NSObject, YES,
                   ^id(id date) { return [ORK1ResultDateTimeFormatter() stringFromDate:date]; },
                   ^id(id string) { return [ORK1ResultDateTimeFormatter() dateFromString:string]; }),
          PROPERTY(calendar, NSCalendar, NSObject, YES,
                   ^id(id calendar) { return [(NSCalendar *)calendar calendarIdentifier]; },
                   ^id(id string) { return [NSCalendar calendarWithIdentifier:string]; }),
          PROPERTY(shouldRequestAuthorization, NSNumber, NSObject, YES, nil, nil),
          })),
  ENTRY(ORK1HealthKitQuantityTypeAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1HealthKitQuantityTypeAnswerFormat alloc] initWithQuantityType:GETPROP(dict, quantityType) unit:GETPROP(dict, unit) style:((NSNumber *)GETPROP(dict, numericAnswerStyle)).integerValue];
        },
        (@{
          PROPERTY(unit, HKUnit, NSObject, NO,
                   ^id(id unit) { return [(HKUnit *)unit unitString]; },
                   ^id(id string) { return [HKUnit unitFromString:string]; }),
          PROPERTY(quantityType, HKQuantityType, NSObject, NO,
                   ^id(id type) { return [(HKQuantityType *)type identifier]; },
                   ^id(id string) { return [HKQuantityType quantityTypeForIdentifier:string]; }),
          PROPERTY(numericAnswerStyle, NSNumber, NSObject, NO,
                   ^id(id num) { return ORK1NumericAnswerStyleToString(((NSNumber *)num).integerValue); },
                   ^id(id string) { return @(ORK1NumericAnswerStyleFromString(string)); }),
          PROPERTY(shouldRequestAuthorization, NSNumber, NSObject, YES, nil, nil),
          })),
  ENTRY(ORK1AnswerFormat,
        nil,
        (@{
          })),
  ENTRY(ORK1ValuePickerAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ValuePickerAnswerFormat alloc] initWithTextChoices:GETPROP(dict, textChoices)];
        },
        (@{
          PROPERTY(textChoices, ORK1TextChoice, NSArray, NO, nil, nil),
          })),
   ENTRY(ORK1MultipleValuePickerAnswerFormat,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1MultipleValuePickerAnswerFormat alloc] initWithValuePickers:GETPROP(dict, valuePickers) separator:GETPROP(dict, separator)];
         },
         (@{
            PROPERTY(valuePickers, ORK1ValuePickerAnswerFormat, NSArray, NO, nil, nil),
            PROPERTY(separator, NSString, NSObject, NO, nil, nil),
            })),
  ENTRY(ORK1ImageChoiceAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ImageChoiceAnswerFormat alloc] initWithImageChoices:GETPROP(dict, imageChoices)];
        },
        (@{
          PROPERTY(imageChoices, ORK1ImageChoice, NSArray, NO, nil, nil),
          })),
  ENTRY(ORK1TextChoiceAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1TextChoiceAnswerFormat alloc] initWithStyle:((NSNumber *)GETPROP(dict, style)).integerValue textChoices:GETPROP(dict, textChoices)];
        },
        (@{
          PROPERTY(style, NSNumber, NSObject, NO, NUMTOSTRINGBLOCK(ORK1ChoiceAnswerStyleTable()), STRINGTONUMBLOCK(ORK1ChoiceAnswerStyleTable())),
          PROPERTY(textChoices, ORK1TextChoice, NSArray, NO, nil, nil),
          })),
  ENTRY(ORK1TextChoice,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1TextChoice alloc] initWithText:GETPROP(dict, text) detailText:GETPROP(dict, detailText) value:GETPROP(dict, value) exclusive:((NSNumber *)GETPROP(dict, exclusive)).boolValue];
        },
        (@{
          PROPERTY(text, NSString, NSObject, NO, nil, nil),
          PROPERTY(value, NSObject, NSObject, NO, nil, nil),
          PROPERTY(detailText, NSString, NSObject, NO, nil, nil),
          PROPERTY(exclusive, NSNumber, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1ImageChoice,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ImageChoice alloc] initWithNormalImage:nil selectedImage:nil text:GETPROP(dict, text) value:GETPROP(dict, value)];
        },
        (@{
          PROPERTY(text, NSString, NSObject, NO, nil, nil),
          PROPERTY(value, NSObject, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1TimeOfDayAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1TimeOfDayAnswerFormat alloc] initWithDefaultComponents:GETPROP(dict, defaultComponents)];
        },
        (@{
          PROPERTY(defaultComponents, NSDateComponents, NSObject, NO,
                   ^id(id components) { return ORK1TimeOfDayStringFromComponents(components);  },
                   ^id(id string) { return ORK1TimeOfDayComponentsFromString(string); })
          })),
  ENTRY(ORK1DateAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1DateAnswerFormat alloc] initWithStyle:((NSNumber *)GETPROP(dict, style)).integerValue defaultDate:GETPROP(dict, defaultDate) minimumDate:GETPROP(dict, minimumDate) maximumDate:GETPROP(dict, maximumDate) calendar:GETPROP(dict, calendar)];
        },
        (@{
          PROPERTY(style, NSNumber, NSObject, NO,
                   NUMTOSTRINGBLOCK(ORK1DateAnswerStyleTable()),
                   STRINGTONUMBLOCK(ORK1DateAnswerStyleTable())),
          PROPERTY(calendar, NSCalendar, NSObject, NO,
                   ^id(id calendar) { return [(NSCalendar *)calendar calendarIdentifier]; },
                   ^id(id string) { return [NSCalendar calendarWithIdentifier:string]; }),
          PROPERTY(minimumDate, NSDate, NSObject, NO,
                   ^id(id date) { return [ORK1ResultDateTimeFormatter() stringFromDate:date]; },
                   ^id(id string) { return [ORK1ResultDateTimeFormatter() dateFromString:string]; }),
          PROPERTY(maximumDate, NSDate, NSObject, NO,
                   ^id(id date) { return [ORK1ResultDateTimeFormatter() stringFromDate:date]; },
                   ^id(id string) { return [ORK1ResultDateTimeFormatter() dateFromString:string]; }),
          PROPERTY(defaultDate, NSDate, NSObject, NO,
                   ^id(id date) { return [ORK1ResultDateTimeFormatter() stringFromDate:date]; },
                   ^id(id string) { return [ORK1ResultDateTimeFormatter() dateFromString:string]; }),
          })),
  ENTRY(ORK1NumericAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1NumericAnswerFormat alloc] initWithStyle:((NSNumber *)GETPROP(dict, style)).integerValue unit:GETPROP(dict, unit) minimum:GETPROP(dict, minimum) maximum:GETPROP(dict, maximum)];
        },
        (@{
          PROPERTY(style, NSNumber, NSObject, NO,
                   ^id(id num) { return ORK1NumericAnswerStyleToString(((NSNumber *)num).integerValue); },
                   ^id(id string) { return @(ORK1NumericAnswerStyleFromString(string)); }),
          PROPERTY(unit, NSString, NSObject, NO, nil, nil),
          PROPERTY(minimum, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(maximum, NSNumber, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1ScaleAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ScaleAnswerFormat alloc] initWithMaximumValue:((NSNumber *)GETPROP(dict, maximum)).integerValue minimumValue:((NSNumber *)GETPROP(dict, minimum)).integerValue defaultValue:((NSNumber *)GETPROP(dict, defaultValue)).integerValue step:((NSNumber *)GETPROP(dict, step)).integerValue vertical:((NSNumber *)GETPROP(dict, vertical)).boolValue maximumValueDescription:GETPROP(dict, maximumValueDescription) minimumValueDescription:GETPROP(dict, minimumValueDescription)];
        },
        (@{
          PROPERTY(minimum, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(maximum, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(defaultValue, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(step, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(vertical, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(maximumValueDescription, NSString, NSObject, NO, nil, nil),
          PROPERTY(minimumValueDescription, NSString, NSObject, NO, nil, nil),
          PROPERTY(gradientColors, UIColor, NSArray, YES, nil, nil),
          PROPERTY(gradientLocations, NSNumber, NSArray, YES, nil, nil)
          })),
  ENTRY(ORK1ContinuousScaleAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1ContinuousScaleAnswerFormat alloc] initWithMaximumValue:((NSNumber *)GETPROP(dict, maximum)).doubleValue minimumValue:((NSNumber *)GETPROP(dict, minimum)).doubleValue defaultValue:((NSNumber *)GETPROP(dict, defaultValue)).doubleValue maximumFractionDigits:((NSNumber *)GETPROP(dict, maximumFractionDigits)).integerValue vertical:((NSNumber *)GETPROP(dict, vertical)).boolValue maximumValueDescription:GETPROP(dict, maximumValueDescription) minimumValueDescription:GETPROP(dict, minimumValueDescription)];
        },
        (@{
          PROPERTY(minimum, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(maximum, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(defaultValue, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(maximumFractionDigits, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(vertical, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(numberStyle, NSNumber, NSObject, YES,
                   ^id(id numeric) { return tableMapForward(((NSNumber *)numeric).integerValue, numberFormattingStyleTable()); },
                   ^id(id string) { return @(tableMapReverse(string, numberFormattingStyleTable())); }),
          PROPERTY(maximumValueDescription, NSString, NSObject, NO, nil, nil),
          PROPERTY(minimumValueDescription, NSString, NSObject, NO, nil, nil),
          PROPERTY(gradientColors, UIColor, NSArray, YES, nil, nil),
          PROPERTY(gradientLocations, NSNumber, NSArray, YES, nil, nil)
          })),
   ENTRY(ORK1TextScaleAnswerFormat,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TextScaleAnswerFormat alloc] initWithTextChoices:GETPROP(dict, textChoices) defaultIndex:[GETPROP(dict, defaultIndex) doubleValue] vertical:[GETPROP(dict, vertical) boolValue]];
         },
         (@{
            PROPERTY(textChoices, ORK1TextChoice, NSArray<ORK1TextChoice *>, NO, nil, nil),
            PROPERTY(defaultIndex, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(vertical, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(gradientColors, UIColor, NSArray, YES, nil, nil),
            PROPERTY(gradientLocations, NSNumber, NSArray, YES, nil, nil)
            })),
  ENTRY(ORK1TextAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1TextAnswerFormat alloc] initWithMaximumLength:((NSNumber *)GETPROP(dict, maximumLength)).integerValue];
        },
        (@{
          PROPERTY(maximumLength, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(validationRegularExpression, NSRegularExpression, NSObject, YES,
                   ^id(id value) { return dictionaryFromRegularExpression((NSRegularExpression *)value); },
                   ^id(id dict) { return regularExpressionsFromDictionary(dict); } ),
          PROPERTY(invalidMessage, NSString, NSObject, YES, nil, nil),
          PROPERTY(autocapitalizationType, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(autocorrectionType, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(spellCheckingType, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(keyboardType, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(multipleLines, NSNumber, NSObject, YES, nil, nil),
          PROPERTY(secureTextEntry, NSNumber, NSObject, YES, nil, nil)
          })),
   ENTRY(ORK1EmailAnswerFormat,
         nil,
         (@{
            })),
   ENTRY(ORK1ConfirmTextAnswerFormat,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1ConfirmTextAnswerFormat alloc] initWithOriginalItemIdentifier:GETPROP(dict, originalItemIdentifier) errorMessage:GETPROP(dict, errorMessage)];
         },
         (@{
            PROPERTY(originalItemIdentifier, NSString, NSObject, NO, nil, nil),
            PROPERTY(errorMessage, NSString, NSObject, NO, nil, nil),
            PROPERTY(maximumLength, NSNumber, NSObject, YES, nil, nil)
            })),
  ENTRY(ORK1TimeIntervalAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1TimeIntervalAnswerFormat alloc] initWithDefaultInterval:((NSNumber *)GETPROP(dict, defaultInterval)).doubleValue step:((NSNumber *)GETPROP(dict, step)).integerValue];
        },
        (@{
          PROPERTY(defaultInterval, NSNumber, NSObject, NO, nil, nil),
          PROPERTY(step, NSNumber, NSObject, NO, nil, nil),
          })),
  ENTRY(ORK1BooleanAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1BooleanAnswerFormat alloc] initWithYesString:((NSString *)GETPROP(dict, yes)) noString:((NSString *)GETPROP(dict, no))];
        },
        (@{
           PROPERTY(yes, NSString, NSObject, NO, nil, nil),
           PROPERTY(no, NSString, NSObject, NO, nil, nil)
          })),
   ENTRY(ORK1HeightAnswerFormat,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1HeightAnswerFormat alloc] initWithMeasurementSystem:((NSNumber *)GETPROP(dict, measurementSystem)).integerValue];
         },
         (@{
            PROPERTY(measurementSystem, NSNumber, NSObject, NO, nil, nil),
            })),
   ENTRY(ORK1WeightAnswerFormat,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1WeightAnswerFormat alloc] initWithMeasurementSystem:((NSNumber *)GETPROP(dict, measurementSystem)).integerValue];
         },
         (@{
            PROPERTY(measurementSystem, NSNumber, NSObject, NO, nil, nil),
            })),
  ENTRY(ORK1LocationAnswerFormat,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1LocationAnswerFormat alloc] init];
        },
        (@{
          PROPERTY(useCurrentLocation, NSNumber, NSObject, YES, nil, nil)
          })),
  ENTRY(ORK1LocationRecorderConfiguration,
        ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
            return [[ORK1LocationRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict,identifier)];
        },
        (@{
          })),
   ENTRY(ORK1PedometerRecorderConfiguration,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict,identifier)];
         },
        (@{
          })),
   ENTRY(ORK1TouchRecorderConfiguration,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TouchRecorderConfiguration alloc] initWithIdentifier:GETPROP(dict,identifier)];
         },
        (@{
          })),
  ENTRY(ORK1Result,
        nil,
        (@{
           PROPERTY(identifier, NSString, NSObject, NO, nil, nil),
           PROPERTY(startDate, NSDate, NSObject, YES,
                    ^id(id date) { return ORK1EStringFromDateISO8601(date); },
                    ^id(id string) { return ORK1EDateFromStringISO8601(string); }),
           PROPERTY(endDate, NSDate, NSObject, YES,
                    ^id(id date) { return ORK1EStringFromDateISO8601(date); },
                    ^id(id string) { return ORK1EDateFromStringISO8601(string); }),
           PROPERTY(userInfo, NSDictionary, NSObject, YES, nil, nil)
           })),
  ENTRY(ORK1TappingSample,
        nil,
        (@{
           PROPERTY(timestamp, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(duration, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(buttonIdentifier, NSNumber, NSObject, NO,
                    ^id(id numeric) { return tableMapForward(((NSNumber *)numeric).integerValue, buttonIdentifierTable()); },
                    ^id(id string) { return @(tableMapReverse(string, buttonIdentifierTable())); }),
           PROPERTY(location, NSValue, NSObject, NO,
                    ^id(id value) { return value?dictionaryFromCGPoint(((NSValue *)value).CGPointValue):nil; },
                    ^id(id dict) { return [NSValue valueWithCGPoint:pointFromDictionary(dict)]; })
           })),
  ENTRY(ORK1TappingIntervalResult,
        nil,
        (@{
           PROPERTY(samples, ORK1TappingSample, NSArray, NO, nil, nil),
           PROPERTY(stepViewSize, NSValue, NSObject, NO,
                    ^id(id value) { return value?dictionaryFromCGSize(((NSValue *)value).CGSizeValue):nil; },
                    ^id(id dict) { return [NSValue valueWithCGSize:sizeFromDictionary(dict)]; }),
           PROPERTY(buttonRect1, NSValue, NSObject, NO,
                    ^id(id value) { return value?dictionaryFromCGRect(((NSValue *)value).CGRectValue):nil; },
                    ^id(id dict) { return [NSValue valueWithCGRect:rectFromDictionary(dict)]; }),
           PROPERTY(buttonRect2, NSValue, NSObject, NO,
                    ^id(id value) { return value?dictionaryFromCGRect(((NSValue *)value).CGRectValue):nil; },
                    ^id(id dict) { return [NSValue valueWithCGRect:rectFromDictionary(dict)]; })
           })),
   ENTRY(ORK1TrailmakingTap,
         nil,
         (@{
            PROPERTY(timestamp, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(index, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(incorrect, NSNumber, NSObject, NO, nil, nil),
            })),
   ENTRY(ORK1TrailmakingResult,
         nil,
         (@{
            PROPERTY(taps, ORK1TrailmakingTap, NSArray, NO, nil, nil),
            PROPERTY(numberOfErrors, NSNumber, NSObject, NO, nil, nil)
            })),
  ENTRY(ORK1SpatialSpanMemoryGameTouchSample,
        nil,
        (@{
           PROPERTY(timestamp, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(targetIndex, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(correct, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(location, NSValue, NSObject, NO,
                    ^id(id value) { return value?dictionaryFromCGPoint(((NSValue *)value).CGPointValue):nil; },
                    ^id(id dict) { return [NSValue valueWithCGPoint:pointFromDictionary(dict)]; })
           })),
  ENTRY(ORK1SpatialSpanMemoryGameRecord,
        nil,
        (@{
           PROPERTY(seed, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(sequence, NSNumber, NSArray, NO, nil, nil),
           PROPERTY(gameSize, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(gameStatus, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(score, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(touchSamples, ORK1SpatialSpanMemoryGameTouchSample, NSArray, NO,
                    ^id(id numeric) { return tableMapForward(((NSNumber *)numeric).integerValue, memoryGameStatusTable()); },
                    ^id(id string) { return @(tableMapReverse(string, memoryGameStatusTable())); }),
           PROPERTY(targetRects, NSValue, NSArray, NO,
                    ^id(id value) { return value?dictionaryFromCGRect(((NSValue *)value).CGRectValue):nil; },
                    ^id(id dict) { return [NSValue valueWithCGRect:rectFromDictionary(dict)]; })
           })),
  ENTRY(ORK1SpatialSpanMemoryResult,
        nil,
        (@{
           PROPERTY(score, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(numberOfGames, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(numberOfFailures, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(gameRecords, ORK1SpatialSpanMemoryGameRecord, NSArray, NO, nil, nil)
           })),
  ENTRY(ORK1FileResult,
        nil,
        (@{
           PROPERTY(contentType, NSString, NSObject, NO, nil, nil),
           PROPERTY(fileURL, NSURL, NSObject, NO,
                    ^id(id url) { return [url absoluteString]; },
                    ^id(id string) { return [NSURL URLWithString:string]; })
           })),
  ENTRY(ORK1ToneAudiometrySample,
        nil,
        (@{
           PROPERTY(frequency, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(channel, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(amplitude, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(channelSelected, NSNumber, NSObject, NO, nil, nil)
           })),
  ENTRY(ORK1ToneAudiometryResult,
        nil,
        (@{
           PROPERTY(outputVolume, NSNumber, NSObject, NO, nil, nil),
           PROPERTY(samples, ORK1ToneAudiometrySample, NSArray, NO, nil, nil),
           })),
   ENTRY(ORK1ReactionTimeResult,
         nil,
         (@{
            PROPERTY(timestamp, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(fileResult, ORK1Result, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1StroopResult,
         nil,
         (@{
            PROPERTY(startTime, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(endTime, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(color, NSString, NSObject, NO, nil, nil),
            PROPERTY(text, NSString, NSObject, NO, nil, nil),
            PROPERTY(colorSelected, NSString, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1TimedWalkResult,
         nil,
         (@{
            PROPERTY(distanceInMeters, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(timeLimit, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(duration, NSNumber, NSObject, NO, nil, nil),
           })),
   ENTRY(ORK1PSATSample,
         nil,
         (@{
            PROPERTY(correct, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(digit, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(answer, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(time, NSNumber, NSObject, NO, nil, nil),
            })),
   ENTRY(ORK1PSATResult,
         nil,
         (@{
            PROPERTY(presentationMode, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(interStimulusInterval, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(stimulusDuration, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(length, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalCorrect, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalDyad, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalTime, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(initialDigit, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(samples, ORK1PSATSample, NSArray, NO, nil, nil),
            })),
   ENTRY(ORK1RangeOfMotionResult,
         nil,
         (@{
            PROPERTY(flexed, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(extended, NSNumber, NSObject, NO, nil, nil),
            })),
   ENTRY(ORK1TowerOfHanoiResult,
         nil,
         (@{
            PROPERTY(puzzleWasSolved, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(moves, ORK1TowerOfHanoiMove, NSArray, YES, nil, nil),
            })),
   ENTRY(ORK1TowerOfHanoiMove,
         nil,
         (@{
            PROPERTY(timestamp, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(donorTowerIndex, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(recipientTowerIndex, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1HolePegTestSample,
         nil,
         (@{
            PROPERTY(time, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(distance, NSNumber, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1HolePegTestResult,
         nil,
         (@{
            PROPERTY(movingDirection, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(dominantHandTested, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(numberOfPegs, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(threshold, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(rotated, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalSuccesses, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalFailures, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalTime, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(totalDistance, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(samples, ORK1HolePegTestSample, NSArray, NO, nil, nil),
            })),
   ENTRY(ORK1PasscodeResult,
         nil,
         (@{
            PROPERTY(passcodeSaved, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(touchIdEnabled, NSNumber, NSObject, YES, nil, nil)
            })),
    ENTRY(ORK1QuestionResult,
         nil,
         (@{
            PROPERTY(questionType, NSNumber, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1DataResult,
         nil,
         (@{
            PROPERTY(contentType, NSString, NSObject, YES, nil, nil),
            PROPERTY(filename, NSString, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1ScaleQuestionResult,
         nil,
         (@{
            PROPERTY(scaleAnswer, NSNumber, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1ChoiceQuestionResult,
         nil,
         (@{
            PROPERTY(choiceAnswers, NSObject, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1MultipleComponentQuestionResult,
         nil,
         (@{
            PROPERTY(componentsAnswer, NSObject, NSObject, NO, nil, nil),
            PROPERTY(separator, NSString, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1BooleanQuestionResult,
         nil,
         (@{
            PROPERTY(booleanAnswer, NSNumber, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1TextQuestionResult,
         nil,
         (@{
            PROPERTY(textAnswer, NSString, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1NumericQuestionResult,
         nil,
         (@{
            PROPERTY(numericAnswer, NSNumber, NSObject, NO, nil, nil),
            PROPERTY(unit, NSString, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1TimeOfDayQuestionResult,
         nil,
         (@{
            PROPERTY(dateComponentsAnswer, NSDateComponents, NSObject, NO,
                     ^id(id dateComponents) { return ORK1TimeOfDayStringFromComponents(dateComponents); },
                     ^id(id string) { return ORK1TimeOfDayComponentsFromString(string); })
            })),
   ENTRY(ORK1TimeIntervalQuestionResult,
         nil,
         (@{
            PROPERTY(intervalAnswer, NSNumber, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1DateQuestionResult,
         nil,
         (@{
            PROPERTY(dateAnswer, NSDate, NSObject, NO,
                     ^id(id date) { return ORK1EStringFromDateISO8601(date); },
                     ^id(id string) { return ORK1EDateFromStringISO8601(string); }),
            PROPERTY(calendar, NSCalendar, NSObject, NO,
                     ^id(id calendar) { return [(NSCalendar *)calendar calendarIdentifier]; },
                     ^id(id string) { return [NSCalendar calendarWithIdentifier:string]; }),
            PROPERTY(timeZone, NSTimeZone, NSObject, NO,
                     ^id(id timezone) { return @([timezone secondsFromGMT]); },
                     ^id(id number) { return [NSTimeZone timeZoneForSecondsFromGMT:((NSNumber *)number).doubleValue]; })
            })),
   ENTRY(ORK1Location,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             CLLocationCoordinate2D coordinate = coordinateFromDictionary(dict[@ESTRINGIFY(coordinate)]);
             return [[ORK1Location alloc] initWithCoordinate:coordinate
                                                     region:GETPROP(dict, region)
                                                  userInput:GETPROP(dict, userInput)
                                          addressDictionary:GETPROP(dict, addressDictionary)];
         },
         (@{
            PROPERTY(userInput, NSString, NSObject, NO, nil, nil),
            PROPERTY(addressDictionary, NSString, NSDictionary, NO, nil, nil),
            PROPERTY(coordinate, NSValue, NSObject, NO,
                     ^id(id value) { return value ? dictionaryFromCoordinate(((NSValue *)value).MKCoordinateValue) : nil; },
                     ^id(id dict) { return [NSValue valueWithMKCoordinate:coordinateFromDictionary(dict)]; }),
            PROPERTY(region, CLCircularRegion, NSObject, NO,
                     ^id(id value) { return dictionaryFromCircularRegion((CLCircularRegion *)value); },
                     ^id(id dict) { return circularRegionFromDictionary(dict); }),
            })),
   ENTRY(ORK1LocationQuestionResult,
         nil,
         (@{
            PROPERTY(locationAnswer, ORK1Location, NSObject, NO, nil, nil)
            })),
   ENTRY(ORK1ConsentSignatureResult,
         nil,
         (@{
            PROPERTY(signature, ORK1ConsentSignature, NSObject, YES, nil, nil),
            PROPERTY(consented, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1SignatureResult,
         nil,
         (@{
            })),
   ENTRY(ORK1CollectionResult,
         nil,
         (@{
            PROPERTY(results, ORK1Result, NSArray, YES, nil, nil)
            })),
   ENTRY(ORK1TaskResult,
         ^id(NSDictionary *dict, ORK1ESerializationPropertyGetter getter) {
             return [[ORK1TaskResult alloc] initWithTaskIdentifier:GETPROP(dict, identifier) taskRunUUID:GETPROP(dict, taskRunUUID) outputDirectory:GETPROP(dict, outputDirectory)];
         },
         (@{
            PROPERTY(taskRunUUID, NSUUID, NSObject, NO,
                     ^id(id uuid) { return [uuid UUIDString]; },
                     ^id(id string) { return [[NSUUID alloc] initWithUUIDString:string]; }),
            PROPERTY(outputDirectory, NSURL, NSObject, NO,
                     ^id(id url) { return [url absoluteString]; },
                     ^id(id string) { return [NSURL URLWithString:string]; })
            })),
   ENTRY(ORK1StepResult,
         nil,
         (@{
            PROPERTY(enabledAssistiveTechnology, NSString, NSObject, YES, nil, nil),
            PROPERTY(isPreviousResult, NSNumber, NSObject, YES, nil, nil),
            })),
   ENTRY(ORK1PageResult,
         nil,
         (@{
            })),
   ENTRY(ORK1VideoInstructionStepResult,
         nil,
         (@{
            PROPERTY(playbackStoppedTime, NSNumber, NSObject, YES, nil, nil),
            PROPERTY(playbackCompleted, NSNumber, NSObject, YES, nil, nil),
            })),
   
   } mutableCopy];
    });
    return encondingTable;
}
#undef GETPROP

static NSArray *classEncodingsForClass(Class c) {
    NSDictionary *encodingTable = ORK1ESerializationEncodingTable();
    
    NSMutableArray *classEncodings = [NSMutableArray array];
    Class sc = c;
    while (sc != nil) {
        NSString *className = NSStringFromClass(sc);
        ORK1ESerializableTableEntry *classEncoding = encodingTable[className];
        if (classEncoding) {
            [classEncodings addObject:classEncoding];
        }
        sc = [sc superclass];
    }
    return classEncodings;
}

static id objectForJsonObject(id input, Class expectedClass, ORK1ESerializationJSONToObjectBlock converterBlock) {
    id output = nil;
    if (converterBlock != nil) {
        input = converterBlock(input);
    }
    
    if (expectedClass != nil && [input isKindOfClass:expectedClass]) {
        // Input is already of the expected class, do nothing
        output = input;
    } else if ([input isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)input;
        NSString *className = input[_ClassKey];
        if (expectedClass != nil) {
            NSCAssert([NSClassFromString(className) isSubclassOfClass:expectedClass], @"Expected subclass of %@ but got %@", expectedClass, className);
        }
        NSArray *classEncodings = classEncodingsForClass(NSClassFromString(className));
        NSCAssert([classEncodings count] > 0, @"Expected serializable class but got %@", className);
        
        ORK1ESerializableTableEntry *leafClassEncoding = classEncodings.firstObject;
        ORK1ESerializationInitBlock initBlock = leafClassEncoding.initBlock;
        BOOL writeAllProperties = YES;
        if (initBlock != nil) {
            output = initBlock(dict,
                               ^id(NSDictionary *dict, NSString *param) {
                                   return propFromDict(dict, param); });
            writeAllProperties = NO;
        } else {
            output = [[NSClassFromString(className) alloc] init];
        }
        
        for (NSString *key in [dict allKeys]) {
            if ([key isEqualToString:_ClassKey]) {
                continue;
            }
            
            BOOL haveSetProp = NO;
            for (ORK1ESerializableTableEntry *encoding in classEncodings) {
                NSDictionary *propertyTable = encoding.properties;
                ORK1ESerializableProperty *propertyEntry = propertyTable[key];
                if (propertyEntry != nil) {
                    // Only write the property if it has not already been set during init
                    if (writeAllProperties || propertyEntry.writeAfterInit) {
                        [output setValue:propFromDict(dict,key) forKey:key];
                    }
                    haveSetProp = YES;
                    break;
                }
            }
            NSCAssert(haveSetProp, @"Unexpected property on %@: %@", className, key);
        }
        
    } else {
        NSCAssert(0, @"Unexpected input of class %@ for %@", [input class], expectedClass);
    }
    return output;
}

static BOOL isValid(id object) {
    return [NSJSONSerialization isValidJSONObject:object] || [object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNull class]];
}

static id jsonObjectForObject(id object) {
    if (object == nil) {
        // Leaf: nil
        return nil;
    }
    
    id jsonOutput = nil;
    Class c = [object class];
    
    NSArray *classEncodings = classEncodingsForClass(c);
    
    if ([classEncodings count]) {
        NSMutableDictionary *encodedDict = [NSMutableDictionary dictionary];
        encodedDict[_ClassKey] = NSStringFromClass(c);
        
        for (ORK1ESerializableTableEntry *encoding in classEncodings) {
            NSDictionary *propertyTable = encoding.properties;
            for (NSString *propertyName in [propertyTable allKeys]) {
                ORK1ESerializableProperty *propertyEntry = propertyTable[propertyName];
                ORK1ESerializationObjectToJSONBlock converter = propertyEntry.objectToJSONBlock;
                Class containerClass = propertyEntry.containerClass;
                id valueForKey = [object valueForKey:propertyName];
                if (valueForKey != nil) {
                    if ([containerClass isSubclassOfClass:[NSArray class]]) {
                        NSMutableArray *a = [NSMutableArray array];
                        for (id valueItem in valueForKey) {
                            id outputItem;
                            if (converter != nil) {
                                outputItem = converter(valueItem);
                                NSCAssert(isValid(valueItem), @"Expected valid JSON object");
                            } else {
                                // Recurse for each property
                                outputItem = jsonObjectForObject(valueItem);
                            }
                            [a addObject:outputItem];
                        }
                        valueForKey = a;
                    } else {
                        if (converter != nil) {
                            valueForKey = converter(valueForKey);
                            NSCAssert((valueForKey == nil) || isValid(valueForKey), @"Expected valid JSON object");
                        } else {
                            // Recurse for each property
                            valueForKey = jsonObjectForObject(valueForKey);
                        }
                    }
                }
                
                if (valueForKey != nil) {
                    encodedDict[propertyName] = valueForKey;
                }
            }
        }
        
        jsonOutput = encodedDict;
    } else if ([c isSubclassOfClass:[NSArray class]]) {
        NSArray *inputArray = (NSArray *)object;
        NSMutableArray *encodedArray = [NSMutableArray arrayWithCapacity:[inputArray count]];
        for (id input in inputArray) {
            // Recurse for each array element
            [encodedArray addObject:jsonObjectForObject(input)];
        }
        jsonOutput = encodedArray;
    } else if ([c isSubclassOfClass:[NSDictionary class]]) {
        NSDictionary *inputDict = (NSDictionary *)object;
        NSMutableDictionary *encodedDictionary = [NSMutableDictionary dictionaryWithCapacity:[inputDict count]];
        for (NSString *key in [inputDict allKeys] ) {
            // Recurse for each dictionary value
            encodedDictionary[key] = jsonObjectForObject(inputDict[key]);
        }
        jsonOutput = encodedDictionary;
    } else if (![c isSubclassOfClass:[NSPredicate class]]) {  // Ignore NSPredicate which cannot be easily serialized for now
        NSCAssert(isValid(object), @"Expected valid JSON object");
        
        // Leaf: native JSON object
        jsonOutput = object;
    }
    
    return jsonOutput;
}

+ (NSDictionary *)JSONObjectForObject:(id)object error:(NSError **)error {
    id json = jsonObjectForObject(object);
    return json;
}

+ (id)objectFromJSONObject:(NSDictionary *)object error:(NSError **)error {
    return objectForJsonObject(object, nil, nil);
}

+ (NSData *)JSONDataForObject:(id)object error:(NSError **)error {
    id json = jsonObjectForObject(object);
    return [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)0 error:error];
}

+ (id)objectFromJSONData:(NSData *)data error:(NSError **)error {
    id json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:error];
    id ret = nil;
    if (json != nil) {
        ret = objectForJsonObject(json, nil, nil);
    }
    return ret;
}

+ (NSArray *)serializableClasses {
    NSMutableArray *a = [NSMutableArray array];
    NSDictionary *table = ORK1ESerializationEncodingTable();
    for (NSString *key in [table allKeys]) {
        [a addObject:NSClassFromString(key)];
    }
    return a;
}

@end


@implementation ORK1ESerializer(Registration)

+ (void)registerSerializableClass:(Class)serializableClass
                        initBlock:(ORK1ESerializationInitBlock)initBlock {
    NSMutableDictionary *encodingTable = ORK1ESerializationEncodingTable();
    
    ORK1ESerializableTableEntry *entry = encodingTable[NSStringFromClass(serializableClass)];
    if (entry) {
        entry.class = serializableClass;
        entry.initBlock = initBlock;
    } else {
        entry = [[ORK1ESerializableTableEntry alloc] initWithClass:serializableClass initBlock:initBlock properties:@{}];
        encodingTable[NSStringFromClass(serializableClass)] = entry;
    }
}

+ (void)registerSerializableClassPropertyName:(NSString *)propertyName
                                     forClass:(Class)serializableClass
                                   valueClass:(Class)valueClass
                               containerClass:(Class)containerClass
                               writeAfterInit:(BOOL)writeAfterInit
                            objectToJSONBlock:(ORK1ESerializationObjectToJSONBlock)objectToJSON
                            jsonToObjectBlock:(ORK1ESerializationJSONToObjectBlock)jsonToObjectBlock {
    NSMutableDictionary *encodingTable = ORK1ESerializationEncodingTable();
    
    ORK1ESerializableTableEntry *entry = encodingTable[NSStringFromClass(serializableClass)];
    if (!entry) {
        entry = [[ORK1ESerializableTableEntry alloc] initWithClass:serializableClass initBlock:nil properties:@{}];
        encodingTable[NSStringFromClass(serializableClass)] = entry;
    }
    
    ORK1ESerializableProperty *property = entry.properties[propertyName];
    if (property == nil) {
        property = [[ORK1ESerializableProperty alloc] initWithPropertyName:propertyName
                                                               valueClass:valueClass
                                                           containerClass:containerClass
                                                           writeAfterInit:writeAfterInit
                                                        objectToJSONBlock:objectToJSON
                                                        jsonToObjectBlock:jsonToObjectBlock];
        entry.properties[propertyName] = property;
    } else {
        property.propertyName = propertyName;
        property.valueClass = valueClass;
        property.containerClass = containerClass;
        property.writeAfterInit = writeAfterInit;
        property.objectToJSONBlock = objectToJSON;
        property.jsonToObjectBlock = jsonToObjectBlock;
    }
}

@end
