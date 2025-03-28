//
//  Defaults.swift
//  OneFingerRotation
//
//  Created by Emma Alyx Wunder on 15.03.25.
//

import SwiftUI

// Default values for things passed into constructors
@usableFromInline let defaultFriction: Double = 0.025
@usableFromInline let defaultVelocityMult: Double = 0.01
@usableFromInline let defaultAngleSnap: Angle? = nil
@usableFromInline let defaultAngleSnapShowFactor: Double = 0.1

@usableFromInline let defaultAutoRotationSpeed: Angle = .degrees(20)

@usableFromInline let defaultKnobMinAngle: Angle = .degrees(-90)
@usableFromInline let defaultKnobMaxAngle: Angle = .degrees(90)

// Shared constants
let rotationThreshold: Double = 12.0
