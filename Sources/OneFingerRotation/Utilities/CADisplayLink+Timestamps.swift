//
//  CADisplayLink+Timestamps.swift
//  OneFingerRotation
//
//  Created by Emma Alyx Wunder on 15.03.25.
//

import UIKit

@MainActor
extension CADisplayLink {
	static func timestamps() -> AsyncStream<Timestamps> {
		AsyncStream { continuation in
			let displayLink = DisplayLink { displayLink in
				continuation.yield(.init(displayLink: displayLink))
			}

			continuation.onTermination = { _ in
				Task { await displayLink.stop() }
			}
		}
	}
}

extension CADisplayLink {
	struct Timestamps {
		let timestamp: TimeInterval
		let targetTimestamp: TimeInterval
		let duration: TimeInterval

		var fps: Double {
			1.0 / self.duration
		}

		init(displayLink: CADisplayLink) {
			self.timestamp = displayLink.timestamp
			self.targetTimestamp = displayLink.targetTimestamp
			self.duration = displayLink.duration
		}
	}
}

@MainActor
private class DisplayLink: NSObject {
	private var displayLink: CADisplayLink!
	private let handler: (CADisplayLink) -> Void

	init(mode: RunLoop.Mode = .default, handler: @escaping (CADisplayLink) -> Void) {
		self.handler = handler
		super.init()

		self.displayLink = CADisplayLink(target: self, selector: #selector(handle(displayLink:)))
		self.displayLink.preferredFrameRateRange = .init(minimum: 30, maximum: 120, preferred: 120)
		self.displayLink.add(to: .main, forMode: mode)
	}

	func stop() {
		self.displayLink.invalidate()
	}

	@objc func handle(displayLink: CADisplayLink) {
		handler(displayLink)
	}
}
