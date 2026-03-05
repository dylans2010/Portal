
import Foundation

class JITFallbackRegistry {

    static let availableStrategies: [any JITFallbackStrategy] = [
        RetryAttachStrategy(),
        PIDRevalidationStrategy(),
        LockdownResetStrategy(),
        DelayedAttachStrategy(),
        iOS_26_4_JIT_Method()
    ]
}
