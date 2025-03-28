//
//  KnobRotationInertia.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct KnobRotationInertia: ViewModifier {
	@Binding private var knobValue: Double

	@State private var rotationAngle: Angle = .zero
	@State private var totalAngle: Angle
	@GestureState private var gestureRotation: Angle = .zero

	@State private var minAngle: Angle
	@State private var maxAngle: Angle
	private var clampRange: ClosedRange<Angle>

	private var animation: Animation?

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero
	
	@State private var isDragging: Bool = false
	@State private var previousAngle: Angle = .zero

	@Binding private var friction: Double
	@Binding private var velocityMultiplier: Double

	@State private var lastVelocity: Double = 0

	/// Keeps track of all data needed for inertial control.
	@State private var inertia: Inertia = .init()

	/// Initialization of three declarable and optional values.
	public init(
		knobValue: Binding<Double>,
		minAngle: Angle,
		maxAngle: Angle,
		friction: Binding<Double>,
		velocityMultiplier: Binding<Double>,
		animation: Animation?
	) {
		self._knobValue = knobValue
		self.minAngle = minAngle
		self.maxAngle = maxAngle
		self.clampRange = minAngle...maxAngle
		self._friction = friction
		self._velocityMultiplier = velocityMultiplier
		self._rotationAngle = .init(initialValue: minAngle + (maxAngle - minAngle) * knobValue.wrappedValue)
		self.totalAngle = minAngle+(maxAngle-minAngle)*knobValue.wrappedValue
		self.animation = animation
	}

	private func updateKnobValue() {
		self.knobValue =
		(self.rotationAngle - self.minAngle).degrees /
		(self.maxAngle - self.minAngle).degrees
	}

	private func inertiaTask(angleSnap: Angle? = nil) async {
		guard self.inertia.active, let inertiaDirection = self.inertia.direction else { return }

		print("starting inertia task")

		for await _ in CADisplayLink.timestamps() {
			guard !self.isDragging else { break	}

			let angle = Angle(degrees: Double(lastVelocity) * inertiaDirection.rawValue)
			let newRotationAngle = rotationAngle + angle

			if !self.clampRange.contains(newRotationAngle) {
				// knob is about to clip the min/max range, cancel inertia early
				self.inertia.reset()
				if newRotationAngle <= self.clampRange.lowerBound {
					self.rotationAngle = self.clampRange.lowerBound
				} else if newRotationAngle >= self.clampRange.upperBound {
					self.rotationAngle = self.clampRange.upperBound
				}
				self.updateKnobValue()
				break
			}

			self.rotationAngle = newRotationAngle
			self.updateKnobValue()
			self.lastVelocity *= (1 - friction)
			if self.lastVelocity < 0.1 {
				// knob has slowed down enough, cancel inertia
				self.inertia.reset()
				break
			}
		}
	}

	public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(rotationAngle + gestureRotation, anchor: .center)
			.onChange(of: knobValue, initial: false) { _, _ in
				// TODO: the !self.inertia.active guard needs to be here
				// or the inertia reset will instantly cancel inertia tasks.
				// need to come up with a way to allow outside assignments
				// to knobValue without inhibiting animations
				guard !isDragging, !self.inertia.active else { return }

				self.inertia.reset()

				withAnimation(self.animation) {
					self.rotationAngle = self.minAngle + (self.maxAngle - self.minAngle) * self.knobValue
				}
			}
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						self.inertia.reset()
						self.isDragging = true

						let angle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
						let angleDifference = angle - self.previousAngle

						let currentAngle = rotationAngle + angleDifference
						let clampedAngle = currentAngle.clamped(to: self.clampRange)

						if abs(angleDifference.degrees) < 90 {
							self.rotationAngle = clampedAngle
							self.knobValue = (clampedAngle - minAngle).degrees / (maxAngle - minAngle).degrees
						}

						self.previousAngle = angle
					}
					.onEnded { value in
						self.isDragging = false
						self.previousAngle = .zero

						self.lastVelocity = sqrt(
							pow(value.velocity.width, 2) +
							pow(value.velocity.height, 2)
						) * velocityMultiplier

						let angle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
						let direction: Inertia.Direction = angle >= .zero ? .clockwise : .counterClockwise

						if abs(value.velocity.width) > rotationThreshold || abs(value.velocity.height) > rotationThreshold {
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
    func knobRotationInertia(
        knobValue: Binding<Double>,
		minAngle: Angle = defaultKnobMinAngle,
		maxAngle: Angle = defaultKnobMaxAngle,
		friction: Binding<Double> = .constant(defaultFriction),
		velocityMultiplier: Binding<Double> = .constant(defaultVelocityMult),
        animation: Animation? = nil,
		stoppingAnimation: Binding<Bool> = .constant(false)
	) -> some View {
        let effect = KnobRotationInertia(
            knobValue: knobValue,
            minAngle: minAngle,
            maxAngle: maxAngle,
            friction: friction,
            velocityMultiplier: velocityMultiplier,
            animation: animation
        )
        return self.modifier(effect)
    }
}

#Preview {
	@Previewable @State var knobValue: Double = 0.33

	VStack(alignment: .center) {
		DebugTitleView(title: "KnobRotation with Inertia")

		DebugKnobView()
			.padding(.vertical, 24)
			.knobRotationInertia(knobValue: $knobValue)

		HStack(spacing: 20) {
			Text("Value")
			Slider(value: $knobValue, in: 0...1)
			Text("\(knobValue.formatted(FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))))")
				.monospacedDigit()
		}
		.padding(.horizontal)

		Section("Set knobValue to:") {
			HStack {
				Button("0") { knobValue = 0 }
				Button("0.25") { knobValue = 0.25 }
				Button("0.5") { knobValue = 0.5 }
				Button("0.75") { knobValue = 0.75 }
				Button("1.0") { knobValue = 1 }
			}
			.buttonStyle(.bordered)
			   .controlSize(.large)
		}


		Spacer()
	}
}
