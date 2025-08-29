import Foundation

package extension Result {
	init(catching body: () async throws(Failure) -> Success) async {
		do { self = try .success(await body()) }
		catch { self = .failure(error) }
	}
}
