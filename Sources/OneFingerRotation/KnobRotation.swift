//
//  KnobRotation.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct KnobRotation: ViewModifier {
	@Binding private var knobValue: Double
	
	@State private var rotationAngle: Angle = .zero
	@GestureState private var gestureRotation: Angle = .zero

	@State private var minAngle: Angle
	@State private var maxAngle: Angle
	private var clampRange: ClosedRange<Angle>

	private var animation: Animation?

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero
	
	@State private var isDragging: Bool = false
	@State private var previousAngle: Angle = .zero

	public init(
		knobValue: Binding<Double>,
		minAngle: Angle,
		maxAngle: Angle,
		animation: Animation? = nil
	) {
		self._knobValue = knobValue
		self.minAngle = minAngle
		self.maxAngle = maxAngle
		self.clampRange = minAngle...maxAngle
		self._rotationAngle = .init(initialValue: minAngle + (maxAngle - minAngle) * self.knobValue)
		self.animation = animation
	}
    
    public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(self.rotationAngle, anchor: .center)
			.onChange(of: knobValue, initial: false) { _, _ in
				guard !isDragging else { return }

				withAnimation(self.animation) {
					self.rotationAngle = self.minAngle + (self.maxAngle - self.minAngle) * self.knobValue
				}
			}
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
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
					.onEnded { _ in
						self.isDragging = false
						self.previousAngle = .zero
					}
			)
    }
}

public extension View {
    func knobRotation(
        knobValue: Binding<Double>,
		minAngle: Angle = defaultKnobMinAngle,
		maxAngle: Angle = defaultKnobMaxAngle,
		animation: Animation? = nil
	) -> some View {
		self.modifier(
			KnobRotation(
				knobValue: knobValue,
				minAngle: minAngle,
				maxAngle: maxAngle,
				animation: animation
			)
		)
	}
}
 
#Preview {
	@Previewable @State var knobValue: Double = 0.33

	VStack(alignment: .center) {
		DebugTitleView(title: "KnobRotation")

		DebugKnobView()
			.padding(.vertical, 24)
			.knobRotation(knobValue: $knobValue, animation: .bouncy.speed(2))

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
