//
//  ORKMedicationPicker.h
//  ResearchKit
//
//  Created by Eric Schramm on 5/30/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

@import UIKit;

@class ORKMedicationPicker;
@class ORKMedication;

@protocol ORKMedicationPickerDelegate <NSObject>

- (void)medicationPicker:(ORKMedicationPicker *)medicationPicker selectedMedication:(ORKMedication *)medication;

@end

@interface ORKMedicationPicker : UITableViewController

@property (weak, nonatomic) id <ORKMedicationPickerDelegate> delegate;

@end
