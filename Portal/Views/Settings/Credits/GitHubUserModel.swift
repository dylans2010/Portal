import Foundation

// MARK: - GitHub User Model
struct GitHubUser: Codable {
	let login: String
	let id: Int
	let avatarUrl: String
	let htmlUrl: String
	let name: String?
	let company: String?
	let blog: String?
	let location: String?
	let email: String?
	let bio: String?
	let publicRepos: Int
	let publicGists: Int
	let followers: Int
	let following: Int
	let createdAt: String
	let updatedAt: String
	
	enum CodingKeys: String, CodingKey {
		case login, id, name, company, blog, location, email, bio
		case avatarUrl = "avatar_url"
		case htmlUrl = "html_url"
		case publicRepos = "public_repos"
		case publicGists = "public_gists"
		case followers, following
		case createdAt = "created_at"
		case updatedAt = "updated_at"
	}
}
