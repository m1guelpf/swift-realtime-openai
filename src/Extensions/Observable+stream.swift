//
//  Observable+stream.swift
//  QizhKit
//
//  Created by Serhii Shevchenko on 27.08.2025.
//  Copyright © 2025 Serhii Shevchenko. All rights reserved.
//

import Foundation
import Observation

/// Extension for `@Observable` classes
/// that want to expose streaming helpers for property changes.
/// It enables convenient methods for streaming property values as they change over time.
///
/// Conforming types gain two main methods:
/// - `stream(_:)`: Produces an `AsyncStream` that emits
/// 	the property's current value immediately,
/// 	and then yields a new value every time the property changes.
/// - `throwingStream(_:, finishOn:)`: Produces an `AsyncThrowingStream` that emits
/// 	property values as above, but can finish early with an error
/// 	when a given predicate signals to stop.
///
/// These helpers leverage Swift's Observation framework and are
/// intended to be called from the main actor. The streams automatically stop emitting
/// when no longer consumed, and are designed for integration with
/// Swift Concurrency's async/await patterns.
///
/// Example usage:
/// ```swift
/// class MyModel: Observable, ObservationStreaming {
///     @Observation var count: Int = 0
/// }
///
/// let model = MyModel()
/// let stream = model.stream(\.count)
/// for await value in stream {
///     // Handle count changes
/// }
/// ```
@available(iOS 17.0, macOS 14.0, *)
extension Observable where Self: AnyObject {
	/// Creates an `AsyncStream` that emits values from the specified key path
	/// on the conforming `@Observable` class.
	/// The stream yields the current value immediately and then emits a new value
	/// each time the observed property changes.
	///
	/// - Parameter keyPath: A key path to the property to observe and emit values for.
	/// - Returns: An `AsyncStream` that produces the property's value on each change
	/// 	(and immediately on start).
	///
	/// - Important: This method must be called from the main actor.
	/// 	The stream automatically stops emitting when no longer consumed.
	///
	/// - Example:
	/// ```swift
	/// let stream = object.stream(\.property)
	/// for await value in stream {
	///     // React to property changes here
	/// }
	/// ```
	@MainActor
	func stream<Value: Sendable>(
		of keyPath: KeyPath<Self, Value>
	) -> AsyncStream<Value> {
		AsyncStream { continuation in
			let task = Task { [weak self] in
				guard let self else {
					continuation.finish()
					return
				}

				let (signal, signalCont) = AsyncStream<Void>.makeStream()
				defer { signalCont.finish() }

				var it = signal.makeAsyncIterator()
				while !Task.isCancelled {
					/// Track access; on change, poke the signal to resume.
					let value = withObservationTracking {
						self[keyPath: keyPath]
					} onChange: {
						signalCont.yield(())
					}

					/// Yield the current value (initial + each change).
					continuation.yield(value)

					/// Wait until something changes.
					_ = await it.next()
				}
			}

			/// Stop work when the consumer is done.
			continuation.onTermination = { _ in task.cancel() }
		}
	}

	/// Creates an `AsyncThrowingStream` that emits values
	/// from the specified key path on the conforming `@Observable` class.
	/// The stream yields the current value immediately and then emits a new value
	/// each time the observed property changes, and can finish early with an error
	/// when the provided predicate returns a non-nil error.
	///
	/// - Parameters:
	///   - keyPath: A key path to the property to observe and emit values for.
	///   - predicate: A closure that takes the current value and returns an `Error`
	///   		if the stream should finish throwing, or `nil` to continue streaming.
	/// - Returns: An `AsyncThrowingStream` that produces the property's value
	/// 		on each change (and immediately on start), and may finish early
	/// 		with an error.
	///
	/// - Important: This method must be called from the main actor.
	/// 		The stream automatically stops emitting when no longer consumed.
	///
	/// - Example:
	/// ```swift
	/// let stream = object.throwingStream(\.property) { value in
	///     if value.shouldStop {
	///         return MyCustomError.stop
	///     }
	///     return nil
	/// }
	/// do {
	///     for try await value in stream {
	///         // React to property changes here
	///     }
	/// } catch {
	///     // Handle the error that finished the stream
	/// }
	/// ```
	@MainActor
	func throwingStream<Value: Sendable>(
		of keyPath: KeyPath<Self, Value>,
		finishOn predicate: @escaping (Value) -> (any Error)?
	) -> AsyncThrowingStream<Value, any Error> {
		AsyncThrowingStream { continuation in
			let task = Task { [weak self] in
				guard let self else {
					continuation.finish()
					return
				}

				let (signal, signalCont) = AsyncStream<Void>.makeStream()
				defer { signalCont.finish() }

				var it = signal.makeAsyncIterator()
				while !Task.isCancelled {
					let value = withObservationTracking {
						self[keyPath: keyPath]
					} onChange: {
						signalCont.yield(())
					}

					continuation.yield(value)
					if let err = predicate(value) {
						continuation.finish(throwing: err)
						return
					}

					_ = await it.next()
				}
			}

			continuation.onTermination = { _ in task.cancel() }
		}
	}
}
