//
//  ORKMedicationChoiceCellGroup.h
//  ResearchKit
//
//  Created by Eric Schramm on 5/24/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

@import Foundation;
#import "ORKTextChoiceCellGroup.h"


@class ORKMedicationChoiceCellGroup, UIViewController, ORKMedication;

@protocol ORKMedicationChoiceCellGroupDelegate <NSObject>

- (void)medicationChoiceCellGroup:(ORKMedicationChoiceCellGroup *)medicationChoiceCellGroup presentMedicationPicker:(UIViewController *)medicationPicker;
- (void)medicationChoiceCellGroup:(ORKMedicationChoiceCellGroup *)medicationChoiceCellGroup dismissMedicationPicker:(UIViewController *)medicationPicker;
- (void)medicationChoiceCellGroup:(ORKMedicationChoiceCellGroup *)medicationChoiceCellGroup didUpdateMedications:(NSArray <ORKMedication *> *)medications;

@end


@interface ORKMedicationCellText: NSObject

@property (nonatomic, copy, readonly, nonnull) NSString *shortText;
@property (nonatomic, copy, readonly, nullable) NSString *longText;

- (instancetype) initWithShortText:(NSString * __nonnull)shortText longText:(NSString * __nullable)longText;

@end


NS_ASSUME_NONNULL_BEGIN


@class ORKMedicationChoiceViewCell;
@class ORKMedicationAnswerFormat;
@class ORKMedication;
@class ORKMedicationPicker;

@interface ORKMedicationChoiceCellGroup : ORKTextChoiceCellGroup


- (instancetype)initWithMedicationAnswerFormat:(ORKMedicationAnswerFormat *)answerFormat
                                   medications:(NSArray<ORKMedication *> *)medications
                            beginningIndexPath:(NSIndexPath *)indexPath
                           immediateNavigation:(BOOL)immediateNavigation
                              medicationPicker:(ORKMedicationPicker *)medicationPicker;

@property (nonatomic, strong) NSArray<ORKMedication *> *medications;
@property (weak, nonatomic) id <ORKMedicationChoiceCellGroupDelegate> delegate;

- (ORKMedicationCellText *)medicationCellTextForRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
