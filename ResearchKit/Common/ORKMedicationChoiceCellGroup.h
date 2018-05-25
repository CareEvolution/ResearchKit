//
//  ORKMedicationChoiceCellGroup.h
//  ResearchKit
//
//  Created by Eric Schramm on 5/24/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class ORKChoiceViewCell;
@class ORKMedicationAnswerFormat;
@class ORKMedication;

@interface ORKMedicationChoiceCellGroup : NSObject


- (instancetype)initWithMedicationAnswerFormat:(ORKMedicationAnswerFormat *)answerFormat
                                   medications:(NSArray<ORKMedication *> *)medications
                            beginningIndexPath:(NSIndexPath *)indexPath
                           immediateNavigation:(BOOL)immediateNavigation;

@property (nonatomic, strong) NSArray<ORKMedication *> *medications;

- (nullable ORKChoiceViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath withReuseIdentifier:(nullable NSString *)identifier;

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath;

- (void)didSelectCellAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)size;

@end

NS_ASSUME_NONNULL_END
