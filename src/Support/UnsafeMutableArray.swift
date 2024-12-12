import Foundation

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
