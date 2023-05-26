//
//  CEVSwiftToObjcTests.swift
//  ResearchKitTests
//
//  Created by Eric Schramm on 5/26/23.
//  Copyright © 2023 researchkit.org. All rights reserved.
//

import XCTest
@testable import ResearchKit

final class CEVSwiftToObjcTests: XCTestCase {
    
    func testNSCoderArchivingForCEV1RangeOfMotionStep() throws {
        
        let heartbeatImage = UIImage(named: "heartbeat", in: Bundle(for: CEVRangeOfMotionStep.self), compatibleWith: nil)
        
        let cevRangeOfMotionStep = CEVRangeOfMotionStep(identifier: "cevIdentifier", motionType: .extension, axisOfRotation: .roll, measuredDirectionOfRotation: .clockwise, offsetFromReferenceAxisDegrees: 90)
        cevRangeOfMotionStep.spokenInstruction = "these are the spoken instructions"
        cevRangeOfMotionStep.image = heartbeatImage
        cevRangeOfMotionStep.isOptional = false
        let addedConfiguration = ORKDeviceMotionRecorderConfiguration(identifier: "motionZZZ", frequency: 123)
        cevRangeOfMotionStep.recorderConfigurations = [addedConfiguration]
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: cevRangeOfMotionStep, requiringSecureCoding: true)
        guard let decodedStep = try NSKeyedUnarchiver.unarchivedObject(ofClass: CEVRangeOfMotionStep.self, from: data) else {
            XCTAssert(true, "decodedStep not unarchived as CEVRangeOfMotionStep")
            return
        }
        
        XCTAssertEqual(decodedStep.identifier, "cevIdentifier")
        XCTAssertEqual(decodedStep.motionType, .extension)
        XCTAssertEqual(decodedStep.axisOfRotation, .roll)
        XCTAssertEqual(decodedStep.measuredDirectionOfRotation, .clockwise)
        XCTAssertEqual(decodedStep.offsetFromReferenceAxis, Measurement<UnitAngle>.init(value: 90, unit: .degrees))
        XCTAssertEqual(decodedStep.spokenInstruction, "these are the spoken instructions")
        XCTAssertNotNil(heartbeatImage)
        XCTAssertNotNil(decodedStep.image)
        XCTAssertEqual(decodedStep.image?.pngData(), heartbeatImage?.pngData())
        XCTAssertEqual(decodedStep.isOptional, false)
        let decodedConfiguration = decodedStep.recorderConfigurations?.first
        XCTAssertNotNil(decodedConfiguration)
        XCTAssertEqual(decodedConfiguration?.identifier, "motionZZZ")
        XCTAssertEqual((decodedConfiguration! as! ORKDeviceMotionRecorderConfiguration).frequency, 123)
    }
}

