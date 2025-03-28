//
//  SimpleRotation.swift
//  OneFingerRotation
//
//  Created by Matteo Fontana on 23/04/23.
//

import SwiftUI

public struct SimpleRotation: ViewModifier {
    @State private var rotationAngle: Angle = .zero
    @GestureState private var gestureRotation: Angle = .zero

	private var totalAngle: Angle {
		self.rotationAngle + self.gestureRotation
	}

	// TODO: implement angleSnap

    @Binding private var angleSnap: Double?
    
    /// Stores the size of the modified view.
    @State private var viewSize: CGSize = .zero
    
    public init(rotationAngle: Angle = .zero, angleSnap: Binding<Double?> = .constant(nil)) {
		self._rotationAngle = State(initialValue: rotationAngle)
		self._angleSnap = angleSnap
    }
    
	public func body(content: Content) -> some View {
		content
			.onGeometryChange(for: CGSize.self) { $0.size } action: { self.viewSize = $0 }
			.rotationEffect(self.totalAngle, anchor: .center)
			.gesture(
				DragGesture(minimumDistance: 0)
					.updating($gestureRotation) { value, state, _ in
						state = calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
					}
					.onEnded { value in
						rotationAngle += calculateGestureRotationAngle(for: value, viewSize: self.viewSize)
					}
			)
	}
}

public extension View {
	func simpleRotation(
		rotationAngle: Angle = .zero,
		angleSnap: Binding<Double?> = .constant(nil)
	) -> some View {
		let effect = SimpleRotation(
			rotationAngle: rotationAngle,
            angleSnap: angleSnap
        )
        return self.modifier(effect)
    }
}

#Preview {
	VStack(alignment: .center) {
		DebugTitleView(title: "SimpleRotation")

		DebugRectView()
			.padding(.vertical, 40)
			.simpleRotation()

		Spacer()
	}
}
