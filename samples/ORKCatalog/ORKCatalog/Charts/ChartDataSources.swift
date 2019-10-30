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

class PieChartDataSource: NSObject, ORK1PieChartViewDataSource {
    
    let colors = [
        UIColor(red: 217/225, green: 217/255, blue: 217/225, alpha: 1),
        UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1),
        UIColor(red: 244/255, green: 190/255, blue: 74/255, alpha: 1)
    ]
    let values = [10.0, 25.0, 45.0]
    
    func numberOfSegments(in pieChartView: ORK1PieChartView ) -> Int {
        return colors.count
    }
    
    func pieChartView(_ pieChartView: ORK1PieChartView, valueForSegmentAt index: Int) -> CGFloat {
        return CGFloat(values[index])
    }
    
    func pieChartView(_ pieChartView: ORK1PieChartView, colorForSegmentAt index: Int) -> UIColor {
        return colors[index]
    }
    
    func pieChartView(_ pieChartView: ORK1PieChartView, titleForSegmentAt index: Int) -> String {
        return "Title \(index + 1)"
    }
}

class LineGraphDataSource: NSObject, ORK1ValueRangeGraphChartViewDataSource {
    
    var plotPoints =
    [
        [
            ORK1ValueRange(value: 10),
            ORK1ValueRange(value: 20),
            ORK1ValueRange(value: 25),
            ORK1ValueRange(),
            ORK1ValueRange(value: 30),
            ORK1ValueRange(value: 40),
        ],
        [
            ORK1ValueRange(value: 2),
            ORK1ValueRange(value: 4),
            ORK1ValueRange(value: 8),
            ORK1ValueRange(value: 16),
            ORK1ValueRange(value: 32),
            ORK1ValueRange(value: 64),
        ]
    ]
    
    func numberOfPlots(in graphChartView: ORK1GraphChartView) -> Int {
        return plotPoints.count
    }

    func graphChartView(_ graphChartView: ORK1GraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORK1ValueRange {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
       return plotPoints[plotIndex].count
    }
    
    func maximumValue(for graphChartView: ORK1GraphChartView) -> Double {
        return 70
    }
    
    func minimumValue(for graphChartView: ORK1GraphChartView) -> Double {
        return 0
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return "\(pointIndex + 1)"
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, drawsPointIndicatorsForPlotIndex plotIndex: Int) -> Bool {
        if plotIndex == 1 {
            return false
        }
        return true
    }
}

class DiscreteGraphDataSource: NSObject, ORK1ValueRangeGraphChartViewDataSource {
    
    var plotPoints =
    [
        [
            ORK1ValueRange(minimumValue: 0, maximumValue: 2),
            ORK1ValueRange(minimumValue: 1, maximumValue: 4),
            ORK1ValueRange(minimumValue: 2, maximumValue: 6),
            ORK1ValueRange(minimumValue: 3, maximumValue: 8),
            ORK1ValueRange(minimumValue: 5, maximumValue: 10),
            ORK1ValueRange(minimumValue: 8, maximumValue: 13),
        ],
        [
            ORK1ValueRange(value: 1),
            ORK1ValueRange(minimumValue: 2, maximumValue: 6),
            ORK1ValueRange(minimumValue: 3, maximumValue: 10),
            ORK1ValueRange(minimumValue: 5, maximumValue: 11),
            ORK1ValueRange(minimumValue: 7, maximumValue: 13),
            ORK1ValueRange(minimumValue: 10, maximumValue: 13),
        ]
    ]
    
    func numberOfPlots(in graphChartView: ORK1GraphChartView) -> Int {
        return plotPoints.count
    }

    func graphChartView(_ graphChartView: ORK1GraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORK1ValueRange {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
        return plotPoints[plotIndex].count
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return "\(pointIndex + 1)"
    }

}

class BarGraphDataSource: NSObject, ORK1ValueStackGraphChartViewDataSource {
    
    var plotPoints =
    [
        [
            ORK1ValueStack(stackedValues: [4, 6]),
            ORK1ValueStack(stackedValues: [2, 4, 4]),
            ORK1ValueStack(stackedValues: [2, 6, 3, 6]),
            ORK1ValueStack(stackedValues: [3, 8, 10, 12]),
            ORK1ValueStack(stackedValues: [5, 10, 12, 8]),
            ORK1ValueStack(stackedValues: [8, 13, 18]),
        ],
        [
            ORK1ValueStack(stackedValues: [14]),
            ORK1ValueStack(stackedValues: [6, 6]),
            ORK1ValueStack(stackedValues: [3, 10, 12]),
            ORK1ValueStack(stackedValues: [5, 11, 14]),
            ORK1ValueStack(stackedValues: [7, 13, 20]),
            ORK1ValueStack(stackedValues: [10, 13, 25]),
        ]
    ]
    
    public func numberOfPlots(in graphChartView: ORK1GraphChartView) -> Int {
        return plotPoints.count
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, dataPointForPointIndex pointIndex: Int, plotIndex: Int) -> ORK1ValueStack {
        return plotPoints[plotIndex][pointIndex]
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, numberOfDataPointsForPlotIndex plotIndex: Int) -> Int {
        return plotPoints[plotIndex].count
    }
    
    func graphChartView(_ graphChartView: ORK1GraphChartView, titleForXAxisAtPointIndex pointIndex: Int) -> String? {
        return "\(pointIndex + 1)"
    }
    
}
