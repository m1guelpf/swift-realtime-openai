package func tap<T>(_ value: T, _ block: (T) -> Void) -> T {
	block(value)
	return value
}
