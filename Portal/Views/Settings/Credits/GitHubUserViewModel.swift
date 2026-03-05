import Foundation
import SwiftUI
import NimbleJSON

// MARK: - GitHub User View Model
@MainActor
class GitHubUserViewModel: ObservableObject {
	@Published var user: GitHubUser?
	@Published var avatarImage: UIImage?
	@Published var isLoading = false
	@Published var error: String?
	
	private let fetchService = NBFetchService()
	
	func fetchUser(username: String) {
		isLoading = true
		error = nil
		
		let urlString = "https://api.github.com/users/\(username)"
		
		fetchService.fetch(from: urlString) { [weak self] (result: Result<GitHubUser, Error>) in
			Task { @MainActor in
				guard let self = self else { return }
				self.isLoading = false
				
				switch result {
				case .success(let user):
					self.user = user
					self.fetchAvatar(from: user.avatarUrl)
				case .failure(let error):
					self.error = error.localizedDescription
				}
			}
		}
	}
	
	private func fetchAvatar(from urlString: String) {
		guard let url = URL(string: urlString) else { return }
		
		// Use URLSession for async network request
		let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
			guard let self = self,
				  let data = data,
				  error == nil,
				  let image = UIImage(data: data) else {
				return
			}
			
			Task { @MainActor in
				self.avatarImage = image
			}
		}
		task.resume()
	}
}
