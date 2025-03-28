//
//  Comparable+Clamped.swift
//  OneFingerRotation
//
//  Created by Emma Alyx Wunder on 16.03.25.
//

import Foundation

extension Comparable {
	func clamped(to range: Range<Self>) -> Self {
		return min(max(self, range.lowerBound), range.upperBound)
	}

	func clamped(to range: ClosedRange<Self>) -> Self {
		return min(max(self, range.lowerBound), range.upperBound)
	}
}
