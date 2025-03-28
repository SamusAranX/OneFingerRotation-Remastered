//
//  Inertia.swift
//  OneFingerRotation
//
//  Created by Emma Alyx Wunder on 16.03.25.
//

import Foundation

struct Inertia {
	enum Direction: Double {
		case clockwise = 1.0
		case counterClockwise = -1.0
	}

	/// Keeps track of whether the view is freely spinning, controlled only by inertia rather than direct user input.
	var active = false

	/// Keeps track of the direction the view was spinning when the user gave up control.
	var direction: Direction? = nil

	mutating func begin(_ direction: Direction) {
		self.active = true
		self.direction = direction
	}

	/// Stops any inertia animations.
	mutating func reset() {
		self.active = false
		self.direction = nil
	}
}
