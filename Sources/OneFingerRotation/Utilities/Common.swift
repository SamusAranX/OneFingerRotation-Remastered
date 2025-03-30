//
//  Common.swift
//  OneFingerRotation-Remastered
//
//  Created by Emma Alyx Wunder on 15.03.25.
//

import SwiftUI

let floatFormatStyle = FloatingPointFormatStyle<Double>.number.grouping(.never).precision(.fractionLength(2))
let moreFloatFormatStyle = FloatingPointFormatStyle<Double>.number.grouping(.never).precision(.fractionLength(5))
let intFloatFormatStyle = FloatingPointFormatStyle<Double>.number.precision(.integerAndFractionLength(integer: 3, fraction: 2))

func calculateGestureRotationAngle(for value: DragGesture.Value, viewSize: CGSize, angleSnap: Angle? = nil) -> Angle {
	let halfViewWidth = viewSize.width / 2
	let halfViewHeight = viewSize.height / 2

	let centerX = value.startLocation.x - halfViewWidth
	let centerY = value.startLocation.y - halfViewHeight
	let startVector = CGVector(dx: centerX, dy: centerY)

	let endX = value.startLocation.x + value.translation.width - halfViewWidth
	let endY = value.startLocation.y + value.translation.height - halfViewHeight
	let endVector = CGVector(dx: endX, dy: endY)

	let atan2Y = startVector.dy * endVector.dx - startVector.dx * endVector.dy
	let atan2X = startVector.dx * endVector.dx + startVector.dy * endVector.dy
	let angleDifference = atan2(atan2Y, atan2X)

	var angle = Angle(radians: -Double(angleDifference))

	if let snap = angleSnap {
		let snappedAngle = round(angle.degrees / snap.degrees) * snap.degrees
		angle = Angle(degrees: snappedAngle)
	}

	return angle
}

extension Angle {
	static var halfCircle: Self {
		return .degrees(180)
	}

	static var fullCircle: Self {
		return .degrees(360)
	}
}
