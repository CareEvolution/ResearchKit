//
//  ORK1SkinSwiftTests.swift
//  ORK1KitTests
//
//  Created by Eric Schramm on 9/7/22.
//  Copyright © 2022 researchkit.org. All rights reserved.
//

import XCTest
final class ORK1SkinSwiftTests: XCTestCase {
    
    /*
     
     These tests merely assert that ORK1SkinSwift vending of metrics matches that of the original Objective-C class
     for the sizes that are shared between the original Obj-C implementation and the new Swift class.

     */
    
    let originalSizes = Set(["320x568", "375x667", "375x812", "414x736", "375x812", "768x1024", "1024x1366"])
    
    let originalMetrics = Set(["CaptionBaselineToFitnessTimerTop","CaptionBaselineToInstructionBaseline","CaptionBaselineToTappingLabelTop","ChoiceCellFirstBaselineOffsetFromTop","ChoiceCellLabelLastBaselineToLabelFirstBaseline","ChoiceCellLastBaselineToBottom","ContinueButtonHeightCompact","ContinueButtonHeightRegular","ContinueButtonTopMargin","ContinueButtonTopMarginForIntroStep","ContinueButtonWidth","FontSizeFootnote","FontSizeHeadline","FontSizeSubheadline","FontSizeSurveyHeadline","HeadlineSideMargin","IconImageViewToCaptionBaseline","IllustrationHeight","IllustrationToCaptionBaseline","InstructionBaselineToLearnMoreBaseline","InstructionImageHeight","LearnMoreBaselineToStepViewTop","LearnMoreBaselineToStepViewTopWithNoLearnMore","LearnMoreButtonSideMargin","LocationQuestionMapHeight","MaxFontSizeHeadline","MaxFontSizeSurveyHeadline","MinimumStepHeaderHeightForMemoryGame","MinimumStepHeaderHeightForTowerOfHanoiPuzzle","PSATKeyboardViewHeight","PSATKeyboardViewWidth","SignatureViewHeight","TableCellDefaultHeight","TextFieldCellHeight","ToolbarHeight","TopToCaptionBaseline","TopToIconImageViewTop","TopToIllustration","VerificationTextBaselineToResendButtonBaseline","VerticalScaleHeight"])
        .map({ ORK1ScreenMetricSwift.metric(for: $0)! })
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetMetricForWindow() throws {
        for size in ORK1SkinSwift.allSizeTypes {
            guard originalSizes.contains("\(Int(size.size.width))x\(Int(size.size.height))") else { continue }
            let window = UIWindow(frame: .init(origin: .zero, size: size.size))
            for metric in ORK1ScreenMetricSwift.allCases {
                XCTAssertEqual(ORK1SkinSwift.getMetric(metric: metric, for: window), ORIGINAL_FOR_TESTING_ORK1GetMetricForWindow(metric.objCMetric, window), "size: \(size.size), metric: \(metric.title) - \(metric.objCMetric)")
            }
        }
    }
    
    func testStandardHorizontalMarginForView() throws {
        for size in ORK1SkinSwift.allSizeTypes {
            guard originalSizes.contains("\(Int(size.size.width))x\(Int(size.size.height))") else { continue }
            let window = UIWindow(frame: .init(origin: .zero, size: size.size))
            let view = UIView()
            window.addSubview(view)
            XCTAssertEqual(ORK1SkinSwift.standardHorizontalMargin(for: view), ORIGINAL_FOR_TESTING_ORK1StandardHorizontalMarginForView(view), "size: \(size.size)")
        }
    }
    
    func testStandardLeftMarginForTableViewCell() throws {
        for size in ORK1SkinSwift.allSizeTypes {
            guard originalSizes.contains("\(Int(size.size.width))x\(Int(size.size.height))") else { continue }
            let window = UIWindow(frame: .init(origin: .zero, size: size.size))
            let cell = UITableViewCell(style: .default, reuseIdentifier: "TEST")
            window.addSubview(cell)
            XCTAssertEqual(ORK1SkinSwift.standardLeftMarginForTableViewCell(for: cell), ORIGINAL_FOR_TESTING_ORK1StandardLeftMarginForTableViewCell(cell), "size: \(size.size)")
        }
    }
    
    func testStandardFullScreenLayoutMarginsForView() throws {
        for size in ORK1SkinSwift.allSizeTypes {
            guard originalSizes.contains("\(Int(size.size.width))x\(Int(size.size.height))") else { continue }
            let window = UIWindow(frame: .init(origin: .zero, size: size.size))
            let view = UIView()
            window.addSubview(view)
            XCTAssertEqual(ORK1SkinSwift.standardFullScreenLayoutMargins(for: view), ORIGINAL_FOR_TESTING_ORK1StandardFullScreenLayoutMarginsForView(view), "size: \(size.size)")
        }
    }
    
    func testScrollIndicatorInsetsForScrollView() throws {
        for size in ORK1SkinSwift.allSizeTypes {
            guard originalSizes.contains("\(Int(size.size.width))x\(Int(size.size.height))") else { continue }
            let window = UIWindow(frame: .init(origin: .zero, size: size.size))
            let view = UIView()
            window.addSubview(view)
            XCTAssertEqual(ORK1SkinSwift.scrollIndicatorInsetsForScrollview(for: view), ORIGINAL_FOR_TESTING_ORK1ScrollIndicatorInsetsForScrollView(view), "size: \(size.size)")
        }
    }
    
    func testWidthForSignatureView() throws {
        for size in ORK1SkinSwift.allSizeTypes {
            guard originalSizes.contains("\(Int(size.size.width))x\(Int(size.size.height))") else { continue }
            let window = UIWindow(frame: .init(origin: .zero, size: size.size))
            XCTAssertEqual(ORK1SkinSwift.widthForSignatureView(window: window), ORIGINAL_FOR_TESTING_ORK1WidthForSignatureView(window), "size: \(size.size)")
        }
    }
}
