import CoreMotion
import Combine

class MotionManager: ObservableObject {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()

    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0

    private var timer: Timer?
    private var referenceCount = 0

    private init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    }

    func start() {
        referenceCount += 1
        guard timer == nil else { return }

        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()

            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                if let data = self?.motionManager.deviceMotion {
                    self?.pitch = data.attitude.pitch
                    self?.roll = data.attitude.roll
                    self?.yaw = data.attitude.yaw
                }
            }
        }
    }

    func stop() {
        referenceCount -= 1
        if referenceCount <= 0 {
            referenceCount = 0
            motionManager.stopDeviceMotionUpdates()
            timer?.invalidate()
            timer = nil
        }
    }
}
