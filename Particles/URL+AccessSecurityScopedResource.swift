
import Foundation

extension URL {

	func accessSecurityScopedResource<Value>(_ accessor: (URL) -> Value) -> Value {

		let didStartAccessing = startAccessingSecurityScopedResource()

		defer {
			if didStartAccessing {
				stopAccessingSecurityScopedResource()
			}
		}

		return accessor(self)
	}
}
