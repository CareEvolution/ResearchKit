/*
Copyright (c) 2015, James Cox. All rights reserved.

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

class PieChartDataSource: NSObject, ORKLegacyPieChartViewDataSource {
    
    let colors = [
        UIColor(red: 217/225, green: 217/255, blue: 217/225, alpha: 1),
        UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1),
        UIColor(red: 244/255, green: 190/255, blue: 74/255, alpha: 1)
    ]
    let values = [10.0, 25.0, 45.0]
    
    func numberOfSegments(in pieChartView: ORKLegacyPieChartView ) -> Int {
        return colors.count
    }
    
    func pieChartView(_ pieChartView: ORKLegacyPieChartView, valueForSegmentAt index: Int) -> CGFloat {
        return CGFloat(values[index])
    }
    
    func pieChartView(_ pieChartView: ORKLegacyPieChartView, colorForSegmentAt index: Int) -> UIColor {
        return colors[index]
    }
    
    func pieChartView(_ pieChartView: ORKLegacyPieChartView, titleForSegmentAt index: Int) -> String {
        return "Title \(index + 1)"
    }
}

class LineGraphDataSource: NSObject, ORKLegacyValueRangeGraphChartViewDataSource {
    
    var plotPoints =
    [
        [
            ORKLegacyValueRange(value: 10),
            ORKLegacyValueRange(value: 20),
            ORKLegacyValueRange(value: 25),
            ORKLegacyValueRange(),
            ORKLegacyValueRange(value: 30),
            ORKLegacyValueRange(value: 40),
        ],
        [
            ORKLegacyValueRange(value: 2),
            ORKLegacyValueRange(value: 4),
            ORKLegacyValueRange(value: 8),
            ORKLegacyValueRange(value: 16),
            ORKLegacyValueRange(value: 32),
            ORKLegacyValueRange(value: 64),
        ]
    ]
    
    func numberOfPlots(in graphChartView: ORKLegacyGraphChartView) -> Int {
        return plotPoints.count
    }

    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKLegacyValueRange {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
       return plotPoints[plotIndex].count
    }
    
    func maximumValue(for graphChartView: ORKLegacyGraphChartView) -> Double {
        return 70
    }
    
    func minimumValue(for graphChartView: ORKLegacyGraphChartView) -> Double {
        return 0
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return "\(pointIndex + 1)"
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, drawsPointIndicatorsForPlotIndex plotIndex: Int) -> Bool {
        if plotIndex == 1 {
            return false
        }
        return true
    }
}

class DiscreteGraphDataSource: NSObject, ORKLegacyValueRangeGraphChartViewDataSource {
    
    var plotPoints =
    [
        [
            ORKLegacyValueRange(minimumValue: 0, maximumValue: 2),
            ORKLegacyValueRange(minimumValue: 1, maximumValue: 4),
            ORKLegacyValueRange(minimumValue: 2, maximumValue: 6),
            ORKLegacyValueRange(minimumValue: 3, maximumValue: 8),
            ORKLegacyValueRange(minimumValue: 5, maximumValue: 10),
            ORKLegacyValueRange(minimumValue: 8, maximumValue: 13),
        ],
        [
            ORKLegacyValueRange(value: 1),
            ORKLegacyValueRange(minimumValue: 2, maximumValue: 6),
            ORKLegacyValueRange(minimumValue: 3, maximumValue: 10),
            ORKLegacyValueRange(minimumValue: 5, maximumValue: 11),
            ORKLegacyValueRange(minimumValue: 7, maximumValue: 13),
            ORKLegacyValueRange(minimumValue: 10, maximumValue: 13),
        ]
    ]
    
    func numberOfPlots(in graphChartView: ORKLegacyGraphChartView) -> Int {
        return plotPoints.count
    }

    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKLegacyValueRange {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
        return plotPoints[plotIndex].count
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return "\(pointIndex + 1)"
    }

}

class BarGraphDataSource: NSObject, ORKLegacyValueStackGraphChartViewDataSource {
    
    var plotPoints =
    [
        [
            ORKLegacyValueStack(stackedValues: [4, 6]),
            ORKLegacyValueStack(stackedValues: [2, 4, 4]),
            ORKLegacyValueStack(stackedValues: [2, 6, 3, 6]),
            ORKLegacyValueStack(stackedValues: [3, 8, 10, 12]),
            ORKLegacyValueStack(stackedValues: [5, 10, 12, 8]),
            ORKLegacyValueStack(stackedValues: [8, 13, 18]),
        ],
        [
            ORKLegacyValueStack(stackedValues: [14]),
            ORKLegacyValueStack(stackedValues: [6, 6]),
            ORKLegacyValueStack(stackedValues: [3, 10, 12]),
            ORKLegacyValueStack(stackedValues: [5, 11, 14]),
            ORKLegacyValueStack(stackedValues: [7, 13, 20]),
            ORKLegacyValueStack(stackedValues: [10, 13, 25]),
        ]
    ]
    
    public func numberOfPlots(in graphChartView: ORKLegacyGraphChartView) -> Int {
        return plotPoints.count
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORKLegacyValueStack {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
        return plotPoints[plotIndex].count
    }
    
    func graphChartView(_ graphChartView: ORKLegacyGraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return "\(pointIndex + 1)"
    }
    
}
