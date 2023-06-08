//
//  CEVRangeOfMotion.swift
//  ResearchKit
//
//  Created by Eric Schramm on 3/21/23.
//  Copyright © 2023 researchkit.org. All rights reserved.
//

import UIKit

public enum CEVAxisOfRotation: Int {
    
    /// Reference orientation of device is lying flat on a horizontal surface with screen up, with the top of the phone pointing true North (accuracy may vary based on calibration to magnetic North and correction based on location)
    
    /// A pitch is a rotation around a lateral axis that passes through the device from side to side. A pitch of zero is the device lying flat on a horiztonal surface with screen up, with positive rotation when the top of the device is raised in relation to the bottom, or clockwise rotation when looking at the device from the left side (volume buttons on iPhone).
    case pitch
    
    /// A roll is a rotation around a lateral axis that passes through the device from side to side. A roll of zero is the device lying flat on a horiztonal surface with screen up, with positive rotation to the right or clockwise rotation when looking at the device from the bottom (lightning port on iPhone).
    case roll
    
    /// A yaw is a rotation around an axis that runs vertically through the device. It is perpendicular to the body of the device, with its origin at the center of gravity and directed toward the bottom of the device. A yaw of zero is the device (appropriately calibrated for magnetic north and location) pointing to true North, with positive rotation to the right or clockwise rotation when looking at the device from the top (screen on iPhone).
    case yaw
}

public enum CEVDirectionOfRotation: Int {
    case clockwise
    case counterClockwise
}

public enum CEVRangeOfMotionType: Int {
    case flexion
    case `extension`
}

/*
 
 Examples of configuration:
 
 - Flexure of shoulder:
    - iPhone in Upside Down orientation on lateral aspect of deltoid, held by alternate hand, alternatively can hold iPhone Upside Down orientation in right hand such that right index finger can tap screen to begin/end test
    - CEVMotionType.flexion
    - CEVAxisOfRotation.pitch
    - CEVDirectionOfRotation.clockwise
    - offsetFromReferenceAxis = 270.0

 - Extension of knee:
    - iPhone in Upside Down orientation on medial aspect of shin, right below knee
    - CEVMotionType.extension
    - CEVAxisOfRotation.pitch
    - CEVDirectionOfRotation.clockwise
    - offsetFromReferenceAxis = 270.0
 
 - Flexure of knee:
    - iPhone in Upside Down orientation on medial aspect of shin, right below knee
    - CEVMotionType.flexion
    - CEVAxisOfRotation.pitch
    - CEVDirectionOfRotation.counterClockwise
    - offsetFromReferenceAxis = 0
 */

public class CEVRangeOfMotionStep: ORKRangeOfMotionStep {
    
    enum NSCodingKeys: String {
        case motionType
        case axisOfRotation
        case measuredDirectionOfRotation
        case offsetFromReferenceAxis
    }
    
    // must be var to comply with NSCopying
    
    var motionType: CEVRangeOfMotionType
    var axisOfRotation: CEVAxisOfRotation
    var measuredDirectionOfRotation: CEVDirectionOfRotation
    var offsetFromReferenceAxis: Measurement<UnitAngle>
    
    /// Initializes a new CEVRangeOfMotionStep.
    /// - Parameters:
    ///   - motionType: flexion or extension - determines which ends of the angle based on `measuredDirectionOfRotation` will appear in the ORKRangeOfMotionResult for `.flexed` and `.extended`
    ///   - identifier: The unique identifier of the step.
    ///   - axisOfRotation: Search for device data points observed after this date.
    ///   - measuredDirectionOfRotation: clockwise or counter-clockwise. (see CEVAxisOfRotation documentation for definition based on axis)
    ///   - offsetFromReferenceAxisDegrees: The offset in degrees from the axis' reference (see CEVAxisOfRotation documentation) such that the result will include a minimalRotation and maximalRotation that subtract the offset from the absolute angles as defined in CEVAxisOfRotation.
    required public init(identifier: String, motionType: CEVRangeOfMotionType, axisOfRotation: CEVAxisOfRotation, measuredDirectionOfRotation: CEVDirectionOfRotation, offsetFromReferenceAxisDegrees: Double) {
        self.motionType = motionType
        self.axisOfRotation = axisOfRotation
        self.offsetFromReferenceAxis = Measurement(value: offsetFromReferenceAxisDegrees, unit: .degrees)
        self.measuredDirectionOfRotation = measuredDirectionOfRotation
        // limbOption is arbitrary here but required for super class initializer
        super.init(identifier: identifier, limbOption: .left)
    }
    
    required init(coder aDecoder: NSCoder) {
        self.motionType = CEVRangeOfMotionType(rawValue: aDecoder.decodeInteger(forKey: NSCodingKeys.motionType.rawValue)) ?? .flexion
        self.axisOfRotation = CEVAxisOfRotation(rawValue: aDecoder.decodeInteger(forKey: NSCodingKeys.axisOfRotation.rawValue)) ?? .pitch
        self.measuredDirectionOfRotation = CEVDirectionOfRotation(rawValue: aDecoder.decodeInteger(forKey: NSCodingKeys.measuredDirectionOfRotation.rawValue)) ?? .clockwise
        self.offsetFromReferenceAxis = Measurement(value: aDecoder.decodeDouble(forKey: NSCodingKeys.offsetFromReferenceAxis.rawValue), unit: .degrees)
        super.init(coder: aDecoder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(motionType.rawValue, forKey: NSCodingKeys.motionType.rawValue)
        coder.encode(axisOfRotation.rawValue, forKey: NSCodingKeys.axisOfRotation.rawValue)
        coder.encode(measuredDirectionOfRotation.rawValue, forKey: NSCodingKeys.measuredDirectionOfRotation.rawValue)
        coder.encode(offsetFromReferenceAxis.converted(to: .degrees).value, forKey: NSCodingKeys.offsetFromReferenceAxis.rawValue)
    }
    
    
    override public class var supportsSecureCoding: Bool {
        return true
    }
    
    @objc class func stepViewControllerClass() -> AnyClass {
        return CEVRangeOfMotionStepViewController.self
    }
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let step = super.copy(with: zone) as! CEVRangeOfMotionStep
        step.motionType = motionType
        step.axisOfRotation = axisOfRotation
        step.measuredDirectionOfRotation = measuredDirectionOfRotation
        step.offsetFromReferenceAxis = offsetFromReferenceAxis
        return step
    }
    
    // https://stackoverflow.com/questions/33319959/nsobject-subclass-in-swift-hash-vs-hashvalue-isequal-vs
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CEVRangeOfMotionStep {
            return super.isEqual(other) &&
            other.motionType == motionType &&
            other.axisOfRotation == axisOfRotation &&
            other.measuredDirectionOfRotation == measuredDirectionOfRotation &&
            other.offsetFromReferenceAxis == offsetFromReferenceAxis
        } else {
            return false
        }
    }
    
    public override var hash : Int {
        return super.hash & motionType.hashValue ^ axisOfRotation.hashValue ^ measuredDirectionOfRotation.hashValue ^ offsetFromReferenceAxis.hashValue
    }
}
