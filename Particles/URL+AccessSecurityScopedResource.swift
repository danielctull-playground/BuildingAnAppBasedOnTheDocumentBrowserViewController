
import Foundation

extension URL {

	func accessSecurityScopedResource<Value>(_ accessor: (URL) throws -> Value) rethrows -> Value {

		let didStartAccessing = startAccessingSecurityScopedResource()

		defer {
			if didStartAccessing {
				stopAccessingSecurityScopedResource()
			}
		}

		return try accessor(self)
	}
}
