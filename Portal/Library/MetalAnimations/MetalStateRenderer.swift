import MetalKit
import SwiftUI

class MetalStateRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?

    private var startTime: CFTimeInterval = 0
    private var stateStartTime: CFTimeInterval = 0
    private var currentState: MetalAnimationState = .idle

    var onAnimationComplete: (() -> Void)?

    struct Uniforms {
        var time: Float
        var state: Int32
        var stateTime: Float
        var resolution: SIMD2<Float>
        var pitch: Float
        var roll: Float
        var yaw: Float
    }

    override init() {
        super.init()
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        self.startTime = CACurrentMediaTime()
        setupPipeline()
        MotionManager.shared.start()
    }

    deinit {
        MotionManager.shared.stop()
    }

    private func setupPipeline() {
        guard let device = device else { return }

        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }

    func updateState(_ state: MetalAnimationState) {
        if currentState != state {
            currentState = state
            stateStartTime = CACurrentMediaTime()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard currentState != .idle else { return }

        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue?.makeCommandBuffer() else { return }

        let currentTime = CACurrentMediaTime()
        let time = Float(currentTime - startTime)
        let stateTime = Float(currentTime - stateStartTime)

        // Handle auto-dismiss
        if currentState == .success && stateTime > 2.0 {
            onAnimationComplete?()
            return
        }

        // Error state auto-dismiss after delay
        if currentState == .error && stateTime > 2.4 {
            // We can optionally auto-dismiss here, but let's keep it manual for now as per requirement "allow manual dismissal"
        }

        let resolution = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))

        var uniforms = Uniforms(
            time: time,
            state: Int32(currentState.rawValue),
            stateTime: stateTime,
            resolution: resolution,
            pitch: Float(MotionManager.shared.pitch),
            roll: Float(MotionManager.shared.roll),
            yaw: Float(MotionManager.shared.yaw)
        )

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder?.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
