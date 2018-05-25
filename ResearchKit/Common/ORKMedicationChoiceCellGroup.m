//
//  ORKMedicationCHoiceCellGroup.m
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

@implementation ORKMedicationChoiceCellGroup {
    ORKChoiceAnswerFormatHelper *_helper;
    BOOL _singleChoice;
    BOOL _immediateNavigation;
    NSIndexPath *_beginningIndexPath;
    
    NSMutableDictionary *_cells;
}


- (instancetype)initWithMedicationAnswerFormat:(ORKMedicationAnswerFormat *)answerFormat
                                   medications:(NSArray<ORKMedication *> *)medications
                            beginningIndexPath:(NSIndexPath *)indexPath
                           immediateNavigation:(BOOL)immediateNavigation {
    self = [super init];
    if (self) {
        _beginningIndexPath = indexPath;
        _helper = [[ORKChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        _singleChoice = answerFormat.singleChoice;
        _immediateNavigation = immediateNavigation;
        _cells = [NSMutableDictionary new];
        [self setMedications:medications];
    }
    return self;
}

- (NSUInteger)size {
    return [_helper choiceCount];
}

- (void)setMedications:(NSArray<ORKMedication *> *)medications {
    _medications = medications;
    
    [self setSelectedIndexes:[_helper selectedIndexesForAnswer:medications]];
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
        if (index == 0) {
            cell.shortLabel.text = @"[Select a Medication]";
            cell.longLabel.text = @"detail text someday";
        } else {
            ORKMedication *medication = self.medications[index - 1];
            cell.shortLabel.text = medication.medicationDescription;
            cell.longLabel.text = @"detail text someday";
        }
        
        _cells[@(index)] = cell;
        
        [self setSelectedIndexes:[_helper selectedIndexesForAnswer:_medications]];
    }
    
    return cell;
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
        }
    }
    
    _medications = [_helper answerForSelectedIndexes:[self selectedIndexes]];
}

- (void)didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    if ([self containsIndexPath:indexPath]== NO) {
        return;
    }
    [self didSelectCellAtIndex:indexPath.row - _beginningIndexPath.row];
}

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath {
    NSUInteger count = _helper.choiceCount;
    
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

@end
