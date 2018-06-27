
import Foundation

extension URL {

	func accessSecurityScopedResource<Value>(_ accessor: (URL) throws -> Value) rethrows -> Value {

        if startAccessingSecurityScopedResource() {
            defer {
                stopAccessingSecurityScopedResource()
            }
        }

		return try accessor(self)
	}
}
