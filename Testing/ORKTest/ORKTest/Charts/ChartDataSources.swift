/*
Copyright (c) 2015, James Cox. All rights reserved.
Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.

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

import ResearchKitLegacy

func randomColorArray(_ number: Int) -> [UIColor] {
        
        func random() -> CGFloat {
            return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        }
        
        var colors: [UIColor] = []
        for _ in 0 ..< number {
            colors.append(UIColor(red: random(), green: random(), blue: random(), alpha: 1))
        }
        return colors
    }

let NumberOfPieChartSegments = 13

class ColorlessPieChartDataSource: NSObject, ORKLegacyPieChartViewDataSource {
    
    func numberOfSegments(in pieChartView: ORKLegacyPieChartView ) -> Int {
        return NumberOfPieChartSegments
    }
    
    func pieChartView(_ pieChartView: ORKLegacyPieChartView, valueForSegmentAt index: Int) -> CGFloat {
        return CGFloat(index + 1)
    }
    
    func pieChartView(_ pieChartView: ORKLegacyPieChartView, titleForSegmentAt index: Int) -> String {
        return "Title \(index + 1)"
    }
}

class RandomColorPieChartDataSource: ColorlessPieChartDataSource {
    
    lazy var backingStore: [UIColor] = {
        return randomColorArray(NumberOfPieChartSegments)
        }()

    func pieChartView(_ pieChartView: ORKLegacyPieChartView, colorForSegmentAtIndex index: Int) -> UIColor {
        return backingStore[index]
    }
}

class BaseFloatRangeGraphChartDataSource:  NSObject, ORKLegacyValueRangeGraphChartViewDataSource {
    var plotPoints: [[ORKLegacyValueRange]] = [[]]
    
    internal func numberOfPlots(in graphChartView: ORKLegacyGraphChartView) -> Int {
        return plotPoints.count
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKLegacyValueRange {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
        return plotPoints[plotIndex].count
    }
}

class BaseFloatStackGraphChartDataSource:  NSObject, ORKLegacyValueStackGraphChartViewDataSource {
    
    var plotPoints: [[ORKLegacyValueStack]] = [[]]
    
    public func numberOfPlots(in graphChartView: ORKLegacyGraphChartView) -> Int {
        return plotPoints.count
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKLegacyValueStack {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
        return plotPoints[plotIndex].count
    }
}

class LineGraphChartDataSource: BaseFloatRangeGraphChartDataSource {
    
    override init() {
        super.init()
        plotPoints =
            [
                [
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                ],
                [
                    ORKLegacyValueRange(value: 2),
                    ORKLegacyValueRange(value: 4),
                    ORKLegacyValueRange(value: 8),
                    ORKLegacyValueRange(value: 16),
                    ORKLegacyValueRange(value: 32),
                    ORKLegacyValueRange(value: 50),
                    ORKLegacyValueRange(value: 64),
                ],
                [
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                ],
        ]
    }
    
    func maximumValueForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Double {
        return 70
    }
    
    func minimumValueForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Double {
        return 0
    }
    
    func numberOfDivisionsInXAxisForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 10
    }

    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return (pointIndex % 2 == 0) ? nil : "\(pointIndex + 1)"
    }

    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, drawsVerticalReferenceLineAtPointIndex pointIndex: Int) -> Bool {
        return (pointIndex % 2 == 1) ? false : true
    }

    func scrubbingPlotIndexForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 2
    }
}

class ColoredLineGraphChartDataSource: LineGraphChartDataSource {
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, colorForPlotIndex plotIndex: Int) -> UIColor {
        let color: UIColor
        switch plotIndex {
        case 0:
            color = UIColor.cyan
        case 1:
            color = UIColor.magenta
        case 2:
            color = UIColor.yellow
        default:
            color = UIColor.red
        }
        return color
    }
    
    func graphChartView(graphChartView: ORKLegacyGraphChartView, fillColorForPlotIndex plotIndex: Int) -> UIColor {
        let color: UIColor
        switch plotIndex {
        case 0:
            color = UIColor.blue.withAlphaComponent(0.6)
        case 1:
            color = UIColor.red.withAlphaComponent(0.6)
        case 2:
            color = UIColor.green.withAlphaComponent(0.6)
        default:
            color = UIColor.cyan.withAlphaComponent(0.6)
        }
        return color
    }
}

class DiscreteGraphChartDataSource: BaseFloatRangeGraphChartDataSource {
    
    override init() {
        super.init()
        plotPoints =
            [
                [
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(minimumValue: 0, maximumValue: 2),
                    ORKLegacyValueRange(minimumValue: 1, maximumValue: 3),
                    ORKLegacyValueRange(minimumValue: 2, maximumValue: 6),
                    ORKLegacyValueRange(minimumValue: 3, maximumValue: 9),
                    ORKLegacyValueRange(minimumValue: 4, maximumValue: 13),
                ],
                [
                    ORKLegacyValueRange(value: 1),
                    ORKLegacyValueRange(minimumValue: 2, maximumValue: 4),
                    ORKLegacyValueRange(minimumValue: 3, maximumValue: 8),
                    ORKLegacyValueRange(minimumValue: 5, maximumValue: 11),
                    ORKLegacyValueRange(minimumValue: 7, maximumValue: 13),
                    ORKLegacyValueRange(minimumValue: 10, maximumValue: 13),
                    ORKLegacyValueRange(minimumValue: 12, maximumValue: 15),
                ],
                [
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(minimumValue: 5, maximumValue: 6),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(minimumValue: 2, maximumValue: 15),
                    ORKLegacyValueRange(minimumValue: 4, maximumValue: 11),
                ],
        ]
    }
    
    func numberOfDivisionsInXAxisForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 8
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String {
        return "\(pointIndex + 1)"
    }

    func scrubbingPlotIndexForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 2
    }
}

class ColoredDiscreteGraphChartDataSource: DiscreteGraphChartDataSource {
    func graphChartView(graphChartView: ORKLegacyGraphChartView, colorForPlotIndex plotIndex: Int) -> UIColor {
        let color: UIColor
        switch plotIndex {
        case 0:
            color = UIColor.cyan
        case 1:
            color = UIColor.magenta
        case 2:
            color = UIColor.yellow
        default:
            color = UIColor.red
        }
        return color
    }
}

class BarGraphChartDataSource: BaseFloatStackGraphChartDataSource {
    
    override init() {
        super.init()
        plotPoints =
            [
                [
                    ORKLegacyValueStack(),
                    ORKLegacyValueStack(stackedValues: [0, 2, 5]),
                    ORKLegacyValueStack(stackedValues: [1, 3, 2]),
                    ORKLegacyValueStack(stackedValues: [2, 6, 1]),
                    ORKLegacyValueStack(stackedValues: [3, 9, 4]),
                    ORKLegacyValueStack(stackedValues: [4, 13, 2]),
                ],
                [
                    ORKLegacyValueStack(stackedValues: [1]),
                    ORKLegacyValueStack(stackedValues: [2, 4]),
                    ORKLegacyValueStack(stackedValues: [3, 8]),
                    ORKLegacyValueStack(stackedValues: [5, 11]),
                    ORKLegacyValueStack(stackedValues: [7, 13]),
                    ORKLegacyValueStack(stackedValues: [10, 13]),
                    ORKLegacyValueStack(stackedValues: [12, 15]),
                ],
                [
                    ORKLegacyValueStack(),
                    ORKLegacyValueStack(stackedValues: [5, 6]),
                    ORKLegacyValueStack(stackedValues: [2, 15]),
                    ORKLegacyValueStack(stackedValues: [4, 11]),
                    ORKLegacyValueStack(),
                    ORKLegacyValueStack(stackedValues: [6, 16]),
                ],
        ]
    }
    
    func numberOfDivisionsInXAxisForGraphChartView(graphChartView: ORKLegacyGraphChartView) -> Int {
        return 8
    }
    
    func graphChartView(graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String {
        return "\(pointIndex + 1)"
    }
    
    func scrubbingPlotIndexForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 2
    }
}

class ColoredBarGraphChartDataSource: BarGraphChartDataSource {
    
    func graphChartView(graphChartView: ORKLegacyGraphChartView, colorForPlotIndex plotIndex: Int) -> UIColor {
        let color: UIColor
        switch plotIndex {
        case 0:
            color = UIColor.cyan
        case 1:
            color = UIColor.magenta
        case 2:
            color = UIColor.yellow
        default:
            color = UIColor.red
        }
        return color
    }
    
    override func scrubbingPlotIndexForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 1
    }
}

class PerformanceLineGraphChartDataSource: BaseFloatRangeGraphChartDataSource {
    
    override init() {
        super.init()
        plotPoints =
            [
                [
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                ],
                [
                    ORKLegacyValueRange(value: 2),
                    ORKLegacyValueRange(value: 4),
                    ORKLegacyValueRange(value: 8),
                    ORKLegacyValueRange(value: 16),
                    ORKLegacyValueRange(value: 32),
                    ORKLegacyValueRange(value: 50),
                    ORKLegacyValueRange(value: 64),
                    ORKLegacyValueRange(value: 2),
                    ORKLegacyValueRange(value: 4),
                    ORKLegacyValueRange(value: 8),
                    ORKLegacyValueRange(value: 16),
                    ORKLegacyValueRange(value: 32),
                    ORKLegacyValueRange(value: 50),
                    ORKLegacyValueRange(value: 64),
                    ORKLegacyValueRange(value: 2),
                    ORKLegacyValueRange(value: 4),
                    ORKLegacyValueRange(value: 8),
                    ORKLegacyValueRange(value: 16),
                    ORKLegacyValueRange(value: 32),
                    ORKLegacyValueRange(value: 50),
                    ORKLegacyValueRange(value: 64),
                    ORKLegacyValueRange(value: 2),
                    ORKLegacyValueRange(value: 4),
                    ORKLegacyValueRange(value: 8),
                    ORKLegacyValueRange(value: 16),
                    ORKLegacyValueRange(value: 32),
                    ORKLegacyValueRange(value: 50),
                    ORKLegacyValueRange(value: 64),
                ],
                [
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 20),
                    ORKLegacyValueRange(value: 25),
                    ORKLegacyValueRange(),
                    ORKLegacyValueRange(value: 30),
                    ORKLegacyValueRange(value: 40),
                    ORKLegacyValueRange(),
                ],
        ]
    }
    
    func maximumValueForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Double {
        return 70
    }
    
    func minimumValueForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Double {
        return 0
    }
    
    func numberOfDivisionsInXAxisForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 10
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return (pointIndex % 2 == 0) ? nil : "\(pointIndex + 1)"
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, drawsVerticalReferenceLineAtPointIndex pointIndex: Int) -> Bool {
        return (pointIndex % 2 == 1) ? false : true
    }
    
    func scrubbingPlotIndexForGraphChartView(_ graphChartView: ORKLegacyGraphChartView) -> Int {
        return 2
    }
}
