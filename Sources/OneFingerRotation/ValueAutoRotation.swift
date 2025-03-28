//
//  ValueAutoRotation.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 01/05/23.
//

import SwiftUI

public struct ValueAutoRotation: ViewModifier {
	@State private var rotationAngle: Angle = .zero
	@State private var previousAngle: Angle = .zero
    @State private var animation: Animation?
    @State private var isDragged: Bool = false
	@State private var fullRotations: Int = 0

	@Binding private var totalAngle: Angle

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

    // Add new properties for auto rotation
    @Binding private var autoRotationSpeed: Angle
    @Binding private var autoRotationEnabled: Bool
    @State private var dragJustEnded: Bool = false
    
    public init(
        totalAngle: Binding<Angle>,
        animation: Animation? = nil,
		autoRotationSpeed: Binding<Angle> = .constant(defaultAutoRotationSpeed),
		autoRotationEnabled: Binding<Bool> = .constant(true)
	) {
        self._totalAngle = totalAngle
		self.rotationAngle = totalAngle.wrappedValue
        self.animation = animation
        self._autoRotationSpeed = autoRotationSpeed
        self._autoRotationEnabled = autoRotationEnabled
	}

    public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(rotationAngle, anchor: .center)
			.onChange(of: totalAngle, initial: false) { _, newValue in
				if !isDragged && !dragJustEnded {
					fullRotations = 0
					withAnimation(self.animation) {
						rotationAngle = newValue
					}
				} else if dragJustEnded {
					rotationAngle = newValue
					fullRotations = 0
					dragJustEnded = false
				}
			}
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						isDragged = true

						let dragAngle = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
						let angleDifference = dragAngle - previousAngle

						if angleDifference.degrees > 180 {
							fullRotations -= 1
						} else if angleDifference.degrees < -180 {
							fullRotations += 1
						}

						let currentAngle = rotationAngle + angleDifference
						rotationAngle = currentAngle
						previousAngle = dragAngle

						let totalRotationAngle = currentAngle + (Angle(degrees: 360) * Double(fullRotations))
						totalAngle = totalRotationAngle
					}
					.onEnded { _ in
						previousAngle = .zero
						isDragged = false
						dragJustEnded = true
					}
			)
			.task(id: autoRotationEnabled) {
				if !autoRotationEnabled { return }

				for await timestamp in CADisplayLink.timestamps() {
					if isDragged {
						continue
					}

					let deltaRotation = self.autoRotationSpeed / timestamp.fps
					let newRotation = self.rotationAngle + deltaRotation
					self.rotationAngle = newRotation
					self.totalAngle = newRotation + Angle(degrees: 360 * Double(self.fullRotations))
				}
			}
	}
}

public extension View {
    func valueAutoRotation(
        totalAngle: Binding<Angle>,
        animation: Animation? = nil,
		autoRotationSpeed: Binding<Angle> = .constant(defaultAutoRotationSpeed),
		autoRotationEnabled: Binding<Bool> = .constant(true)
    ) -> some View {
        self.modifier(
            ValueAutoRotation(
                totalAngle: totalAngle,
                animation: animation,
                autoRotationSpeed: autoRotationSpeed,
                autoRotationEnabled: autoRotationEnabled
            )
        )
    }
}

#Preview {
	@Previewable @State var totalAngle: Angle = .zero
	@Previewable @State var rotationSpeed: Angle = defaultAutoRotationSpeed
	@Previewable @State var rotationEnabled: Bool = true

	VStack(alignment: .center) {
		DebugTitleView(title: "AutoRotation with Value")

		DebugRectView()
			.padding(.vertical, 40)
			.valueAutoRotation(totalAngle: $totalAngle, animation: .bouncy.speed(2), autoRotationSpeed: $rotationSpeed, autoRotationEnabled: $rotationEnabled)
			.overlay { DebugAngleOverlayView(angle: $totalAngle) }

		VStack {
			HStack(spacing: 20) {
				Text("Speed")
				Slider(value: $rotationSpeed.degrees, in: -360...360)
				Text("\(rotationSpeed.degrees.formatted(FloatingPointFormatStyle<Double>.number.precision(.integerAndFractionLength(integer: 3, fraction: 2))))")
					.monospacedDigit()
			}

			Stepper("Rotation", value: $totalAngle.degrees, step: 20)

			Toggle("Rotation Enabled", isOn: $rotationEnabled)
		}
		.padding(.horizontal)

		Spacer()
	}
}
