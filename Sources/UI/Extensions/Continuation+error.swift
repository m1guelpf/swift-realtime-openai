import Foundation

extension AsyncThrowingStream.Continuation where Failure == any Error {
	func yield(error: Failure) {
		yield(with: Result.failure(error))
	}
}
