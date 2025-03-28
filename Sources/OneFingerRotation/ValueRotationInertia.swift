//
//  ValueRotationInertia.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct ValueRotationInertia: ViewModifier {
	@Binding private var rotationAngle: Angle

	/// Controls the amount of friction. Ranges between zero (no friction) and one (too much friction).
	@Binding private var friction: Double

	/// Controls the initial velocity of the view after the user lets go of it.
	/// Ranges between zero and one, but shouldn't be meaningfully larger than 0.1 for best results.
	@Binding private var velocityMultiplier: Double

	@GestureState private var gestureRotation: Angle = .zero

	@State private var lastVelocity: Double = 0

	/// Keeps track of all data needed for inertial control.
	@State private var inertia: Inertia = .init()

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

    var animation: Animation?
    @State private var isDragging: Bool = false

	@State private var previousAngle: Angle = .zero
	@State private var fullRotations: Int = 0

    /// Initialization of three declarable and optional values.
    public init(
        rotationAngle: Binding<Angle>,
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult),
        animation: Animation? = nil
    ) {
		self._rotationAngle = rotationAngle
        self._friction = friction
        self._velocityMultiplier = velocityMultiplier
        self.animation = animation
    }

	private func inertiaTask() async {
		guard let inertiaDirection = self.inertia.direction else { return }

		for await _ in CADisplayLink.timestamps() {
			guard self.inertia.active, !self.isDragging else {
				break
			}

			let angle = Angle(degrees: Double(self.lastVelocity) * inertiaDirection.rawValue)
			self.rotationAngle += angle
			self.lastVelocity *= (1 - friction)

			if self.lastVelocity < 0.1 {
				self.inertia.reset()
				break
			}
		}
	}
    
    public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(rotationAngle, anchor: .center)
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						self.isDragging = true
						self.inertia.reset()

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
					}
					.onEnded { value in
						self.isDragging = false
						self.previousAngle = .zero

						let angle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
						let direction: Inertia.Direction = angle >= .zero ? .clockwise : .counterClockwise

						let velocity = value.velocity
						self.lastVelocity = sqrt(
							pow(velocity.width, 2) +
							pow(velocity.height, 2)
						) * self.velocityMultiplier

						if abs(velocity.width) > rotationThreshold || abs(velocity.height) > rotationThreshold {
							self.inertia.begin(direction)
						}
					}
			)
			.task(id: self.inertia.active) {
				await inertiaTask()
			}
    }
}

public extension View {
    func valueRotationInertia(
        rotationAngle: Binding<Angle>,
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult),
        animation: Animation? = nil
	) -> some View {
        let effect = ValueRotationInertia(
			rotationAngle: rotationAngle,
			friction: friction,
            velocityMultiplier: velocityMultiplier,
            animation: animation
		)
        return self.modifier(effect)
    }
}

#Preview {
	@Previewable @State var rotationAngle: Angle = .zero

	VStack(alignment: .center) {
		DebugTitleView(title: "ValueRotation with Inertia")

		DebugRectView()
			.padding(.vertical, 40)
			.valueRotationInertia(rotationAngle: $rotationAngle)
			.overlay { DebugAngleOverlayView(angle: $rotationAngle) }

		Stepper("Rotation", value: $rotationAngle.degrees, step: 20)
			.padding(.horizontal)

		Spacer()
	}
}
