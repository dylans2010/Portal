import Foundation
import Combine
import UIKit
import ActivityKit

// oh no, UIKit
// MARK: - Download Errors
enum DownloadError: LocalizedError {
	case invalidFileFormat(String)
	case downloadFailed(String)
	case networkError(String)
	case fileSystemError(String)
	
	var errorDescription: String? {
		switch self {
		case .invalidFileFormat(let message):
			return message
		case .downloadFailed(let message):
			return message
		case .networkError(let message):
			return message
		case .fileSystemError(let message):
			return message
		}
	}
}

class Download: Identifiable, @unchecked Sendable {
	@Published var progress: Double = 0.0
	@Published var bytesDownloaded: Int64 = 0
	@Published var totalBytes: Int64 = 0
	@Published var unpackageProgress: Double = 0.0
	
	var overallProgress: Double {
		onlyArchiving
		? unpackageProgress
		: (0.3 * unpackageProgress) + (0.7 * progress)
	}
	
    var task: URLSessionDownloadTask?
    var resumeData: Data?
	
	let id: String
	let url: URL
	let fileName: String
	let onlyArchiving: Bool
	let fromSourcesView: Bool  // Track if download is from Sources view
	var liveActivityStarted: Bool = false  // Track if Live Activity was started for this download
    
    init(
		id: String,
		url: URL,
		onlyArchiving: Bool = false,
		fromSourcesView: Bool = false
	) {
		self.id = id
        self.url = url
		self.onlyArchiving = onlyArchiving
		self.fromSourcesView = fromSourcesView
        self.fileName = url.lastPathComponent
    }
}

class DownloadManager: NSObject, ObservableObject {
	static let shared = DownloadManager()
	
    @Published var downloads: [Download] = []
	
	var manualDownloads: [Download] {
		downloads.filter { isManualDownload($0.id) }
	}
	
    private var _session: URLSession!
    
    private func _updateBackgroundAudioState() {
        if !downloads.isEmpty {
            BackgroundAudioManager.shared.start()
        } else  {
            BackgroundAudioManager.shared.stop()
        }
    }
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        _session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func startDownload(
		from url: URL,
		id: String = UUID().uuidString,
		fromSourcesView: Bool = false
	) -> Download {
        AppLogManager.shared.info("Starting download: \(url.lastPathComponent) (ID: \(id))", category: "Download")
        if let existingDownload = downloads.first(where: { $0.url == url }) {
            AppLogManager.shared.info("Resuming existing download: \(url.lastPathComponent)", category: "Download")
            resumeDownload(existingDownload)
            return existingDownload
        }
        
		let download = Download(id: id, url: url, fromSourcesView: fromSourcesView)
        
        let task = _session.downloadTask(with: url)
        download.task = task
        task.resume()
        
        downloads.append(download)
        _updateBackgroundAudioState()
		
		// Start Live Activity if enabled
		if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
			let appName = url.deletingPathExtension().lastPathComponent
			LiveActivityManager.shared.startActivity(appName: appName, bundleId: "unknown", appVersion: nil)
			download.liveActivityStarted = true
		}
		
        return download
    }
	
	func startArchive(
		from url: URL,
		id: String = UUID().uuidString
	) -> Download {
		let download = Download(id: id, url: url, onlyArchiving: true)
		downloads.append(download)
        _updateBackgroundAudioState()
		return download
	}
    
    func resumeDownload(_ download: Download) {
        if let resumeData = download.resumeData {
            let task = _session.downloadTask(withResumeData: resumeData)
            download.task = task
            task.resume()
            _updateBackgroundAudioState()
        } else if let url = download.task?.originalRequest?.url {
            let task = _session.downloadTask(with: url)
            download.task = task
            task.resume()
            _updateBackgroundAudioState()
        }
    }
    
    func cancelDownload(_ download: Download) {
        AppLogManager.shared.info("Cancelling download: \(download.fileName)", category: "Download")
        download.task?.cancel()
        
		// End Live Activity if started
		if #available(iOS 16.2, *), download.liveActivityStarted {
			LiveActivityManager.shared.endActivityWithCancellation()
		}
		
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads.remove(at: index)
            _updateBackgroundAudioState()
        }
    }
    
	func isManualDownload(_ string: String) -> Bool {
		return string.contains("FeatherManualDownload")
	}
	
	func getDownload(by id: String) -> Download? {
		return downloads.first(where: { $0.id == id })
	}
	
	func getDownloadIndex(by id: String) -> Int? {
		return downloads.firstIndex(where: { $0.id == id })
	}
	
	func getDownloadTask(by task: URLSessionDownloadTask) -> Download? {
		return downloads.first(where: { $0.task == task })
	}
}

extension DownloadManager: URLSessionDownloadDelegate {
	
	// Notification names for import status
	static let importDidSucceedNotification = Notification.Name("Feather.importDidSucceed")
	static let importDidFailNotification = Notification.Name("Feather.importDidFail")
	static let downloadDidStartNotification = Notification.Name("Feather.downloadDidStart")
	static let downloadDidProgressNotification = Notification.Name("Feather.downloadDidProgress")
	static let downloadDidFailNotification = Notification.Name("Feather.downloadDidFail")
	
	func handlePachageFile(url: URL, dl: Download) throws {
		// ALWAYS show Install/Modify popup after successful download
		let appName = url.deletingPathExtension().lastPathComponent
		
		// Update Live Activity to installing state
		if #available(iOS 16.2, *), dl.liveActivityStarted {
			Task {
				await LiveActivityManager.shared.updateActivity(
					progress: dl.progress,
					bytesDownloaded: dl.bytesDownloaded,
					totalBytes: dl.totalBytes,
					status: .installing,
					timeRemaining: nil,
					speed: nil
				)
			}
		}
		
		FR.handlePackageFile(url, download: dl) { err in
			if err != nil {
				HapticsManager.shared.error()
				AppLogManager.shared.error("Failed to handle package file: \(err?.localizedDescription ?? "Unknown error")", category: "Download", errorCode: .INVALID_IPA)
				
				// End Live Activity with error
				if #available(iOS 16.2, *), dl.liveActivityStarted {
					LiveActivityManager.shared.endActivityWithError()
				}
				
				DispatchQueue.main.async {
					// Post failure notification
					NotificationCenter.default.post(
						name: DownloadManager.importDidFailNotification,
						object: nil,
						userInfo: ["appName": appName, "error": err?.localizedDescription ?? "Unknown error", "downloadId": dl.id]
					)
					
					UIAlertController.showAlertWithOk(
						title: .localized("Download Error"),
						message: err?.localizedDescription ?? "Unknown error"
					)
				}
			} else {
				HapticsManager.shared.success()
				AppLogManager.shared.success("Successfully handled package file: \(url.lastPathComponent)", category: "Download", errorCode: .IMPORT_SUCCESS)
				
				// End Live Activity with success
				if #available(iOS 16.2, *), dl.liveActivityStarted {
					LiveActivityManager.shared.endActivityWithSuccess()
				}
				
				// Success - send notification if enabled
				if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
					NotificationManager.shared.sendAppSignedNotification(appName: appName)
				}
				
				DispatchQueue.main.async {
					// Post success notification
					NotificationCenter.default.post(
						name: DownloadManager.importDidSucceedNotification,
						object: nil,
						userInfo: ["appName": appName, "downloadId": dl.id]
					)
					
				}
			}
			
			DispatchQueue.main.async {
				if let index = DownloadManager.shared.getDownloadIndex(by: dl.id) {
					DownloadManager.shared.downloads.remove(at: index)
					self._updateBackgroundAudioState()
				}
			}
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let download = getDownloadTask(by: downloadTask) else { return }
		
		let tempDirectory = FileManager.default.temporaryDirectory
		let customTempDir = tempDirectory.appendingPathComponent("FeatherDownloads", isDirectory: true)
		let appName = download.fileName.replacingOccurrences(of: ".ipa", with: "").replacingOccurrences(of: ".tipa", with: "")
		
		do {
			try FileManager.default.createDirectoryIfNeeded(at: customTempDir)
			
			// Use the server-suggested filename if available, otherwise fallback
			var suggestedFileName = downloadTask.response?.suggestedFilename ?? download.fileName
			
			// Ensure the file has a valid extension for IPA/TIPA handling
			let suggestedExtension = (suggestedFileName as NSString).pathExtension.lowercased()
			if suggestedExtension != "ipa" && suggestedExtension != "tipa" {
				// Check if it might be a zip file (IPAs are just renamed zips)
				// Try to add .ipa extension if missing
				if suggestedExtension.isEmpty || suggestedExtension == "zip" {
					suggestedFileName = (suggestedFileName as NSString).deletingPathExtension + ".ipa"
					AppLogManager.shared.info("Added .ipa extension to downloaded file: \(suggestedFileName)", category: "Download")
				} else {
					// Unknown extension - still try to process as IPA
					AppLogManager.shared.warning("Downloaded file has unexpected extension '\(suggestedExtension)', attempting to process anyway", category: "Download")
				}
			}
			
			let destinationURL = customTempDir.appendingPathComponent(suggestedFileName)
			
			try FileManager.default.removeFileIfNeeded(at: destinationURL)
			try FileManager.default.moveItem(at: location, to: destinationURL)
			
			// Validate file is a valid ZIP archive (IPA files are ZIP archives)
			if !validateZipArchive(at: destinationURL) {
				throw DownloadError.invalidFileFormat("Downloaded file is not a valid IPA/TIPA archive")
			}
			
			try handlePachageFile(url: destinationURL, dl: download)
		} catch {
			let errorMessage: String
			if let downloadError = error as? DownloadError {
				errorMessage = downloadError.localizedDescription
			} else {
				errorMessage = error.localizedDescription
			}
			
			AppLogManager.shared.error("Error handling downloaded file: \(errorMessage)", category: "Download", errorCode: .INVALID_IPA)
			
			// Post failure notification for manual downloads
			if isManualDownload(download.id) {
				DispatchQueue.main.async {
					HapticsManager.shared.error()
					NotificationCenter.default.post(
						name: DownloadManager.importDidFailNotification,
						object: nil,
						userInfo: ["appName": appName, "error": errorMessage, "downloadId": download.id]
					)
					
					if let index = self.getDownloadIndex(by: download.id) {
						self.downloads.remove(at: index)
						self._updateBackgroundAudioState()
					}
				}
			}
		}
	}
	
	/// Validate that the file at the given URL is a valid ZIP archive
	private func validateZipArchive(at url: URL) -> Bool {
		guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
			return false
		}
		defer { try? fileHandle.close() }
		
		// ZIP files start with "PK" (0x50 0x4B)
		guard let data = try? fileHandle.read(upToCount: 4), data.count >= 2 else {
			return false
		}
		
		return data[0] == 0x50 && data[1] == 0x4B
	}
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let download = getDownloadTask(by: downloadTask) else { return }
        
        DispatchQueue.main.async {
            download.progress = totalBytesExpectedToWrite > 0
			? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
			: 0
            download.bytesDownloaded = totalBytesWritten
            download.totalBytes = totalBytesExpectedToWrite
			
			// Update Live Activity if started
			if #available(iOS 16.2, *), download.liveActivityStarted {
				let speed = bytesWritten > 0 ? Double(bytesWritten) : nil
				let timeRemaining = speed != nil && speed! > 0
					? TimeInterval(Double(totalBytesExpectedToWrite - totalBytesWritten) / speed!)
					: nil
				
				Task {
					await LiveActivityManager.shared.updateActivity(
						progress: download.progress,
						bytesDownloaded: totalBytesWritten,
						totalBytes: totalBytesExpectedToWrite,
						status: .downloading,
						timeRemaining: timeRemaining,
						speed: speed
					)
				}
			}
			
			// Post progress notification for manual downloads
			if self.isManualDownload(download.id) {
				NotificationCenter.default.post(
					name: DownloadManager.downloadDidProgressNotification,
					object: nil,
					userInfo: [
						"downloadId": download.id,
						"progress": download.overallProgress,
						"bytesDownloaded": totalBytesWritten,
						"totalBytes": totalBytesExpectedToWrite
					]
				)
			}
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let downloadTask = task as? URLSessionDownloadTask,
			  let download = getDownloadTask(by: downloadTask)
		else {
			return
		}
		
		// If there's an error, handle it
		if let error = error {
			let appName = download.fileName.replacingOccurrences(of: ".ipa", with: "").replacingOccurrences(of: ".tipa", with: "")
			AppLogManager.shared.error("Download Failed: \(error.localizedDescription)", category: "Download", errorCode: .DOWNLOAD_FAILED)
			
			// End Live Activity with error
			if #available(iOS 16.2, *), download.liveActivityStarted {
				LiveActivityManager.shared.endActivityWithError()
			}
			
			// Post failure notification for manual downloads
			if isManualDownload(download.id) {
				DispatchQueue.main.async {
					HapticsManager.shared.error()
					NotificationCenter.default.post(
						name: DownloadManager.downloadDidFailNotification,
						object: nil,
						userInfo: ["appName": appName, "error": error.localizedDescription, "downloadId": download.id]
					)
				}
			}
		}
		
		DispatchQueue.main.async {
			if let index = self.getDownloadIndex(by: download.id) {
				self.downloads.remove(at: index)
				self._updateBackgroundAudioState()
			}
		}
    }
}
