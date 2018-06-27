
import Foundation

extension URL {

	func accessSecurityScopedResource(_ accessor: (URL) -> Void) {

		let didStartAccessing = startAccessingSecurityScopedResource()

		defer {
			if didStartAccessing {
				stopAccessingSecurityScopedResource()
			}
		}

		accessor(self)
	}
}
