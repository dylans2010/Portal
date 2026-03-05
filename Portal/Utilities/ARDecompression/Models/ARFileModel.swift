import Foundation

struct ARFileModel {
	var name: String
	var modificationDate: Date
	var ownerId: Int
	var groupId: Int
	var mode: Int
	var size: Int
	var content: Data
}
