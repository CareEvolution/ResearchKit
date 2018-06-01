//
//  ORKMedicationChoiceViewCell.m
//  ResearchKit
//
//  Created by Eric Schramm on 5/31/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

#import "ORKMedicationChoiceViewCell.h"

@implementation ORKMedicationChoiceViewCell

//overrriding to prevent coloring based on selection
- (void)updateSelectedItem {
    if (self.immediateNavigation == NO) {
        self.accessoryView.hidden = YES;
    }
}

@end
