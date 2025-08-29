final class UnsafeInteriorMutable<T: Sendable>: @unchecked Sendable {
	private var value: T?

	func set(_ value: T) {
		self.value = value
	}

	func get() -> T? {
		return value
	}

	func lazy(_ closure: () -> T?) -> T? {
		if case let .some(wrapped) = value {
			return wrapped
		}

		if let newValue = closure() {
			value = newValue
			return newValue
		}

		return nil
	}
}
