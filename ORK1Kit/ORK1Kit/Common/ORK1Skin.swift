//
//  ORKSkin.swift
//  ORK1Kit
//
//  Created by Eric Schramm on 8/31/22.
//  Copyright © 2022 researchkit.org. All rights reserved.
//

import UIKit


struct ORK1SizeType {
    let size: CGSize
    let isiPad: Bool
    let metrics : [ORK1ScreenMetricSwift : CGFloat]
    func metric(for metric: ORK1ScreenMetricSwift) -> CGFloat {
        return metrics[metric] ?? 9999
    }
    
    /*
         320x568 : iPhone: 5/S/C, SE1; iPod Touch: 5-7
         375x667 : iPhone: 6/S, 7-8, SE2
         414x736 : iPhone: 8+
         375x812 : iPhone: X/S, 11 Pro, 12-13 mini
         390x844 : iPhone: 12-14/Pro
         476x847 : iPhone: 6/S/7 Plus
         393x852 : iPhone: 14 Pro
         414x896 : iPhone: XR, XS Max, 11/Pro Max
         428x926 : iPhone: 12-13 Pro Max, 14 Plus
         430x932 : iPhone: 14 Pro Max
        768x1024 : iPad: 1-6, mini 1-5, Air 1-2, Pro 9.7"
        810x1080 : iPad: 7-9
        834x1112 : iPad: Pro 10.5", Air 3
        744x1133 : iPad: mini 6
        820x1180 : iPad: Air 4
        834x1194 : iPad: Pro 11"
       1024x1366 : iPad: Pro 12.9"
    */
}

enum ORK1MetricType {
    case vertical
    case horizontal
    case fontSize
}

@objc public enum ORK1ScreenMetricSwift: Int, CaseIterable {
    case captionBaselineToFitnessTimerTop
    case captionBaselineToInstructionBaseline
    case captionBaselineToTappingLabelTop
    case choiceCellFirstBaselineOffsetFromTop
    case choiceCellLabelLastBaselineToLabelFirstBaseline
    case choiceCellLastBaselineToBottom
    case continueButtonHeightCompact
    case continueButtonHeightRegular
    case continueButtonTopMargin
    case continueButtonTopMarginForIntroStep
    case continueButtonWidth
    case fontSizeFootnote
    case fontSizeHeadline
    case fontSizeSubheadline
    case fontSizeSurveyHeadline
    case headlineSideMargin
    case iconImageViewToCaptionBaseline
    case illustrationHeight
    case illustrationToCaptionBaseline
    case instructionBaselineToLearnMoreBaseline
    case instructionImageHeight
    case learnMoreBaselineToStepViewTop
    case learnMoreBaselineToStepViewTopWithNoLearnMore
    case learnMoreButtonSideMargin
    case locationQuestionMapHeight
    case maxFontSizeHeadline
    case maxFontSizeSurveyHeadline
    case minimumStepHeaderHeightForMemoryGame
    case minimumStepHeaderHeightForTowerOfHanoiPuzzle
    case PSATKeyboardViewHeight
    case PSATKeyboardViewWidth
    case signatureViewHeight
    case tableCellDefaultHeight
    case textFieldCellHeight
    case toolbarHeight
    case topToCaptionBaseline
    case topToIconImageViewTop
    case topToIllustration
    case verificationTextBaselineToResendButtonBaseline
    case verticalScaleHeight
    
    static func metric(for abbreviatedString: String) -> ORK1ScreenMetricSwift? {
        switch abbreviatedString {
        case "CaptionBaselineToFitnessTimerTop":
            return .captionBaselineToFitnessTimerTop
        case "CaptionBaselineToInstructionBaseline":
            return .captionBaselineToInstructionBaseline
        case "CaptionBaselineToTappingLabelTop":
            return .captionBaselineToTappingLabelTop
        case "ChoiceCellFirstBaselineOffsetFromTop":
            return .choiceCellFirstBaselineOffsetFromTop
        case "ChoiceCellLabelLastBaselineToLabelFirstBaseline":
            return .choiceCellLabelLastBaselineToLabelFirstBaseline
        case "ChoiceCellLastBaselineToBottom":
            return .choiceCellLastBaselineToBottom
        case "ContinueButtonHeightCompact":
            return .continueButtonHeightCompact
        case "ContinueButtonHeightRegular":
            return .continueButtonHeightRegular
        case "ContinueButtonTopMargin":
            return .continueButtonTopMargin
        case "ContinueButtonTopMarginForIntroStep":
            return .continueButtonTopMarginForIntroStep
        case "ContinueButtonWidth":
            return .continueButtonWidth
        case "FontSizeFootnote":
            return .fontSizeFootnote
        case "FontSizeHeadline":
            return .fontSizeHeadline
        case "FontSizeSubheadline":
            return .fontSizeSubheadline
        case "FontSizeSurveyHeadline":
            return .fontSizeSurveyHeadline
        case "HeadlineSideMargin":
            return .headlineSideMargin
        case "IconImageViewToCaptionBaseline":
            return .iconImageViewToCaptionBaseline
        case "IllustrationHeight":
            return .illustrationHeight
        case "IllustrationToCaptionBaseline":
            return .illustrationToCaptionBaseline
        case "InstructionBaselineToLearnMoreBaseline":
            return .instructionBaselineToLearnMoreBaseline
        case "InstructionImageHeight":
            return .instructionImageHeight
        case "LearnMoreBaselineToStepViewTop":
            return .learnMoreBaselineToStepViewTop
        case "LearnMoreBaselineToStepViewTopWithNoLearnMore":
            return .learnMoreBaselineToStepViewTopWithNoLearnMore
        case "LearnMoreButtonSideMargin":
            return .learnMoreButtonSideMargin
        case "LocationQuestionMapHeight":
            return .locationQuestionMapHeight
        case "MaxFontSizeHeadline":
            return .maxFontSizeHeadline
        case "MaxFontSizeSurveyHeadline":
            return .maxFontSizeSurveyHeadline
        case "MinimumStepHeaderHeightForMemoryGame":
            return .minimumStepHeaderHeightForMemoryGame
        case "MinimumStepHeaderHeightForTowerOfHanoiPuzzle":
            return .minimumStepHeaderHeightForTowerOfHanoiPuzzle
        case "PSATKeyboardViewHeight":
            return .PSATKeyboardViewHeight
        case "PSATKeyboardViewWidth":
            return .PSATKeyboardViewWidth
        case "SignatureViewHeight":
            return .signatureViewHeight
        case "TableCellDefaultHeight":
            return .tableCellDefaultHeight
        case "TextFieldCellHeight":
            return .textFieldCellHeight
        case "ToolbarHeight":
            return .toolbarHeight
        case "TopToCaptionBaseline":
            return .topToCaptionBaseline
        case "TopToIconImageViewTop":
            return .topToIconImageViewTop
        case "TopToIllustration":
            return .topToIllustration
        case "VerificationTextBaselineToResendButtonBaseline":
            return .verificationTextBaselineToResendButtonBaseline
        case "VerticalScaleHeight":
            return .verticalScaleHeight
        default:
            return nil
        }
    }
    
    static func metric(for objCMetric: ORK1ScreenMetric) -> ORK1ScreenMetricSwift? {
        switch objCMetric {
        case .topToCaptionBaseline:
            return .topToCaptionBaseline
        case .fontSizeHeadline:
            return .fontSizeHeadline
        case .maxFontSizeHeadline:
            return .maxFontSizeHeadline
        case .fontSizeSurveyHeadline:
            return .fontSizeSurveyHeadline
        case .maxFontSizeSurveyHeadline:
            return .maxFontSizeSurveyHeadline
        case .fontSizeSubheadline:
            return .fontSizeSubheadline
        case .fontSizeFootnote:
            return .fontSizeFootnote
        case .captionBaselineToFitnessTimerTop:
            return .captionBaselineToFitnessTimerTop
        case .captionBaselineToTappingLabelTop:
            return .captionBaselineToTappingLabelTop
        case .captionBaselineToInstructionBaseline:
            return .captionBaselineToInstructionBaseline
        case .instructionBaselineToLearnMoreBaseline:
            return .instructionBaselineToLearnMoreBaseline
        case .learnMoreBaselineToStepViewTop:
            return .learnMoreBaselineToStepViewTop
        case .learnMoreBaselineToStepViewTopWithNoLearnMore:
            return .learnMoreBaselineToStepViewTopWithNoLearnMore
        case .continueButtonTopMargin:
            return .continueButtonTopMargin
        case .continueButtonTopMarginForIntroStep:
            return .continueButtonTopMarginForIntroStep
        case .topToIllustration:
            return .topToIllustration
        case .illustrationToCaptionBaseline:
            return .illustrationToCaptionBaseline
        case .illustrationHeight:
            return .illustrationHeight
        case .instructionImageHeight:
            return .instructionImageHeight
        case .continueButtonHeightRegular:
            return .continueButtonHeightRegular
        case .continueButtonHeightCompact:
            return .continueButtonHeightCompact
        case .continueButtonWidth:
            return .continueButtonWidth
        case .minimumStepHeaderHeightForMemoryGame:
            return .minimumStepHeaderHeightForMemoryGame
        case .minimumStepHeaderHeightForTowerOfHanoiPuzzle:
            return .minimumStepHeaderHeightForTowerOfHanoiPuzzle
        case .tableCellDefaultHeight:
            return .tableCellDefaultHeight
        case .textFieldCellHeight:
            return .textFieldCellHeight
        case .choiceCellFirstBaselineOffsetFromTop:
            return .choiceCellFirstBaselineOffsetFromTop
        case .choiceCellLastBaselineToBottom:
            return .choiceCellLastBaselineToBottom
        case .choiceCellLabelLastBaselineToLabelFirstBaseline:
            return .choiceCellLabelLastBaselineToLabelFirstBaseline
        case .learnMoreButtonSideMargin:
            return .learnMoreButtonSideMargin
        case .headlineSideMargin:
            return .headlineSideMargin
        case .toolbarHeight:
            return .toolbarHeight
        case .verticalScaleHeight:
            return .verticalScaleHeight
        case .signatureViewHeight:
            return .signatureViewHeight
        case .psatKeyboardViewWidth:
            return .PSATKeyboardViewWidth
        case .psatKeyboardViewHeight:
            return .PSATKeyboardViewHeight
        case .locationQuestionMapHeight:
            return .locationQuestionMapHeight
        case .topToIconImageViewTop:
            return .topToIconImageViewTop
        case .iconImageViewToCaptionBaseline:
            return .iconImageViewToCaptionBaseline
        case .verificationTextBaselineToResendButtonBaseline:
            return .verificationTextBaselineToResendButtonBaseline
        case ._COUNT:
            return nil
        @unknown default:
            return nil
        }
    }
    
    var metricType: ORK1MetricType {
        switch self {
        case .captionBaselineToFitnessTimerTop, .captionBaselineToInstructionBaseline, .captionBaselineToTappingLabelTop, .choiceCellFirstBaselineOffsetFromTop, .choiceCellLabelLastBaselineToLabelFirstBaseline, .choiceCellLastBaselineToBottom, .continueButtonHeightCompact, .continueButtonHeightRegular, .continueButtonTopMargin, .continueButtonTopMarginForIntroStep, .iconImageViewToCaptionBaseline, .illustrationHeight, .illustrationToCaptionBaseline, .instructionBaselineToLearnMoreBaseline, .instructionImageHeight, .learnMoreBaselineToStepViewTop, .learnMoreBaselineToStepViewTopWithNoLearnMore, .locationQuestionMapHeight, .minimumStepHeaderHeightForMemoryGame, .minimumStepHeaderHeightForTowerOfHanoiPuzzle, .PSATKeyboardViewHeight, .signatureViewHeight, .tableCellDefaultHeight, .textFieldCellHeight, .toolbarHeight, .topToCaptionBaseline, .topToIconImageViewTop, .topToIllustration, .verificationTextBaselineToResendButtonBaseline, .verticalScaleHeight:
            return .vertical
        case .continueButtonWidth, .headlineSideMargin, .learnMoreButtonSideMargin, .PSATKeyboardViewWidth:
            return .horizontal
        case .fontSizeFootnote, .fontSizeHeadline, .fontSizeSubheadline, .fontSizeSurveyHeadline, .maxFontSizeHeadline, .maxFontSizeSurveyHeadline:
            return .fontSize
        }
    }
    
    var isStatic: Bool {
        return Set(Self.staticValues.keys).contains(self)
    }

    static var staticValues: [Self : CGFloat] = {
        return [
            .choiceCellFirstBaselineOffsetFromTop            : 36.0,
            .choiceCellLabelLastBaselineToLabelFirstBaseline : 24.0,
            .choiceCellLastBaselineToBottom                  : 24.0,
            .continueButtonHeightRegular                     : 44.0,
            .fontSizeFootnote                                : 14.0,
            .fontSizeSubheadline                             : 17.0,
            .fontSizeSurveyHeadline                          : 30.0,
            .maxFontSizeSurveyHeadline                       : 32.0,
            .tableCellDefaultHeight                          : 60.0,
            .textFieldCellHeight                             : 55.0,
            .toolbarHeight                                   : 44.0,
        ]
    }()
    
    // for testing
    var objCMetric: ORK1ScreenMetric {
        switch self {
        case .captionBaselineToFitnessTimerTop:
            return .captionBaselineToFitnessTimerTop
        case .captionBaselineToInstructionBaseline:
            return .captionBaselineToInstructionBaseline
        case .captionBaselineToTappingLabelTop:
            return .captionBaselineToTappingLabelTop
        case .choiceCellFirstBaselineOffsetFromTop:
            return .choiceCellFirstBaselineOffsetFromTop
        case .choiceCellLabelLastBaselineToLabelFirstBaseline:
            return .choiceCellLabelLastBaselineToLabelFirstBaseline
        case .choiceCellLastBaselineToBottom:
            return .choiceCellLastBaselineToBottom
        case .continueButtonHeightCompact:
            return .continueButtonHeightCompact
        case .continueButtonHeightRegular:
            return .continueButtonHeightRegular
        case .continueButtonTopMargin:
            return .continueButtonTopMargin
        case .continueButtonTopMarginForIntroStep:
            return .continueButtonTopMarginForIntroStep
        case .continueButtonWidth:
            return .continueButtonWidth
        case .fontSizeFootnote:
            return .fontSizeFootnote
        case .fontSizeHeadline:
            return .fontSizeHeadline
        case .fontSizeSubheadline:
            return .fontSizeSubheadline
        case .fontSizeSurveyHeadline:
            return .fontSizeSurveyHeadline
        case .headlineSideMargin:
            return .headlineSideMargin
        case .iconImageViewToCaptionBaseline:
            return .iconImageViewToCaptionBaseline
        case .illustrationHeight:
            return .illustrationHeight
        case .illustrationToCaptionBaseline:
            return .illustrationToCaptionBaseline
        case .instructionBaselineToLearnMoreBaseline:
            return .instructionBaselineToLearnMoreBaseline
        case .instructionImageHeight:
            return .instructionImageHeight
        case .learnMoreBaselineToStepViewTop:
            return .learnMoreBaselineToStepViewTop
        case .learnMoreBaselineToStepViewTopWithNoLearnMore:
            return .learnMoreBaselineToStepViewTopWithNoLearnMore
        case .learnMoreButtonSideMargin:
            return .learnMoreButtonSideMargin
        case .locationQuestionMapHeight:
            return .locationQuestionMapHeight
        case .maxFontSizeHeadline:
            return .maxFontSizeHeadline
        case .maxFontSizeSurveyHeadline:
            return .maxFontSizeSurveyHeadline
        case .minimumStepHeaderHeightForMemoryGame:
            return .minimumStepHeaderHeightForMemoryGame
        case .minimumStepHeaderHeightForTowerOfHanoiPuzzle:
            return .minimumStepHeaderHeightForTowerOfHanoiPuzzle
        case .PSATKeyboardViewHeight:
            return .psatKeyboardViewHeight
        case .PSATKeyboardViewWidth:
            return .psatKeyboardViewWidth
        case .signatureViewHeight:
            return .signatureViewHeight
        case .tableCellDefaultHeight:
            return .tableCellDefaultHeight
        case .textFieldCellHeight:
            return .textFieldCellHeight
        case .toolbarHeight:
            return .toolbarHeight
        case .topToCaptionBaseline:
            return .topToCaptionBaseline
        case .topToIconImageViewTop:
            return .topToIconImageViewTop
        case .topToIllustration:
            return .topToIllustration
        case .verificationTextBaselineToResendButtonBaseline:
            return .verificationTextBaselineToResendButtonBaseline
        case .verticalScaleHeight:
            return .verticalScaleHeight
        }
    }
       
    // for testing
    var title: String {
        switch self {
        case .captionBaselineToFitnessTimerTop:
            return "captionBaselineToFitnessTimerTop"
        case .captionBaselineToInstructionBaseline:
            return "captionBaselineToInstructionBaseline"
        case .captionBaselineToTappingLabelTop:
            return "captionBaselineToTappingLabelTop"
        case .choiceCellFirstBaselineOffsetFromTop:
            return "choiceCellFirstBaselineOffsetFromTop"
        case .choiceCellLabelLastBaselineToLabelFirstBaseline:
            return "choiceCellLabelLastBaselineToLabelFirstBaseline"
        case .choiceCellLastBaselineToBottom:
            return "choiceCellLastBaselineToBottom"
        case .continueButtonHeightCompact:
            return "continueButtonHeightCompact"
        case .continueButtonHeightRegular:
            return "continueButtonHeightRegular"
        case .continueButtonTopMargin:
            return "continueButtonTopMargin"
        case .continueButtonTopMarginForIntroStep:
            return "continueButtonTopMarginForIntroStep"
        case .continueButtonWidth:
            return "continueButtonWidth"
        case .fontSizeFootnote:
            return "fontSizeFootnote"
        case .fontSizeHeadline:
            return "fontSizeHeadline"
        case .fontSizeSubheadline:
            return "fontSizeSubheadline"
        case .fontSizeSurveyHeadline:
            return "fontSizeSurveyHeadline"
        case .headlineSideMargin:
            return "headlineSideMargin"
        case .iconImageViewToCaptionBaseline:
            return "iconImageViewToCaptionBaseline"
        case .illustrationHeight:
            return "illustrationHeight"
        case .illustrationToCaptionBaseline:
            return "illustrationToCaptionBaseline"
        case .instructionBaselineToLearnMoreBaseline:
            return "instructionBaselineToLearnMoreBaseline"
        case .instructionImageHeight:
            return "instructionImageHeight"
        case .learnMoreBaselineToStepViewTop:
            return "learnMoreBaselineToStepViewTop"
        case .learnMoreBaselineToStepViewTopWithNoLearnMore:
            return "learnMoreBaselineToStepViewTopWithNoLearnMore"
        case .learnMoreButtonSideMargin:
            return "learnMoreButtonSideMargin"
        case .locationQuestionMapHeight:
            return "locationQuestionMapHeight"
        case .maxFontSizeHeadline:
            return "maxFontSizeHeadline"
        case .maxFontSizeSurveyHeadline:
            return "maxFontSizeSurveyHeadline"
        case .minimumStepHeaderHeightForMemoryGame:
            return "minimumStepHeaderHeightForMemoryGame"
        case .minimumStepHeaderHeightForTowerOfHanoiPuzzle:
            return "minimumStepHeaderHeightForTowerOfHanoiPuzzle"
        case .PSATKeyboardViewHeight:
            return "PSATKeyboardViewHeight"
        case .PSATKeyboardViewWidth:
            return "PSATKeyboardViewWidth"
        case .signatureViewHeight:
            return "signatureViewHeight"
        case .tableCellDefaultHeight:
            return "tableCellDefaultHeight"
        case .textFieldCellHeight:
            return "textFieldCellHeight"
        case .toolbarHeight:
            return "toolbarHeight"
        case .topToCaptionBaseline:
            return "topToCaptionBaseline"
        case .topToIconImageViewTop:
            return "topToIconImageViewTop"
        case .topToIllustration:
            return "topToIllustration"
        case .verificationTextBaselineToResendButtonBaseline:
            return "verificationTextBaselineToResendButtonBaseline"
        case .verticalScaleHeight:
            return "verticalScaleHeight"
        }
    }
}


public class ORK1SkinSwift: NSObject {
    
    static let allSizeTypes: [ORK1SizeType] = {
        guard let matrixFile = Bundle(for: ORK1SkinSwift.self).url(forResource: "ORK1SkinMatrix", withExtension: "csv"),
                  let matrixData = try? Data(contentsOf: matrixFile),
                  let fileString = String(data: matrixData, encoding: .utf8) else
        {
            return []
        }
        let csvRows = fileString.components(separatedBy: .newlines)
        let sizes = csvRows[0].components(separatedBy: ",")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .dropLast()
            .map({ $0.components(separatedBy: "x") })
            .map({ CGSize(width: Double($0[0])!, height: Double($0[1])!) })
        
        let isiPads = csvRows[1].components(separatedBy: ",")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .map({ $0 == "true" })
        
        var output = [ORK1SizeType]()
        for n in 0..<sizes.count {
            let metrics = csvRows.dropFirst(2).reduce([ORK1ScreenMetricSwift : CGFloat]()) { partialResult, csvRow in
                var dict = partialResult
                let fields = csvRow.components(separatedBy: ",")
                    .map({ $0.trimmingCharacters(in: .whitespaces) })
                let metric = ORK1ScreenMetricSwift.metric(for: fields.last!)!
                dict[metric] = Double(fields[n])!
                return dict
            }
            output.append(.init(size: sizes[n], isiPad: isiPads[n], metrics: metrics))
        }
        return output
    }()
    
    static let sizeTypesSortedHeight = allSizeTypes.sorted(by: { $0.size.height < $1.size.height })
    static let sizeTypesSortedWidth  = allSizeTypes.sorted(by: { $0.size.width  < $1.size.width  })
    static let ORK1LayoutMarginWidthBezel : CGFloat = 15.0
    static let ORK1LayoutMarginWidthiPad  : CGFloat = 115.0
    
    @objc public static func getMetric(objCMetric: ORK1ScreenMetric, for window: UIWindow?) -> CGFloat {
        guard let swiftMetric = ORK1ScreenMetricSwift.metric(for: objCMetric) else {
            fatalError("FIX THIS LATER")
        }
        return getMetric(metric: swiftMetric, for: window)
    }
    
    @objc public static func getMetric(metric: ORK1ScreenMetricSwift, for window: UIWindow?) -> CGFloat {
        // Use this method instead of UIApplication's keyWindow or UIApplication's delegate's window
        // because we may need the window before the keyWindow is set (e.g., if a view controller
        // loads programmatically on the app delegate to be assigned as the root view controller)
        guard !metric.isStatic else {
            return ORK1ScreenMetricSwift.staticValues[metric]!
        }
        let window = window ?? UIApplication.shared.windows.first!
        var sizeType: ORK1SizeType?
        switch metric.metricType {
        case .vertical, .fontSize:
            sizeType = verticalScreenType(for: window)
        case .horizontal:
            sizeType = horizontalScreenType(for: window)
        }
        return sizeType!.metric(for: metric)
    }
    
    @objc public static func isiPad(for window: UIWindow?) -> Bool {
        let window = window ?? UIApplication.shared.windows.first!
        return verticalScreenType(for: window).isiPad
    }
    
    private static func verticalScreenType(for window: UIWindow) -> ORK1SizeType {
        let maximumDimension = max(window.bounds.size.width, window.bounds.size.height)
        var sizeType: ORK1SizeType?
        for n in 0..<sizeTypesSortedHeight.count {
            let nextSize = sizeTypesSortedHeight[n]
            if maximumDimension < nextSize.size.height + 1 {
                sizeType = nextSize
                break
            }
        }
        if sizeType == nil {
            sizeType = sizeTypesSortedHeight.last!
        }
        return sizeType!
    }
    
    private static func horizontalScreenType(for window: UIWindow) -> ORK1SizeType {
        let minimumDimension = min(window.bounds.size.width, window.bounds.size.height)
        var sizeType: ORK1SizeType?
        for n in 0..<sizeTypesSortedWidth.count {
            let nextSize = sizeTypesSortedWidth[n]
            if minimumDimension < nextSize.size.width + 1 {
                sizeType = nextSize
                break
            }
        }
        if sizeType == nil {
            sizeType = sizeTypesSortedHeight.last!
        }
        return sizeType!
    }
    
    @objc public static func standardHorizontalMargin(for view: UIView) -> CGFloat {
        let window: UIWindow
        if let viewIsWindow = view as? UIWindow {
            window = viewIsWindow
        } else {
            window = view.window ?? UIApplication.shared.windows.first!  // need a proper window to use bounds
        }
        let screenSize = horizontalScreenType(for: window)
        if screenSize.isiPad {
            // Use adaptive side margin, if window is wider than largest non-iPad device (iPhone6 Plus).
            // Min Margin = ORK1LayoutMarginWidthThinBezelRegular, Max Margin = ORK1LayoutMarginWidthiPad or iPad12_9
            var largestNoniPadDevice: ORK1SizeType!
            var maxWidth: CGFloat = 0
            for sizeType in allSizeTypes.filter({ !$0.isiPad }) {
                if sizeType.size.width > maxWidth {
                    maxWidth = sizeType.size.width
                    largestNoniPadDevice = sizeType
                }
            }
            var ratio = (window.bounds.size.width - largestNoniPadDevice.size.width) / (screenSize.size.width - largestNoniPadDevice.size.width)
            ratio = min(1.0, ratio)
            ratio = max(0.0, ratio)
            return ORK1LayoutMarginWidthBezel + (ORK1LayoutMarginWidthiPad - ORK1LayoutMarginWidthBezel) * ratio
        } else {
            return ORK1LayoutMarginWidthBezel
        }
    }
    
    @objc public static func standardLeftMarginForTableViewCell(for view: UIView) -> CGFloat {
        // now static since https://github.com/CareEvolution/ResearchKit/pull/71/files
        return ORK1LayoutMarginWidthBezel
    }
    
    @objc public static func standardFullScreenLayoutMargins(for view: UIView) -> UIEdgeInsets {
        let window = view.window ?? UIApplication.shared.windows.first!
        let screenType = horizontalScreenType(for: window)
        if screenType.isiPad {
            let margin = standardHorizontalMargin(for: view)
            return UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        } else {
            return .zero
        }
    }
    
    @objc public static func scrollIndicatorInsetsForScrollview(for view: UIView) -> UIEdgeInsets {
        let window = view.window ?? UIApplication.shared.windows.first!
        let screenType = horizontalScreenType(for: window)
        if screenType.isiPad {
            let margin = standardHorizontalMargin(for: view)
            return UIEdgeInsets(top: 0, left: -margin, bottom: 0, right: -margin)
        } else {
            return .zero
        }
    }
    
    @objc public static func widthForSignatureView(window: UIWindow?) -> CGFloat {
        let window = window ?? UIApplication.shared.windows.first!
        let windowSize = window.bounds.size
        let windowPortraitWidth = min(windowSize.width, windowSize.height)
        return windowPortraitWidth - (2 * standardHorizontalMargin(for: window) + 2 * standardLeftMarginForTableViewCell(for: window))
    }
}
