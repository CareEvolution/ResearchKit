//
//  ORKMedicationPicker.h
//  ResearchKit
//
//  Created by Eric Schramm on 5/30/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

@import UIKit;

@protocol ORKMedicationPicker;
@class ORKMedication;

NS_ASSUME_NONNULL_BEGIN

@protocol ORKMedicationPickerDelegate <NSObject>

- (void)medicationPicker:(id <ORKMedicationPicker>)medicationPicker didSelectMedication:(ORKMedication *)medication;
- (void)medicationPickerDidCancel:(id <ORKMedicationPicker>)medicationPicker;

@end


@protocol ORKMedicationPicker <NSObject>

@property (nonatomic, weak) id <ORKMedicationPickerDelegate> delegate;

- (void)summonMedPickerFromPresentingViewController:(UIViewController *)presentingViewController;
- (void)dismissMedPickerFromPresentingViewController:(UIViewController *)presentingViewController;

@end

NS_ASSUME_NONNULL_END
