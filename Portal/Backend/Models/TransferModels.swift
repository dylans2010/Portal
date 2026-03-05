import Foundation

// MARK: - Transfer State
enum TransferState: Equatable {
    case idle
    case discovering
    case connecting
    case transferring(progress: Double, bytesTransferred: Int64 = 0, totalBytes: Int64 = 0, speed: Double = 0)
    case completed
    case failed(Error)

    static func == (lhs: TransferState, rhs: TransferState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.discovering, .discovering), (.connecting, .connecting), (.completed, .completed):
            return true
        case (.transferring(let p1, _, _, _), .transferring(let p2, _, _, _)):
            return p1 == p2
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Transfer Mode
enum TransferMode {
    case send
    case receive
}
