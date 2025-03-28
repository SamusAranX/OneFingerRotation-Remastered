//
//  ValueRotation.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct ValueRotation: ViewModifier {
	@State private var rotationAngle: Angle = .zero
	@State private var previousAngle: Angle = .zero
	@Binding var totalAngle: Angle

	var animation: Animation?
	@State private var isDragging: Bool = false
	@State private var fullRotations: Int = 0

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

	public init(
		totalAngle: Binding<Angle>,
		animation: Animation? = nil
	) {
		self._totalAngle = totalAngle
		self.rotationAngle = totalAngle.wrappedValue
		self.animation = animation
	}

	public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(rotationAngle, anchor: .center)
			.onChange(of: totalAngle, initial: false) { _, newValue in
				if !isDragging {
					withAnimation(animation) {
						self.rotationAngle = newValue
						self.fullRotations = 0
					}
				}
			}
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						self.isDragging = true
						let angle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
						let angleDifference = angle - self.previousAngle
						if angleDifference.degrees > 180 {
							self.fullRotations -= 1
						} else if angleDifference.degrees < -180 {
							self.fullRotations += 1
						}
						let currentAngle = rotationAngle + angleDifference
						self.rotationAngle = currentAngle
						self.previousAngle = angle
						let totalRotationAngle = currentAngle + (Angle(degrees: 360) * Double(fullRotations))
						self.totalAngle = totalRotationAngle
					}
					.onEnded { _ in
						self.isDragging = false
						self.previousAngle = .zero
					}
			)
	}
}

public extension View {
	func valueRotation(
		totalAngle: Binding<Angle>,
		animation: Animation? = nil
	) -> some View {
		self.modifier(
			ValueRotation(
				totalAngle: totalAngle,
				animation: animation
			)
		)
	}
}

#Preview {
	@Previewable @State var totalAngle: Angle = .zero

	VStack(alignment: .center) {
		DebugTitleView(title: "ValueRotation")

		DebugRectView()
			.padding(.vertical, 40)
			.valueRotation(totalAngle: $totalAngle)
			.overlay { DebugAngleOverlayView(angle: $totalAngle) }

		Spacer()
	}
}
