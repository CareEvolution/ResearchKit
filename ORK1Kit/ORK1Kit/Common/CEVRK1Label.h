//
//  CEVRK1Label.h
//  ORK1Kit
//
//  Created by Eric Schramm on 8/27/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

@import UIKit;


/**
 This abstract class stores the text when set into a local property 'rawText' such that
 Markdown can be rendered on rendering passes due to changes like dynamic text
 */
@interface CEVRK1Label: UILabel

- (NSString * _Nullable)rawText;

@end
