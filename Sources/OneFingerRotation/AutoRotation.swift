//
//  AutoRotation.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 30/04/23.
//

import SwiftUI

public struct AutoRotation: ViewModifier {
    /// Variable for general rotationAngle, which calculates the initial angle of the content.
    @State private var rotationAngle: Angle = .zero
	
    /// Variable for the calculation of the gesture Angle
    @GestureState private var gestureRotation: Angle = .zero

	@State private var isDragging: Bool = false

    @Binding private var autoRotationSpeed: Angle
    @Binding private var autoRotationActive: Bool

	/// Stores the size of the modified view.
	@State private var viewSize: CGSize = .zero

    public init(
		rotationAngle: Angle = .zero,
        autoRotationSpeed: Binding<Angle>,
        autoRotationActive: Binding<Bool>
    ) {
        _rotationAngle = State(initialValue: rotationAngle)
        _autoRotationSpeed = autoRotationSpeed
        _autoRotationActive = autoRotationActive
    }

    public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(rotationAngle + gestureRotation, anchor: .center)
			.gesture(
				DragGesture(minimumDistance: 0)
					.updating($gestureRotation) { value, state, _ in
						self.isDragging = true
						state = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
					}
					.onEnded { value in
						self.isDragging = false
						rotationAngle += calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
					}
			)
			.task {
				for await timestamp in CADisplayLink.timestamps() {
					guard autoRotationActive && !self.isDragging else { continue }

					self.rotationAngle += self.autoRotationSpeed / timestamp.fps
				}
			}
    }
}

public extension View {
    func autoRotation(
		rotationAngle: Angle = .zero,
		autoRotationSpeed: Binding<Angle> = .constant(defaultAutoRotationSpeed),
        autoRotationActive: Binding<Bool> = .constant(true)
	) -> some View {
        let effect = AutoRotation(
            rotationAngle: rotationAngle,
            autoRotationSpeed: autoRotationSpeed,
            autoRotationActive: autoRotationActive
        )
        return self.modifier(effect)
    }
}

#Preview {
	@Previewable @State var rotationSpeed: Angle = defaultAutoRotationSpeed
	@Previewable @State var rotationEnabled: Bool = true

	VStack(alignment: .center) {
		DebugTitleView(title: "AutoRotation")

		DebugRectView()
			.padding(.vertical, 40)
			.autoRotation(autoRotationSpeed: $rotationSpeed, autoRotationActive: $rotationEnabled)

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
