//
//  CEVRKNavigationBarProgressView.h
//  ResearchKit
//
//  Created by Eric Schramm on 8/10/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

/*
 Due to order of drawing operations, there is an animated appearance or disappearance of
 the UIProgressView when it is hidden or unhidden. To avoid it always hiding or unhiding based
 on initial state, we capture the hiding/unhiding and store that in a singleton so when the
 ORKNavigationContainerView draws initially, it will use the last used state which is more likely
 to match what is happening on the current step so when the progress is updated after the step
 has loaded, it should only animate if this is a true change in state.
 */

@interface CEVRKNavigationBarProgressView : UIProgressView

@end
