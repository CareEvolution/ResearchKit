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

#import "ORKChoiceViewCell.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKHelpers_Internal.h"

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
    id <ORKMedicationPicker> _medicationPicker;
}


- (instancetype)initWithMedicationAnswerFormat:(ORKMedicationAnswerFormat *)answerFormat
                                   medications:(NSArray<ORKMedication *> *)medications
                            beginningIndexPath:(NSIndexPath *)indexPath
                              medicationPicker:(nonnull id <ORKMedicationPicker>)medicationPicker {
    self = [super init];
    if (self) {
        
        // TODO: setting superclass values which are protected, consider alternate method of sharing ivars like https://stackoverflow.com/questions/31249906/access-ivar-from-subclass-in-objective-c
        [self setValue:indexPath forKey:@"_beginningIndexPath"];
        [self setValue:[NSMutableDictionary new] forKey:@"_cells"];
        
        _singleChoice = answerFormat.singleChoice;
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

- (void)configureCell:(ORKChoiceViewCell *)cell atIndex:(NSUInteger)index {  // called from ORKQuestionStepViewController
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

- (void)configureAsSelectMedicationCell:(ORKChoiceViewCell *)cell {
    cell.selectable = NO;
    cell.shortLabel.text = [NSString stringWithFormat:@"[%@]", ORKLocalizedString(@"PLACEHOLDER_ADD_MEDICATION", nil)];
    cell.shortLabel.textColor = [UIColor grayColor];
    cell.longLabel.text = nil;
}

- (void)configureCell:(ORKChoiceViewCell *)cell forMedication:(ORKMedication *)medication {
    cell.selectable = NO;
    cell.shortLabel.text = medication.medicationDescription;
    cell.shortLabel.textColor = [UIColor blueColor];
    cell.longLabel.text = medication.detailedDescription;
}

- (void)didSelectCellAtIndex:(NSUInteger)index {
    UIViewController *presentingViewController = nil;
    if ([self.delegate respondsToSelector:@selector(presentingViewControllerForMedicationChoiceCellGroup:)]) {
        presentingViewController = [self.delegate presentingViewControllerForMedicationChoiceCellGroup:self];
    } else {
        return;
    }
    ORKChoiceViewCell *touchedCell = [self cellAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] withReuseIdentifier:nil];
    if ([touchedCell.shortLabel.text isEqualToString:[NSString stringWithFormat:@"[%@]", ORKLocalizedString(@"PLACEHOLDER_ADD_MEDICATION", nil)]]) {
        //spawn to add medication
        if ([_medicationPicker respondsToSelector:@selector(summonMedPickerFromPresentingViewController:)]) {
            [_medicationPicker summonMedPickerFromPresentingViewController:presentingViewController];
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

- (void)medicationPicker:(id <ORKMedicationPicker>)medicationPicker didSelectMedication:(ORKMedication *)medication {
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
    
    [self dismissMedicationPicker];
}

- (void)medicationPickerDidCancel:(nonnull id<ORKMedicationPicker>)medicationPicker {
    [self dismissMedicationPicker];
}

- (void)dismissMedicationPicker {
    if ([_medicationPicker respondsToSelector:@selector(dismissMedPickerFromPresentingViewController:)] &&
        [self.delegate respondsToSelector:@selector(presentingViewControllerForMedicationChoiceCellGroup:)]) {
        [_medicationPicker dismissMedPickerFromPresentingViewController:[self.delegate presentingViewControllerForMedicationChoiceCellGroup:self]];
    }
}

- (ORKMedicationCellText *)medicationCellTextForRow:(NSInteger)row {
    if ((_singleChoice && self.medications.count == 0) || (!_singleChoice && row == 0)) {
        return [[ORKMedicationCellText alloc] initWithShortText:[NSString stringWithFormat:@"[%@]", ORKLocalizedString(@"PLACEHOLDER_ADD_MEDICATION", nil)] longText:nil];
    }
    ORKMedication *medication = self.medications[[self correctedIndexForRow:row]];
    return [[ORKMedicationCellText alloc] initWithShortText:medication.medicationDescription longText:medication.detailedDescription];
}

- (NSInteger)correctedIndexForRow:(NSInteger)row {
    return _singleChoice ? 0 : row - 1;
}

@end
