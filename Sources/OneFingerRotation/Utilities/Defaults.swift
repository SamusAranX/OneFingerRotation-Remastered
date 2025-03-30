//
//  Defaults.swift
//  OneFingerRotation-Remastered
//
//  Created by Emma Alyx Wunder on 15.03.25.
//

import SwiftUI

// Default values for things passed into constructors
@usableFromInline let defaultFriction: Double = 2.0
@usableFromInline let defaultAutoRotationSpeed: Angle = .degrees(20)
let defaultKnobRange = Angle(degrees: -90)...Angle(degrees: 90)

// Shared constants
let rotationThreshold: Double = 12.0
let minimumVelocity: Double = .pi
