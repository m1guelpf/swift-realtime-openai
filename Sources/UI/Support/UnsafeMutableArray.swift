import Foundation

/// An unsafe mutable array that can be accessed from multiple threads.
/// > Warning: Exposing any observable property externally (such as by having a computed property use `isEmpty` will lead to very hard to debug crashes
/// >
/// > If you really need to, manually observe the property using `withObservationTracking` and write changes in the main actor.
@Observable final class UnsafeMutableArray<T: Sendable>: @unchecked Sendable {
	private var array = [T]()

	public var isEmpty: Bool {
		array.isEmpty
	}

	var first: T? {
		array.first
	}

	func push(_ value: T) {
		array.append(value)
	}

	@discardableResult
	func popFirst() -> T? {
		array.removeFirst()
	}

	func clear() {
		array.removeAll()
	}
}
