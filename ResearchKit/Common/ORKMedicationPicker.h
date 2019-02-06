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

NS_ASSUME_NONNULL_BEGIN

@protocol ORKMedicationPickerDelegate <NSObject>

- (void)medicationPicker:(ORKMedicationPicker *)medicationPicker didSelectMedication:(ORKMedication *)medication;

@end

@interface ORKMedicationPicker : UITableViewController

@property (weak, nonatomic) id <ORKMedicationPickerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
