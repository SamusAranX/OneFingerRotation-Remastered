//
//  Defaults.swift
//  OneFingerRotation-Remastered
//
//  Created by Emma Alyx Wunder on 15.03.25.
//

import SwiftUI

// Default values for things passed into constructors
@usableFromInline let defaultFriction: Double = 0.025

@usableFromInline let defaultAutoRotationSpeed: Angle = .degrees(20)

@usableFromInline let defaultKnobMinAngle: Angle = .degrees(-90)
@usableFromInline let defaultKnobMaxAngle: Angle = .degrees(90)
@usableFromInline let defaultKnobRange = defaultKnobMinAngle...defaultKnobMaxAngle

// Shared constants
@usableFromInline let rotationThreshold: Double = 12.0
