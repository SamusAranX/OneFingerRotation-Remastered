//
//  CADisplayLink+Timestamps.swift
//  OneFingerRotation-Remastered
//
//  Created by Emma Alyx Wunder on 15.03.25.
//

import UIKit

@MainActor
extension CADisplayLink {
	public struct Timestamp: Sendable {
		public let timestamp: TimeInterval
		public let targetTimestamp: TimeInterval
		public let duration: TimeInterval
		public let fps: Double

		init(displayLink: CADisplayLink) {
			self.timestamp = displayLink.timestamp
			self.targetTimestamp = displayLink.targetTimestamp
			self.duration = displayLink.duration
			self.fps = 1.0 / (self.targetTimestamp - self.timestamp)
		}
	}

	public static func timestamps() -> AsyncStream<Timestamp> {
		AsyncStream { continuation in
			let displayLink = DisplayLink { displayLink in
				continuation.yield(Timestamp(displayLink: displayLink))
			}

			continuation.onTermination = { _ in
				Task { await displayLink.stop() }
			}
		}
	}
}

@MainActor
private class DisplayLink: NSObject {
	private var displayLink: CADisplayLink!
	private let handler: (CADisplayLink) -> Void

	init(mode: RunLoop.Mode = .common, handler: @escaping (CADisplayLink) -> Void) {
		self.handler = handler
		super.init()

		self.displayLink = CADisplayLink(target: self, selector: #selector(handle(displayLink:)))
		self.displayLink.preferredFrameRateRange = .default
		self.displayLink.add(to: .main, forMode: mode)
	}

	func stop() {
		self.displayLink.invalidate()
	}

	@objc func handle(displayLink: CADisplayLink) {
		handler(displayLink)
	}
}
