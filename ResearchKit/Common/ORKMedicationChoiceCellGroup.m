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
    return (self.medications.count + 1);
}

- (void)setMedications:(NSArray<ORKMedication *> *)medications {
    _medications = medications;
    
    //[self setSelectedIndexes:[_helper selectedIndexesForAnswer:medications]];
}

- (ORKChoiceViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath withReuseIdentifier:(NSString *)identifier {
    if ([self containsIndexPath:indexPath] == NO) {
        return nil;
    }
    
    return [self cellAtIndex:indexPath.row-_beginningIndexPath.row withReuseIdentifier:identifier];
}

- (ORKChoiceViewCell *)cellAtIndex:(NSUInteger)index withReuseIdentifier:(NSString *)identifier {
    ORKChoiceViewCell *cell = _cells[@(index)];
    
    if (cell == nil) {
        cell = [[ORKChoiceViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.immediateNavigation = _immediateNavigation;
        _cells[@(index)] = cell;
    }
    //[self setSelectedIndexes:[_helper selectedIndexesForAnswer:_medications]];
    
    return cell;
}

- (void)configureCell:(ORKChoiceViewCell *)cell atIndex:(NSUInteger)index {  //called from ORKQuestionStepViewController
    //consider deletions?
    NSLog(@"Configuring cell at index: %@", @(index));
    if (index == 0) {
        cell.shortLabel.text = @"[Select a Medication]";
        cell.shortLabel.textColor = [UIColor grayColor];
        cell.longLabel.text = nil;
    } else {
        ORKMedication *medication = self.medications[index - 1];
        cell.shortLabel.text = medication.medicationDescription;
        cell.shortLabel.textColor = [UIColor blueColor];
        cell.longLabel.text = medication.detailedDescription;
    }
}

- (void)didSelectCellAtIndex:(NSUInteger)index {
    ORKChoiceViewCell *touchedCell = [self cellAtIndex:index withReuseIdentifier:nil];
    
    if (_singleChoice) {
        touchedCell.selectedItem = YES;
        for (ORKChoiceViewCell *cell in _cells.allValues) {
            if (cell != touchedCell) {
                cell.selectedItem = NO;
            }
        }
    } else {
        if ([touchedCell.shortLabel.text isEqualToString:@"[Select a Medication]"]) {
            //spawn to add medication
            if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:presentMedicationPicker:)]) {
                [self.delegate medicationChoiceCellGroup:self presentMedicationPicker:_medicationPicker];
            }
        } else {
            //remove medication
            NSMutableArray *updatedMedications = [_medications mutableCopy];
            [updatedMedications removeObjectAtIndex:index - 1];
            [self setMedications:[updatedMedications copy]];
            if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:didUpdateMedications:)]) {
                [self.delegate medicationChoiceCellGroup:self didUpdateMedications:_medications];
            }
        }
        /*
        touchedCell.selectedItem = !touchedCell.selectedItem;
        if (touchedCell.selectedItem) {
             ORKTextChoice *touchedChoice = [_helper textChoiceAtIndex:index];
            for (NSNumber *num in _cells.allKeys) {
                ORKChoiceViewCell *cell = _cells[num];
                ORKTextChoice *choice = [_helper textChoiceAtIndex:num.unsignedIntegerValue];
                if (cell != touchedCell && (touchedChoice.exclusive || (cell.selectedItem && choice.exclusive))) {
                    cell.selectedItem = NO;
                }
            }
        }*/
    }
    
    //_medications = [_helper answerForSelectedIndexes:[self selectedIndexes]];
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

- (void)setSelectedIndexes:(NSArray *)indexes {
    for (NSUInteger index = 0; index < self.size; index++ ) {
        BOOL selected = [indexes containsObject:@(index)];
        
        if (selected) {
            // In case the cell has not been created, need to create cell
            ORKChoiceViewCell *cell = [self cellAtIndex:index withReuseIdentifier:nil];
            cell.selectedItem = YES;
        } else {
            // It is ok to not create the cell at here
            ORKChoiceViewCell *cell = _cells[@(index)];
            cell.selectedItem = NO;
        }
    }
}

- (NSArray *)selectedIndexes {
    NSMutableArray *indexes = [NSMutableArray new];
    
    for (NSUInteger index = 0; index < self.size; index++ ) {
        ORKChoiceViewCell *cell = _cells[@(index)];
        if (cell.selectedItem) {
            [indexes addObject:@(index)];
        }
    }
    
    return [indexes copy];
}

- (void)medicationPicker:(ORKMedicationPicker *)medicationPicker selectedMedication:(ORKMedication *)medication {
    if (medication) {
        [self setMedications:[_medications arrayByAddingObject:medication]];
    }
    
    if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:didUpdateMedications:)]) {
        [self.delegate medicationChoiceCellGroup:self didUpdateMedications:_medications];
    }
    
    if ([self.delegate respondsToSelector:@selector(medicationChoiceCellGroup:dismissMedicationPicker:)]) {
        [self.delegate medicationChoiceCellGroup:self dismissMedicationPicker:medicationPicker];
    }
}

- (ORKMedicationCellText *)medicationCellTextForRow:(NSInteger)row {
    if (row == 0) {
        return [[ORKMedicationCellText alloc] initWithShortText:@"[Select a Medication]" longText:nil];
    }
    ORKMedication *medication = self.medications[row - 1];
    return [[ORKMedicationCellText alloc] initWithShortText:medication.medicationDescription longText:medication.detailedDescription];
}

@end
