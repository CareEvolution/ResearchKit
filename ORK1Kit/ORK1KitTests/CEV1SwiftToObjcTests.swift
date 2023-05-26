//
//  CEV1SwiftToObjcTests.swift
//  ORK1KitTests
//
//  Created by Eric Schramm on 3/22/23.
//  Copyright © 2023 researchkit.org. All rights reserved.
//

import XCTest
@testable import ORK1Kit

final class CEV1SwiftToObjcTests: XCTestCase {
    
    func testNSCoderArchivingForCEV1RangeOfMotionStep() throws {
        
        let heartbeatImage = UIImage(named: "heartbeat", in: Bundle(for: CEV1RangeOfMotionStep.self), compatibleWith: nil)
        
        let cevRangeOfMotionStep = CEV1RangeOfMotionStep(identifier: "cevIdentifier", motionType: .extension, axisOfRotation: .roll, measuredDirectionOfRotation: .clockwise, offsetFromReferenceAxisDegrees: 90)
        cevRangeOfMotionStep.spokenInstruction = "these are the spoken instructions"
        cevRangeOfMotionStep.image = heartbeatImage
        cevRangeOfMotionStep.isOptional = false
        let addedConfiguration = ORK1DeviceMotionRecorderConfiguration(identifier: "motionZZZ", frequency: 123)
        cevRangeOfMotionStep.recorderConfigurations = [addedConfiguration]
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: cevRangeOfMotionStep, requiringSecureCoding: true)
        guard let decodedStep = try NSKeyedUnarchiver.unarchivedObject(ofClass: CEV1RangeOfMotionStep.self, from: data) else {
            XCTAssert(true, "decodedStep not unarchived as CEV1RangeOfMotionStep")
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
        XCTAssertEqual((decodedConfiguration! as! ORK1DeviceMotionRecorderConfiguration).frequency, 123)
    }
}

