//
//  DebugTools.swift
//  OneFingerRotation-Remastered
//
//  Created by Emma Alyx Wunder on 28.03.25.
//

import SwiftUI

private let dark = Color(white: 0.4)
private let light = Color(white: 0.95)
let debugGradient = AngularGradient(
	colors: [
		light,
		dark,
		light,
		dark,
		light,
		dark,
		light,
		dark,
		light,
	],
	center: .center,
	startAngle: .degrees(-90),
	endAngle: .degrees(270)
)

struct DebugTitleView: View {
	@State var title: String

    var body: some View {
		Text(self.title)
			.font(.title)
			.fontWeight(.bold)
			.fontWidth(.compressed)
			.multilineTextAlignment(.center)
			.padding()
			.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct DebugRectView: View {
	var body: some View {
		RoundedRectangle(cornerRadius: 70)
			.fill(debugGradient)
			.aspectRatio(1, contentMode: .fit)
			.frame(height: 300)
	}
}

struct DebugKnobView: View {
	var body: some View {
		ZStack {
			Circle()
				.fill(debugGradient)

			Image(systemName: "triangle")
				.offset(y: -110)
				.font(.largeTitle)
				.symbolVariant(.fill)
				.foregroundStyle(.black.opacity(0.85).shadow(.inner(color: .black, radius: 2)))
				.shadow(color: .white, radius: 1, y: 1)
				.blendMode(.hardLight)
		}
		.aspectRatio(1, contentMode: .fit)
		.frame(height: 300)
	}
}

struct DebugAngleOverlayView: View {
	@Binding var angle: Angle

	var body: some View {
		Text("\(self.angle.degrees.formatted(floatFormatStyle))°")
			.monospacedDigit()
			.bold()
			.padding()
			.background(.ultraThinMaterial, in: Capsule(style: .continuous))
			.allowsHitTesting(false)
	}
}

#Preview("Rectangle") {
	VStack(spacing: 24) {
		DebugTitleView(title: "Rectangle")

		DebugRectView()
			.overlay { DebugAngleOverlayView(angle: .constant(.degrees(180))) }

		Spacer()
	}
}

#Preview("Knob") {
	VStack(spacing: 24) {
		DebugTitleView(title: "Knob")

		DebugKnobView()
			.overlay { DebugAngleOverlayView(angle: .constant(.degrees(180))) }

		Spacer()
	}
}
