//
//  ORKMedicationChoiceCellGroup.m
//  ResearchKit
//
//  Created by Eric Schramm on 5/24/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

#import "ORKMedicationChoiceCellGroup.h"

#import "ORKSelectionTitleLabel.h"
#import "ORKSelectionSubTitleLabel.h"

#import "ORKMedicationChoiceViewCell.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKChoiceAnswerFormatHelper.h"

#import "ORKResult.h"

#import "ORKMedicationPicker.h"


@implementation ORKMedicationCellText {
    NSString *_shortText;
    NSString *_longText;
}

- (instancetype)initWithShortText:(NSString *)shortText longText:(NSString *)longText {
    self = [super init];
    if (self) {
        _shortText = shortText;
        _longText = longText;
    }
    return self;
}

@end

@interface ORKMedicationChoiceCellGroup () <ORKMedicationPickerDelegate>
@end

@implementation ORKMedicationChoiceCellGroup {
    BOOL _singleChoice;
    BOOL _immediateNavigation;
    NSIndexPath *_beginningIndexPath;
    ORKMedicationPicker *_medicationPicker;
    
    NSMutableDictionary *_cells;
}


- (instancetype)initWithMedicationAnswerFormat:(ORKMedicationAnswerFormat *)answerFormat
                                   medications:(NSArray<ORKMedication *> *)medications
                            beginningIndexPath:(NSIndexPath *)indexPath
                           immediateNavigation:(BOOL)immediateNavigation
                              medicationPicker:(nonnull ORKMedicationPicker *)medicationPicker {
    self = [super init];
    if (self) {
        _beginningIndexPath = indexPath;
        _singleChoice = answerFormat.singleChoice;
        _immediateNavigation = immediateNavigation;
        _cells = [NSMutableDictionary new];
        _medicationPicker = medicationPicker;
        [self setMedications:medications];
        _medicationPicker.delegate = self;
    }
    return self;
}

- (NSUInteger)size {
    if (_singleChoice) {
        return 1;
    } else {
        return (self.medications.count + 1);
    }
}

- (void)setMedications:(NSArray<ORKMedication *> *)medications {
    _medications = medications;
}

- (ORKMedicationChoiceViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath withReuseIdentifier:(NSString *)identifier {
    if ([self containsIndexPath:indexPath] == NO) {
        return nil;
    }
    
    return [self cellAtIndex:indexPath.row-_beginningIndexPath.row withReuseIdentifier:identifier];
}

- (ORKMedicationChoiceViewCell *)cellAtIndex:(NSUInteger)index withReuseIdentifier:(NSString *)identifier {
    ORKMedicationChoiceViewCell *cell = _cells[@(index)];
    
    if (cell == nil) {
        cell = [[ORKMedicationChoiceViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.immediateNavigation = _immediateNavigation;
        _cells[@(index)] = cell;
    }
    
    return cell;
}

- (void)configureCell:(ORKMedicationChoiceViewCell *)cell atIndex:(NSUInteger)index {  //called from ORKQuestionStepViewController
    if (_singleChoice) {
        if (self.medications.count == 0) {
            [self configureAsSelectMedicationCell:cell];
        } else {
            [self configureCell:cell forMedication:self.medications[0]];
        }
    } else {
        if (index == 0) {
            [self configureAsSelectMedicationCell:cell];
        } else {
            [self configureCell:cell forMedication:self.medications[index - 1]];
        }
    }
}

- (void)configureAsSelectMedicationCell:(ORKMedicationChoiceViewCell *)cell {
    cell.shortLabel.text = @"[Add a Medication]";
    cell.shortLabel.textColor = [UIColor grayColor];
    cell.longLabel.text = nil;
}

- (void)configureCell:(ORKMedicationChoiceViewCell *)cell forMedication:(ORKMedication *)medication {
    cell.shortLabel.text = medication.medicationDescription;
    cell.shortLabel.textColor = [UIColor blueColor];
    cell.longLabel.text = medication.detailedDescription;
}

- (void)didSelectCellAtIndex:(NSUInteger)index {
    ORKChoiceViewCell *touchedCell = [self cellAtIndex:index withReuseIdentifier:nil];
    if ([touchedCell.shortLabel.text isEqualToString:@"[Add a Medication]"]) {
        //spawn to add medication
        if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:presentMedicationPicker:)]) {
            [self.delegate medicationChoiceCellGroup:self presentMedicationPicker:_medicationPicker];
        }
    } else {
        //remove medication
        NSMutableArray *updatedMedications = [_medications mutableCopy];
        [updatedMedications removeObjectAtIndex:[self correctedIndexForRow:index]];
        [self setMedications:[updatedMedications copy]];
        if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:didUpdateMedications:)]) {
            [self.delegate medicationChoiceCellGroup:self didUpdateMedications:_medications];
        }
    }
}

- (void)didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    if ([self containsIndexPath:indexPath]== NO) {
        return;
    }
    [self didSelectCellAtIndex:indexPath.row - _beginningIndexPath.row];
}

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath {
    NSUInteger count = (self.medications.count + 1);
    
    return (indexPath.section == _beginningIndexPath.section) &&
    (indexPath.row >= _beginningIndexPath.row) &&
    (indexPath.row < (_beginningIndexPath.row + count));
}

- (void)medicationPicker:(ORKMedicationPicker *)medicationPicker selectedMedication:(ORKMedication *)medication {
    if (medication) {
        if (_singleChoice) {
            [self setMedications:@[medication]];
        } else {
            [self setMedications:[_medications arrayByAddingObject:medication]];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:didUpdateMedications:)]) {
        [self.delegate medicationChoiceCellGroup:self didUpdateMedications:_medications];
    }
    
    if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:dismissMedicationPicker:)]) {
        [self.delegate medicationChoiceCellGroup:self dismissMedicationPicker:medicationPicker];
    }
}

- (ORKMedicationCellText *)medicationCellTextForRow:(NSInteger)row {
    if ((_singleChoice && self.medications.count == 0) || (!_singleChoice && row == 0)) {
        return [[ORKMedicationCellText alloc] initWithShortText:@"[Add a Medication]" longText:nil];
    }
    ORKMedication *medication = self.medications[[self correctedIndexForRow:row]];
    return [[ORKMedicationCellText alloc] initWithShortText:medication.medicationDescription longText:medication.detailedDescription];
}

- (NSInteger)correctedIndexForRow:(NSInteger)row {
    return _singleChoice ? 0 : row - 1;
}

@end
