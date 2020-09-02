//
//  CEVRKTextView.h
//  ORK1Kit
//
//  Created by Eric Schramm on 8/26/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

@import UIKit;


/**
 This is a class that is being swapped in for ORK1SubheadlineLabel which allows for
 tappable links via data detectors - specifically for links specified in Markdown.
 */
@interface CEVRK1TextView : UITextView

@property (nonatomic, copy, nullable) NSString *textValue;
@property (nonatomic, copy, nullable) NSString *detailTextValue;

/**
 Use textValue / detailTextValue instead.
 */
- (void)setText:(nullable NSString *)text NS_UNAVAILABLE;
- (void)init_CEVRK1TextView;

@end
