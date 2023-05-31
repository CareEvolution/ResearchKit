//
//  CEV1RangeOfMotionStepViewController.swift
//  ORK1Kit
//
//  Created by Eric Schramm on 3/27/23.
//  Copyright © 2023 researchkit.org. All rights reserved.
//

import Foundation

public class CEV1RangeOfMotionStepViewController: ORK1RangeOfMotionStepViewController {
    
    let debugMode = false
    
    var referenceAttitude: CMAttitude?
    var highestAngle = Double.leastNonzeroMagnitude
    var lowestAngle = Double.greatestFiniteMagnitude
    var lastRawAngle: Double?
    var motionUpdates = 0
    var clockwiseCrossesZero = 0
    var cumulativeAngle = 0.0
    var firstRawAngle = 0.0
    
    public override var result: ORK1StepResult? {
        let stepResult = super.result
        
        guard let step = step as? CEV1RangeOfMotionStep else {
            return nil
        }
    
        let result = ORK1RangeOfMotionResult(identifier: step.identifier)
        switch step.motionType {
        case .flexion:
            result.extended = lowestAngle
            result.flexed = highestAngle
        case .extension:
            result.flexed = lowestAngle
            result.extended = highestAngle
        }
        result.fileResult = self.fileResult
        
        stepResult?.results = (self.addedResults ?? []) + [result]
        
        return stepResult
    }
}

extension CEV1RangeOfMotionStepViewController {
    public override func deviceMotionRecorderDidUpdate(with motion: CMDeviceMotion) {
        if referenceAttitude == nil {
            referenceAttitude = motion.attitude
        }
        guard let referenceAttitude else {
            return
        }
        motionUpdates += 1
        let currentAttitude = motion.attitude
        currentAttitude.multiply(byInverseOf: referenceAttitude)
        if let angle = deviceAngleInDegrees(from: motion.attitude) {
            lowestAngle = min(lowestAngle, angle)
            highestAngle = max(highestAngle, angle)
            if debugMode {
                print("CW axis crossings: \(clockwiseCrossesZero) : rawAngle: \(lastRawAngle!); cumulativeAngle: \(cumulativeAngle); correctedAngle: \(angle); lowestAngle: \(lowestAngle); highestAngle: \(highestAngle)")
            }
        }
    }
    
    public func deviceAngleInDegrees(from attitude: CMAttitude) -> Double? {
        
        guard let step = step as? CEV1RangeOfMotionStep else {
            return nil
        }
        
        // an angle describing rotation in the axis from 0 to 360
        // http://lavalle.pl/planning/node103.html
        let rawAngle: Double
        switch step.axisOfRotation {
        case .pitch:
            let pitchAngle = Measurement(value: atan2(-attitude.rotationMatrix.m32, attitude.rotationMatrix.m33), unit: UnitAngle.radians).converted(to: .degrees).value
            rawAngle = (pitchAngle > 0) ? pitchAngle : 180 + (180 + pitchAngle)
        case .roll:
            let rollAngle = Measurement(value: atan2(attitude.rotationMatrix.m31, attitude.rotationMatrix.m11), unit: UnitAngle.radians).converted(to: .degrees).value
            rawAngle = (rollAngle > 0) ? rollAngle : 180 + (180 + rollAngle)
        case .yaw:
            let yawAngle = Measurement(value: atan2(attitude.rotationMatrix.m21, attitude.rotationMatrix.m11), unit: UnitAngle.radians).converted(to: .degrees).value
            rawAngle = (yawAngle > 0) ? yawAngle : 180 + (180 + yawAngle)
        }
        
        if let lastRawAngle {
            let correctedLastRawAngle = lastRawAngle + Double(clockwiseCrossesZero) * 360
            if crossesAxis(rawAngle: rawAngle, lastRawAngle: lastRawAngle) {
                if debugMode {
                    print("Axis Crossed - cumulativeAngle: \(cumulativeAngle); firstRawAngle: \(firstRawAngle)")
                }
                switch directionOfRotation(rawAngle: rawAngle, lastRawAngle: lastRawAngle) {
                case .clockwise:
                    clockwiseCrossesZero += 1
                case .counterClockwise:
                    clockwiseCrossesZero -= 1
                }
            }
            cumulativeAngle += (rawAngle + Double(clockwiseCrossesZero) * 360 - correctedLastRawAngle)
        }
        
        guard motionUpdates > 1 else {
            return nil
        }
        if motionUpdates == 2 {
            firstRawAngle = rawAngle
            if debugMode {
                print("firstRawAngle: \(firstRawAngle)")
            }
        }
        lastRawAngle = rawAngle
            
        switch step.measuredDirectionOfRotation {
        case .clockwise:
            return cumulativeAngle + firstRawAngle - step.offsetFromReferenceAxis.converted(to: .degrees).value
        case .counterClockwise:
            return -(cumulativeAngle + firstRawAngle - step.offsetFromReferenceAxis.converted(to: .degrees).value)
        }
        
    }
    
    // assumes maximum rotation rate < 10 degrees per sample, at 100 Hz = 1000 degrees / sec, or 2.8 rotations per second ~ 167 rpm, probably not physically possibly by a human doing normal rotation of a joint
    func directionOfRotation(rawAngle: Double, lastRawAngle: Double) -> CEV1DirectionOfRotation {
        if crossesAxis(rawAngle: rawAngle, lastRawAngle: lastRawAngle) {
            return (rawAngle < lastRawAngle) ? .clockwise : .counterClockwise
        } else {
            return (rawAngle > lastRawAngle) ? .clockwise : .counterClockwise
        }
    }
    
    // assumes maximum rotation rate < 10 degrees per sample, at 100 Hz = 1000 degrees / sec, or 2.8 rotations per second ~ 167 rpm, probably not physically possibly by a human doing normal rotation of a joint
    func crossesAxis(rawAngle: Double, lastRawAngle: Double) -> Bool {
        return abs(rawAngle - lastRawAngle) > 10
    }
}
