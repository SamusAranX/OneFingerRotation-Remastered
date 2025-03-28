//
//  ValueAutoRotationInertia.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct ValueAutoRotationInertia: ViewModifier {
    @Binding private var rotationAngle: Angle
    @GestureState private var gestureRotation: Angle = .zero
    @State private var lastVelocity: Double = 0
    @State private var isSpinning = false
    @Binding var friction: Double
    @Binding var velocityMultiplier: Double
	@State private var fullRotations: Int = 0

	/// Keeps track of all data needed for inertial control.
	@State private var inertia: Inertia = .init()
	@State private var isDragging = false

	@Binding private var autoRotationSpeed: Angle
	@Binding private var autoRotationEnabled: Bool
	
	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

    var animation: Animation?
	@State private var previousAngle: Angle = .zero
    @State private var rotationDirection: Double = 1

	private var taskID: Int {
		(self.inertia.active ? 0 : 1) + (self.autoRotationEnabled ? 0 : 1)
	}

    /// Initialization of three declarable and optional values.
    public init(
        rotationAngle: Binding<Angle>,
		autoRotationSpeed: Binding<Angle>,
		autoRotationEnabled: Binding<Bool> = .constant(false),
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult),
        animation: Animation? = nil
    ) {
		self._rotationAngle = rotationAngle
		self._autoRotationSpeed = autoRotationSpeed
		self._autoRotationEnabled = autoRotationEnabled
        self._friction = friction
        self._velocityMultiplier = velocityMultiplier
        self.animation = animation
    }

	private func animationTask() async {
		for await timestamp in CADisplayLink.timestamps() {
			guard !self.isDragging else { continue }

			if self.inertia.active, let inertiaDirection = self.inertia.direction {
				// do inertia
				let angle = Angle(degrees: Double(self.lastVelocity) * inertiaDirection.rawValue)
				self.rotationAngle += angle
				self.lastVelocity *= (1 - friction)

				if self.lastVelocity < 0.1 {
					self.inertia.reset()
				}
			} else if self.autoRotationEnabled {
				// do auto rotation
				let deltaRotation = self.autoRotationSpeed / timestamp.fps
				let newRotation = self.rotationAngle + deltaRotation
				self.rotationAngle = newRotation + Angle(degrees: 360 * Double(self.fullRotations))
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
			.task(id: taskID) {
				await animationTask()
			}
    }
}

public extension View {
	func valueAutoRotationInertia(
		rotationAngle: Binding<Angle>,
		autoRotationSpeed: Binding<Angle>,
		autoRotationEnabled: Binding<Bool> = .constant(false),
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult),
		animation: Animation? = nil
	) -> some View {
		let effect = ValueAutoRotationInertia(
			rotationAngle: rotationAngle,
			autoRotationSpeed: autoRotationSpeed,
			autoRotationEnabled: autoRotationEnabled,
			friction: friction,
			velocityMultiplier: velocityMultiplier,
			animation: animation
		)
		return self.modifier(effect)
	}
}

#Preview {
	@Previewable @State var rotationAngle: Angle = .zero
	@Previewable @State var rotationSpeed: Angle = .degrees(22.5)
	@Previewable @State var rotationEnabled: Bool = true

	VStack(alignment: .center) {
		DebugTitleView(title: "ValueRotation with Inertia")

		DebugRectView()
			.padding(.vertical, 40)
			.valueAutoRotationInertia(rotationAngle: $rotationAngle, autoRotationSpeed: $rotationSpeed, autoRotationEnabled: $rotationEnabled)
			.overlay { DebugAngleOverlayView(angle: $rotationAngle) }

		VStack {
			HStack(spacing: 20) {
				Text("Speed")
				Slider(value: $rotationSpeed.degrees, in: -360...360)
				Text("\(rotationSpeed.degrees.formatted(FloatingPointFormatStyle<Double>.number.precision(.integerAndFractionLength(integer: 3, fraction: 2))))")
					.monospacedDigit()
			}

			Toggle("Rotation Enabled", isOn: $rotationEnabled)
		}
		.padding(.horizontal)

		Spacer()
	}
}
