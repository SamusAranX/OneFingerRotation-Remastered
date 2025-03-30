//
//  ViewRotation.swift
//  OneFingerRotation-Remastered
//
//  Created by Emma Alyx Wunder on 29.03.25.
//

import SwiftUI
import RealModule

public struct ViewRotation: ViewModifier {

	public enum Mode {
		case knob(range: ClosedRange<Angle>)
		case inertia(friction: Double)
		case autoRotation(speed: Angle)
		case autoRotationNoTouch(speed: Angle)
		case inertiaAndAutoRotation(friction: Double, speed: Angle)
	}

	enum Direction: Double {
		case clockwise = 1.0
		case counterClockwise = -1.0
	}

	/// The initial angle that's applied to the modified view.
	@Binding var rotationAngle: Angle

	/// Controls whether touch-based rotation is enabled or not.
	@Binding var touchRotationEnabled: Bool {
		didSet {
			// reset isDragging when touch rotation is disabled
			self.isDragging = false
		}
	}

	/// Used in touch-based rotation calculations.
	@State private var previousAngle: Angle = .zero

	/// Defines a minimum and maximum allowed rotation for the modified view. Only applies to touch-based rotation, inertia, and auto rotation, **not** externally set values.
	@State private var knobRange: ClosedRange<Angle>?

	/// Controls whether inertia is enabled or not.
	@Binding var inertiaEnabled: Bool {
		didSet {
			// reset all inertia-related values when inertia is disabled
			self.resetInertia()
		}
	}

	/// Keeps track of whether the modified view is freely spinning, controlled only by inertia rather than direct user input.
	@State private var inertiaActive = false

	/// Keeps track of the direction the modified view was spinning when the user gave up control.
	@State private var inertiaDirection: Direction? = nil

	/// Controls how quickly rotating views slow down.
	@Binding var inertiaFriction: Double

	/// Used in inertia calculations.
	@State private var lastVelocity: Double = 0

	/// Used in inertia calculations.
	@State private var lastAngleDiff: Angle = .zero

	/// Controls whether auto rotation is enabled or not.
	@Binding var autoRotationEnabled: Bool

	/// The amount by which the modified view should rotate per second.
	@Binding var autoRotationSpeed: Angle

	// TODO: add angle snapping?

	/// Whether the modified view is currently being manipulated by the user.
	@State private var isDragging: Bool = false

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

	/// The ViewRotation modifier's initializer. It is recommended to use `.viewRotation()` instead.
	public init(
		rotationAngle: Binding<Angle>? = nil,
		touchRotationEnabled: Binding<Bool> = .constant(true),
		knobRange: ClosedRange<Angle>? = nil,
		inertiaEnabled: Binding<Bool> = .constant(false),
		inertiaFriction: Binding<Double> = .constant(defaultFriction),
		autoRotationEnabled: Binding<Bool> = .constant(false),
		autoRotationSpeed: Binding<Angle> = .constant(defaultAutoRotationSpeed)
	) {
		// This ensures rotation can still happen, even if no actual binding was passed in
		var dummyAngle: Angle = .zero
		let dummyBinding = Binding(
			get: { dummyAngle },
			set: { dummyAngle = $0 }
		)

		self._rotationAngle = rotationAngle ?? dummyBinding
		self._touchRotationEnabled = touchRotationEnabled
		self.knobRange = knobRange
		self._inertiaEnabled = inertiaEnabled
		self._inertiaFriction = inertiaFriction
		self._autoRotationEnabled = autoRotationEnabled
		self._autoRotationSpeed = autoRotationSpeed
	}

	// Property to facilitate an early continue in the animation loop
	var shouldAnimate: Bool {
		let animateInertia = self.inertiaEnabled && self.inertiaActive
		let animateAutoRotation = self.autoRotationEnabled

		if let knobRange = self.knobRange {
			let canNotAnimate = (self.rotationAngle == knobRange.lowerBound && self.autoRotationSpeed <= .zero) || (self.rotationAngle == knobRange.upperBound && self.autoRotationSpeed >= .zero)
			return animateInertia || (animateAutoRotation && !canNotAnimate)
		} else {
			return animateInertia || animateAutoRotation
		}
	}

	/// This value changes every time either inertia or auto rotation are toggled.
	/// Use this in `.task()` modifiers to ensure animations are started or canceled correctly.
	var animationTaskID: Int {
		(self.inertiaActive ? 0 : 1) + (self.autoRotationEnabled ? 0 : 1)
	}

	/// Sets up an inertia animation with the value in `lastVelocity`
	private func beginInertia(_ direction: Direction) {
		print("inertia started: \(direction)")
		self.inertiaActive = true
		self.inertiaDirection = direction
	}

	private func beginInertia(angle: Angle) {
		if abs(angle.degrees) < 0.1 {
			print("inertia start angle too small, not applying inertia")
		} else if angle > .zero {
			self.beginInertia(.clockwise)
		} else if angle < .zero {
			self.beginInertia(.counterClockwise)
		}
	}

	private func resetInertia() {
		self.inertiaActive = false
		self.inertiaDirection = nil
		self.lastVelocity = 0
		self.lastAngleDiff = .zero
	}

	private func doRotation(_ value: DragGesture.Value) -> Angle {
		let angle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
		let angleDiff = angle - self.previousAngle
		self.previousAngle = angle

		var currentAngle = rotationAngle + angleDiff

		// Ensure that the rotation angle rotates smoothly instead of glitching around 180° steps
		if angleDiff > .halfCircle {
			currentAngle -= .fullCircle
		} else if angleDiff < -(.halfCircle) {
			currentAngle += .fullCircle
		}

		if let knobRange = self.knobRange {
			self.rotationAngle = currentAngle.clamped(to: knobRange)
		} else {
			self.rotationAngle = currentAngle
		}

		self.previousAngle = angle

		return angleDiff
	}

	private func animationTask() async {
		for await timestamp in CADisplayLink.timestamps() {
			guard !self.isDragging && self.shouldAnimate else { continue }

			if self.inertiaActive, let inertiaDirection = self.inertiaDirection {
				// do inertia
				let angle = Angle(degrees: Double(self.lastVelocity) / timestamp.fps * inertiaDirection.rawValue)
				self.lastVelocity *= 1 - ((.exp(1 / timestamp.fps) - 1) * self.inertiaFriction)

				if let knobRange = self.knobRange {
					self.rotationAngle = (self.rotationAngle + angle).clamped(to: knobRange)
				} else {
					self.rotationAngle += angle
				}

				if self.lastVelocity <= minimumVelocity {
					print("inertia ended (velocity smaller than \(minimumVelocity))")
					self.resetInertia()
				} else if let knobRange = self.knobRange, self.rotationAngle == knobRange.lowerBound || self.rotationAngle == knobRange.upperBound {
					print("inertia ended (knob limit reached)")
					self.resetInertia()
				}
			} else if self.autoRotationEnabled {
				// do auto rotation
				let deltaRotation = self.autoRotationSpeed / timestamp.fps
				let newRotation = self.rotationAngle + deltaRotation

				if let knobRange = self.knobRange {
					self.rotationAngle = newRotation.clamped(to: knobRange)
				} else {
					self.rotationAngle = newRotation
				}
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
						guard self.touchRotationEnabled else { return }

						self.isDragging = true
						self.resetInertia()
						let angleDiff = self.doRotation(value)
						if angleDiff != .zero {
							self.lastAngleDiff = angleDiff
						}
					}
					.onEnded { value in
						guard self.touchRotationEnabled else { return }

						self.isDragging = false

						guard self.inertiaEnabled else {
							self.previousAngle = .zero
							return
						}

						let angleDiff = self.doRotation(value)
						if angleDiff != .zero {
							self.lastAngleDiff = angleDiff
						}
						self.previousAngle = .zero

						let velocity = value.velocity
						self.lastVelocity = sqrt(
							pow(velocity.width, 2) +
							pow(velocity.height, 2)
						)
						print("lastVelocity: \(lastVelocity)")
						print("lastAngleDiff: \(lastAngleDiff.degrees)°")

						if self.inertiaEnabled && (abs(velocity.width) > rotationThreshold || abs(velocity.height) > rotationThreshold) {
							self.beginInertia(angle: self.lastAngleDiff)
						}
					}
			)
			.task(id: self.animationTaskID) {
				await self.animationTask()
			}
	}
}

public extension View {
	/// Adds one-finger rotation capabilities to a view.
	///
	/// - Parameter rotationAngle: An optional binding that represents the total rotation angle of the view. Omit this for set-and-forget rotation.
	/// - Parameter touchRotationEnabled: Whether touch-based rotation is enabled.
	/// - Parameter knobRange: Enables Knob Mode™. Adds minimum and maximum rotation angles that the view can't exceed during touch-based, inertia-based, or auto rotation. Does not apply if `rotationAngle` is set to a value outside of this range externally.
	/// - Parameter inertiaEnabled: Whether inertia animations are enabled.
	/// - Parameter inertiaFriction: Controls how quickly the view slows down during inertia animations.
	/// - Parameter autoRotationEnabled: Whether auto rotation is enabled.
	/// - Parameter autoRotationSpeed: Set to make the view rotate by this much per second.
	func viewRotation(
		rotationAngle: Binding<Angle>? = nil,
		touchRotationEnabled: Binding<Bool> = .constant(true),
		knobRange: ClosedRange<Angle>? = nil,
		inertiaEnabled: Binding<Bool> = .constant(false),
		inertiaFriction: Binding<Double> = .constant(defaultFriction),
		autoRotationEnabled: Binding<Bool> = .constant(false),
		autoRotationSpeed: Binding<Angle> = .constant(defaultAutoRotationSpeed)
	) -> some View {
		return self.modifier(
			ViewRotation(
				rotationAngle: rotationAngle,
				touchRotationEnabled: touchRotationEnabled,
				knobRange: knobRange,
				inertiaEnabled: inertiaEnabled,
				inertiaFriction: inertiaFriction,
				autoRotationEnabled: autoRotationEnabled,
				autoRotationSpeed: autoRotationSpeed
			)
		)
	}

	/// Adds one-finger rotation capabilities to a view using a handful of shortcut enum cases.
	///
	/// - Parameter mode: Selects a setup shortcut.
	func viewRotation(mode: ViewRotation.Mode) -> some View {
		let viewRotation: ViewRotation

		switch mode {
			case .knob(range: let range):
				viewRotation = ViewRotation(knobRange: range)
			case .inertia(friction: let friction):
				viewRotation = ViewRotation(inertiaEnabled: .constant(true), inertiaFriction: .constant(friction))
			case .autoRotation(speed: let speed):
				viewRotation = ViewRotation(autoRotationEnabled: .constant(true), autoRotationSpeed: .constant(speed))
			case .autoRotationNoTouch(speed: let speed):
				viewRotation = ViewRotation(touchRotationEnabled: .constant(false), autoRotationEnabled: .constant(true), autoRotationSpeed: .constant(speed))
			case .inertiaAndAutoRotation(friction: let friction, speed: let speed):
				viewRotation = ViewRotation(inertiaEnabled: .constant(true), inertiaFriction: .constant(friction), autoRotationEnabled: .constant(true), autoRotationSpeed: .constant(speed))
		}

		return self.modifier(viewRotation)
	}
}

#Preview("Simple Rotation") {
	VStack(alignment: .center) {
		DebugTitleView(title: "Simple View Rotation")

		DebugRectView()
			.padding(.vertical, 40)
			.viewRotation()

		Spacer()
	}
}

#Preview("Only Auto Rotation") {
	@Previewable @State var rotationAngle: Angle = .zero
	@Previewable @State var rotationEnabled: Bool = false
	@Previewable @State var rotationSpeed: Angle = defaultAutoRotationSpeed

	let stepAngle = Angle(degrees: 30)
	let animation: Animation = .default.speed(2)

	VStack(alignment: .center) {
		DebugTitleView(title: "Advanced View Rotation")

		DebugRectView()
			.padding(.vertical, 40)
			.viewRotation(
				rotationAngle: $rotationAngle,
				touchRotationEnabled: .constant(false),
				autoRotationEnabled: $rotationEnabled,
				autoRotationSpeed: $rotationSpeed
			)
			.overlay { DebugAngleOverlayView(angle: $rotationAngle) }

		HStack {
			Button("", systemImage: "minus") {
				withAnimation(animation) {
					rotationAngle -= stepAngle
				}
			}
			.labelStyle(.iconOnly)

			Button("Reset to zero") {
				withAnimation(animation) {
					rotationAngle = .zero
				}
			}
			.disabled(rotationAngle == .zero)

			Button("", systemImage: "plus") {
				withAnimation(animation) {
					rotationAngle += stepAngle
				}
			}
			.labelStyle(.iconOnly)
		}
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.controlSize(.large)

		VStack {
			Toggle("Rotation Enabled", isOn: $rotationEnabled)
			HStack(spacing: 20) {
				Text("Speed")
				Slider(value: $rotationSpeed.degrees, in: -360...360)
				Text("\(rotationSpeed.degrees.formatted(intFloatFormatStyle))")
					.monospacedDigit()
			}
		}
		.padding(.horizontal)

		Spacer()
	}
}

#Preview("Advanced Rotation") {
	@Previewable @State var rotationAngle: Angle = .zero
	@Previewable @State var inertiaEnabled: Bool = true
	@Previewable @State var inertiaFriction: Double = defaultFriction
	@Previewable @State var rotationEnabled: Bool = false
	@Previewable @State var rotationSpeed: Angle = defaultAutoRotationSpeed

	let stepAngle = Angle(degrees: 30)
	let animation: Animation = .default.speed(2)

	VStack(alignment: .center) {
		DebugTitleView(title: "Advanced View Rotation")

		DebugRectView()
			.padding(.vertical, 40)
			.viewRotation(
				rotationAngle: $rotationAngle,
				inertiaEnabled: $inertiaEnabled,
				inertiaFriction: $inertiaFriction,
				autoRotationEnabled: $rotationEnabled,
				autoRotationSpeed: $rotationSpeed
			)
			.overlay { DebugAngleOverlayView(angle: $rotationAngle) }

		HStack {
			Button("", systemImage: "minus") {
				withAnimation(animation) {
					rotationAngle -= stepAngle
				}
			}
			.labelStyle(.iconOnly)

			Button("Reset to zero") {
				withAnimation(animation) {
					rotationAngle = .zero
				}
			}
			.disabled(rotationAngle == .zero)

			Button("", systemImage: "plus") {
				withAnimation(animation) {
					rotationAngle += stepAngle
				}
			}
			.labelStyle(.iconOnly)
		}
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.controlSize(.large)

		VStack {
			Toggle("Inertia Enabled", isOn: $inertiaEnabled)
			HStack(spacing: 20) {
				Text("Friction")
				Slider(value: $inertiaFriction, in: 0...0.2)
				Text("\(inertiaFriction.formatted(.number.precision(.fractionLength(3))))")
					.monospacedDigit()
			}

			Toggle("Rotation Enabled", isOn: $rotationEnabled)
			HStack(spacing: 20) {
				Text("Speed")
				Slider(value: $rotationSpeed.degrees, in: -360...360)
				Text("\(rotationSpeed.degrees.formatted(intFloatFormatStyle))")
					.monospacedDigit()
			}
		}
		.padding(.horizontal)

		Spacer()
	}
}

#Preview("Advanced Knob Rotation") {
	@Previewable @State var rotationAngle: Angle = .zero
	@Previewable @State var inertiaEnabled: Bool = false
	@Previewable @State var inertiaFriction: Double = defaultFriction
	@Previewable @State var rotationEnabled: Bool = false
	@Previewable @State var rotationSpeed: Angle = defaultAutoRotationSpeed

	let stepAngle = Angle(degrees: 30)
	let animation: Animation = .default.speed(2)

	VStack(alignment: .center) {
		DebugTitleView(title: "Advanced Knob Rotation")

		DebugKnobView()
			.padding(.vertical, 40)
			.viewRotation(
				rotationAngle: $rotationAngle,
				knobRange: defaultKnobRange,
				inertiaEnabled: $inertiaEnabled,
				inertiaFriction: $inertiaFriction,
				autoRotationEnabled: $rotationEnabled,
				autoRotationSpeed: $rotationSpeed
			)
			.overlay { DebugAngleOverlayView(angle: $rotationAngle) }

		HStack {
			Button("", systemImage: "minus") {
				withAnimation(animation) {
					rotationAngle -= stepAngle
				}
			}
			.labelStyle(.iconOnly)

			Button("Reset to zero") {
				withAnimation(animation) {
					rotationAngle = .zero
				}
			}
			.disabled(rotationAngle == .zero)

			Button("", systemImage: "plus") {
				withAnimation(animation) {
					rotationAngle += stepAngle
				}
			}
			.labelStyle(.iconOnly)
		}
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.controlSize(.large)

		VStack {
			Toggle("Inertia Enabled", isOn: $inertiaEnabled)
			HStack(spacing: 20) {
				Text("Friction")
				Slider(value: $inertiaFriction, in: 0...0.2)
				Text("\(inertiaFriction.formatted(.number.precision(.fractionLength(3))))")
					.monospacedDigit()
			}

			Toggle("Rotation Enabled", isOn: $rotationEnabled)
			HStack(spacing: 20) {
				Text("Speed")
				Slider(value: $rotationSpeed.degrees, in: -360...360)
				Text("\(rotationSpeed.degrees.formatted(intFloatFormatStyle))")
					.monospacedDigit()
			}
		}
		.padding(.horizontal)

		Spacer()
	}
}
