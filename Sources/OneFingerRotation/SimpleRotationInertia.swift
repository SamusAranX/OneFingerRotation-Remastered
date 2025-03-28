//
//  SimpleRotationInertia.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct SimpleRotationInertia: ViewModifier {
	@State private var rotationAngle: Angle

	/// Controls the amount of friction.
	/// Is clamped to a closed range from zero (no friction) to one (too much friction).
	@Binding private var friction: Double

	/// Controls the initial velocity of the view after the user lets go of it.
	/// Is clamped to a closed range from zero to one, but shouldn't be meaningfully larger than 0.1 for best results.
	@Binding private var velocityMultiplier: Double

	@GestureState private var gestureRotation: Angle = .zero

	@State private var lastVelocity: Double = 0

	/// Keeps track of all data needed for inertial control.
	@State private var inertia: Inertia = .init()

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

	public init(
		rotationAngle: Angle = .zero,
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult)
	) {
		self._rotationAngle = State(initialValue: rotationAngle)
		self._friction = friction
		self._velocityMultiplier = velocityMultiplier
	}

	private func inertiaTask() async {
		guard self.inertia.active, let inertiaDirection = self.inertia.direction else { return }

		for await _ in CADisplayLink.timestamps() {
			let angle = Angle(degrees: Double(self.lastVelocity) * inertiaDirection.rawValue)
			self.rotationAngle += angle
			self.lastVelocity *= (1 - friction.clamped(to: 0...1))

			if self.lastVelocity < 0.1 {
				print("done with inertia, cancelling task")
				self.inertia.reset()
				break
			}
		}
	}

	public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(rotationAngle + gestureRotation, anchor: .center)
			.gesture(
				DragGesture(minimumDistance: 0)
					.updating($gestureRotation) { value, state, _ in
						self.inertia.reset()
						state = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
					}
					.onEnded { value in
						let angle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
						let direction: Inertia.Direction = angle >= .zero ? .clockwise : .counterClockwise
						self.rotationAngle += angle

						let velocity = value.velocity
						self.lastVelocity = sqrt(
							pow(velocity.width, 2) +
							pow(velocity.height, 2)
						) * self.velocityMultiplier.clamped(to: 0...1)

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
	func simpleRotationInertia(
		rotationAngle: Angle = Angle.zero,
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult)
	) -> some View {
		let effect = SimpleRotationInertia(
			rotationAngle: rotationAngle,
			friction: friction,
			velocityMultiplier: velocityMultiplier
		)
		return self.modifier(effect)
	}
}

#Preview {
	VStack(alignment: .center) {
		DebugTitleView(title: "SimpleRotation with Inertia")

		DebugRectView()
			.padding(.vertical, 40)
			.simpleRotationInertia()

		Spacer()
	}
}
