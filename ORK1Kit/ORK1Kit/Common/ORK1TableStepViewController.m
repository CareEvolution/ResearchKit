
/*
 Copyright (c) 2016, Sage Bionetworks
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORK1TableStepViewController.h"
#import "ORK1TableStepViewController_Internal.h"

#import "ORK1NavigationContainerView_Internal.h"
#import "ORK1StepHeaderView_Internal.h"
#import "ORK1TableContainerView.h"

#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController_Internal.h"

#import "ORK1TableStep.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"


ORK1DefineStringKey(ORK1BasicCellReuseIdentifier);


@implementation ORK1TableStepViewController 

- (id <ORK1TableStepSource>)tableStep {
    if ([self.step conformsToProtocol:@protocol(ORK1TableStepSource)]) {
        return (id <ORK1TableStepSource>)self.step;
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.taskViewController setRegisteredScrollView:_tableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

// Override to monitor button title change
- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    self.continueSkipView.continueButtonItem = continueButtonItem;
    [self updateButtonStates];
}

- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    [super setLearnMoreButtonItem:learnMoreButtonItem];
    self.headerView.learnMoreButtonItem = self.learnMoreButtonItem;
    [_tableContainer setNeedsLayout];
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    self.continueSkipView.skipButtonItem = skipButtonItem;
    [self updateButtonStates];
}
    
- (UITableViewStyle)tableViewStyle {
    return [self numSections] > 1 ? UITableViewStyleGrouped : UITableViewStylePlain;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [_tableContainer removeFromSuperview];
    _tableContainer = nil;
    
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    _headerView = nil;
    _continueSkipView = nil;
    
    if (self.step) {
        _tableContainer = [[ORK1TableContainerView alloc] initWithFrame:self.view.bounds style:self.tableViewStyle];
        if ([self conformsToProtocol:@protocol(ORK1TableContainerViewDelegate)]) {
            _tableContainer.delegate = (id)self;
        }
        [self.view addSubview:_tableContainer];
        _tableContainer.tapOffView = self.view;
        
        _tableView = _tableContainer.tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = ORK1GetMetricForWindow(ORK1ScreenMetricTableCellDefaultHeight, self.view.window);
        _tableView.estimatedSectionHeaderHeight = [self numSections] > 1 ? 30.0 : 0.0;
        _tableView.allowsSelection = NO;
        
        _headerView = _tableContainer.stepHeaderView;
        _headerView.captionLabel.text = [[self step] title];
        _headerView.instructionTextView.textValue = [[self step] text];
        _headerView.learnMoreButtonItem = self.learnMoreButtonItem;
        
        _continueSkipView = _tableContainer.continueSkipContainerView;
        _continueSkipView.skipButtonItem = self.skipButtonItem;
        _continueSkipView.continueEnabled = [self continueButtonEnabled];
        _continueSkipView.continueButtonItem = self.continueButtonItem;
        _continueSkipView.optional = self.step.optional;
        
        // Register the cells for the table view
        if ([self.tableStep respondsToSelector:@selector(registerCellsForTableView:)]) {
            [self.tableStep registerCellsForTableView:_tableView];
        } else {
            [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ORK1BasicCellReuseIdentifier];
        }
    }
}

- (BOOL)continueButtonEnabled {
    return YES;
}

- (void)updateButtonStates {
    self.continueSkipView.continueEnabled = [self continueButtonEnabled];
}

#pragma mark UITableViewDataSource
    
- (NSInteger)numSections {
    if ([self.tableStep respondsToSelector:@selector(numberOfSections)]) {
        return [self.tableStep numberOfSections] ?: 1;
    } else {
        return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self numSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableStep numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ORK1ThrowInvalidArgumentExceptionIfNil(self.tableStep);
    
    NSString *reuseIdentifier;
    if ([self.tableStep respondsToSelector:@selector(reuseIdentifierForRowAtIndexPath:)]) {
        reuseIdentifier = [self.tableStep reuseIdentifierForRowAtIndexPath:indexPath];
    } else {
        reuseIdentifier = ORK1BasicCellReuseIdentifier;
    }
    ORK1ThrowInvalidArgumentExceptionIfNil(reuseIdentifier);
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self.tableStep configureCell:cell indexPath:indexPath tableView:tableView];
    
    return cell;
}

@end

