import SwiftUI
import NimbleViews

// MARK: - iOS 17+ Version
@available(iOS 17.0, *)
struct NearbyShareIntroView: View {
    @AppStorage("hasSeenNearbyShareIntro") var hasSeenNearbyShareIntro: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var selectedDemo: DemoAction? = nil
    
    // MARK: - Header Icon Section
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
    }
    
    // MARK: - Title and Subtitle Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            // Title
            Text("Nearby Share")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
            
            // Subtitle
            Text("New feature on Portal 2.3, use Nearby Share to quickly transfer your backups between devices on the same network.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(spacing: 16) {
            StepRow(
                step: 1,
                icon: "iphone.gen2",
                title: "Open Nearby Share",
                description: "Navigate to Settings, Backup & Restore, Nearby Share tab in Portal to start.",
                delay: 0.2
            )
            
            StepRow(
                step: 2,
                icon: "person.2.fill",
                title: "Select Mode",
                description: "Choose to send or receive apps",
                delay: 0.3
            )
            
            StepRow(
                step: 3,
                icon: "wifi.circle.fill",
                title: "Connect Devices",
                description: "Devices must be on the same network.",
                delay: 0.4
            )
            
            StepRow(
                step: 4,
                icon: "arrow.down.circle.fill",
                title: "Transfer Apps",
                description: "Select apps and start the backup transfer instantly.",
                delay: 0.5
            )
        }
        .padding(.horizontal, 24)
        .opacity(animateContent ? 1.0 : 0.0)
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.yellow)
                Text("Tips")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 8) {
                TipRow(text: "Both devices need Portal 2.3 or later.")
                TipRow(text: "Ensure WiFi is enabled on both devices.")
                TipRow(text: "Keep devices close for better performance.")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .opacity(animateContent ? 1.0 : 0.0)
    }
    
    // MARK: - Button Section
    private var gotItButton: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                hasSeenNearbyShareIntro = true
                UserDefaults.standard.set(true, forKey: "hasSeenNearbyShareIntro")
                UserDefaults.standard.synchronize()
            }
            HapticsManager.shared.success()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text("Got It!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal, 24)
        .scaleEffect(animateButton ? 1.0 : 0.9)
        .opacity(animateButton ? 1.0 : 0.0)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.clear
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Main content
                    VStack(spacing: 32) {
                        headerIcon
                        
                        titleSection
                        
                        stepsSection
                        
                        // Interactive Demo Section (iOS 17+)
                        InteractiveDemoSection(selectedDemo: $selectedDemo)
                            .padding(.horizontal, 24)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        tipsSection
                        
                        gotItButton
                    }
                    .padding(.vertical, 32)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                animateButton = true
            }
        }
    }
}

// MARK: - Step Row Component
@available(iOS 17.0, *)
struct StepRow: View {
    let step: Int
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.purple)
                    .rotationEffect(.degrees(isVisible ? 0 : -10))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Tip Row Component
@available(iOS 17.0, *)
struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - iOS 16 Legacy Version
struct NearbyShareIntroViewLegacy: View {
    @AppStorage("hasSeenNearbyShareIntro") var hasSeenNearbyShareIntro: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var animateButton = false
    
    // MARK: - Header Icon Section
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
    }
    
    // MARK: - Title and Subtitle Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            // Title
            Text("Nearby Share")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
            
            // Subtitle
            Text("With Portal 2.3, use Nearby Share to quickly transfer Portal backups between devices.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(spacing: 16) {
            StepRowLegacy(
                step: 1,
                icon: "iphone.gen2",
                title: "Open Nearby Share",
                description: "Navigate to Settings, Backup & Restore, Nearby Share tab in Portal",
                delay: 0.2
            )
            
            StepRowLegacy(
                step: 2,
                icon: "person.2.fill",
                title: "Select Mode",
                description: "Choose to send or receive the backup.",
                delay: 0.3
            )
            
            StepRowLegacy(
                step: 3,
                icon: "wifi.circle.fill",
                title: "Connect Devices",
                description: "Devices must be on the same network.",
                delay: 0.4
            )
            
            StepRowLegacy(
                step: 4,
                icon: "arrow.down.circle.fill",
                title: "Transfer Apps",
                description: "Select apps and start the transfer instantly.",
                delay: 0.5
            )
        }
        .padding(.horizontal, 24)
        .opacity(animateContent ? 1.0 : 0.0)
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.yellow)
                Text("Tips")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 8) {
                TipRowLegacy(text: "Both devices need Portal 2.3 or later.")
                TipRowLegacy(text: "Ensure WiFi is enabled on both devices.")
                TipRowLegacy(text: "Keep devices close for better performance.")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .opacity(animateContent ? 1.0 : 0.0)
    }
    
    // MARK: - Button Section
    private var gotItButton: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                hasSeenNearbyShareIntro = true
                UserDefaults.standard.set(true, forKey: "hasSeenNearbyShareIntro")
                UserDefaults.standard.synchronize()
            }
            HapticsManager.shared.success()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text("Got It!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal, 24)
        .scaleEffect(animateButton ? 1.0 : 0.9)
        .opacity(animateButton ? 1.0 : 0.0)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.clear
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Main content
                    VStack(spacing: 32) {
                        headerIcon
                        
                        titleSection
                        
                        stepsSection
                        
                        // Simple transfer visualization for iOS 16
                        SimplifiedTransferView()
                            .frame(height: 100)
                            .padding(.horizontal, 24)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        tipsSection
                        
                        gotItButton
                    }
                    .padding(.vertical, 32)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                animateButton = true
            }
        }
    }
}

// MARK: - Step Row Component (Legacy)
struct StepRowLegacy: View {
    let step: Int
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.purple)
                    .rotationEffect(.degrees(isVisible ? 0 : -10))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Tip Row Component (Legacy)
struct TipRowLegacy: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Demo Action Enum
@available(iOS 17.0, *)
enum DemoAction: String, CaseIterable {
    case send = "Send"
    case receive = "Receive"
    case connect = "Connect"
    
    var icon: String {
        switch self {
        case .send: return "arrow.up.circle.fill"
        case .receive: return "arrow.down.circle.fill"
        case .connect: return "wifi.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .send: return "Tap to see send animation"
        case .receive: return "Tap to see receive animation"
        case .connect: return "Tap to see connection animation"
        }
    }
}

// MARK: - Interactive Demo Section
@available(iOS 17.0, *)
struct InteractiveDemoSection: View {
    @Binding var selectedDemo: DemoAction?
    @State private var isAnimating = false
    
    // MARK: - Header Section
    private var headerView: some View {
        HStack {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
            Text("Try It Out")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
    }
    
    // MARK: - Demo Buttons Row
    private var demoButtonsRow: some View {
        HStack(spacing: 12) {
            ForEach(DemoAction.allCases, id: \.self) { action in
                DemoButton(
                    action: action,
                    isSelected: selectedDemo == action,
                    isAnimating: isAnimating && selectedDemo == action
                ) {
                    handleDemoSelection(action)
                }
            }
        }
    }
    
    // MARK: - Description Text
    @ViewBuilder
    private var descriptionText: some View {
        if let demo = selectedDemo {
            Text(demo.description)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .transition(AnyTransition.opacity)
        }
    }
    
    // MARK: - Interactive Transfer Mockup
    @ViewBuilder
    private var transferMockup: some View {
        if let demo = selectedDemo {
            InteractiveTransferView(demoAction: demo, isAnimating: isAnimating)
                .frame(height: 120)
                .transition(AnyTransition.scale.combined(with: .opacity))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            demoButtonsRow
            transferMockup
            descriptionText
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .animation(.easeInOut, value: selectedDemo)
    }
    
    // MARK: - Helper Methods
    private func handleDemoSelection(_ action: DemoAction) {
        selectedDemo = action
        isAnimating = true
        HapticsManager.shared.light()
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isAnimating = false
            selectedDemo = nil
        }
    }
}

// MARK: - Interactive Transfer View
@available(iOS 17.0, *)
struct InteractiveTransferView: View {
    let demoAction: DemoAction
    let isAnimating: Bool
    
    @State private var dataPackets: [DataPacket] = []
    @State private var connectionStrength: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connection line
                if connectionStrength > 0 {
                    connectionLine(in: geometry)
                }
                
                // Data packets animation
                ForEach(dataPackets) { packet in
                    dataPacketView(packet: packet, in: geometry)
                }
                
                // Left device (sender)
                deviceGlyph(position: .leading, in: geometry)
                
                // Right device (receiver)
                deviceGlyph(position: .trailing, in: geometry)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - Connection Line
    private func connectionLine(in geometry: GeometryProxy) -> some View {
        Path { path in
            let startX = geometry.size.width * 0.25
            let endX = geometry.size.width * 0.75
            let midY = geometry.size.height / 2.0
            
            path.move(to: CGPoint(x: startX, y: midY))
            path.addLine(to: CGPoint(x: endX, y: midY))
        }
        .stroke(
            LinearGradient(
                colors: [Color.purple.opacity(connectionStrength), Color.blue.opacity(connectionStrength)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
        )
        .animation(.easeInOut(duration: 0.5), value: connectionStrength)
    }
    
    // MARK: - Device Glyph
    private func deviceGlyph(position: HorizontalAlignment, in geometry: GeometryProxy) -> some View {
        let xPosition = position == .leading ? geometry.size.width * 0.15 : geometry.size.width * 0.85
        let isActive = (position == .leading && demoAction == .send) ||
                      (position == .trailing && demoAction == .receive) ||
                      demoAction == .connect
        
        return VStack(spacing: 4) {
            ZStack {
                // Pulse effect when active
                if isActive && isAnimating {
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .scaleEffect(connectionStrength * 1.5)
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isActive ? [Color.purple.opacity(0.8), Color.blue.opacity(0.8)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(position == .leading ? "Device 1" : "Device 2")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .position(x: xPosition, y: geometry.size.height / 2.0)
    }
    
    // MARK: - Data Packet View
    private func dataPacketView(packet: DataPacket, in geometry: GeometryProxy) -> some View {
        let startX = geometry.size.width * 0.25
        let endX = geometry.size.width * 0.75
        let xPosition = startX + (endX - startX) * packet.progress
        
        return Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 8, height: 8)
            .position(x: xPosition, y: geometry.size.height / 2.0)
            .opacity(1.0 - packet.progress)
    }
    
    // MARK: - Animation Logic
    private func startAnimation() {
        dataPackets.removeAll()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            connectionStrength = 1.0
        }
        
        // Create data packets at intervals
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let newPacket = DataPacket()
            dataPackets.append(newPacket)
            
            // Animate packet
            withAnimation(.linear(duration: 1.5)) {
                if let index = dataPackets.firstIndex(where: { $0.id == newPacket.id }) {
                    dataPackets[index].progress = 1.0
                }
            }
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dataPackets.removeAll { $0.id == newPacket.id }
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            connectionStrength = 0
            dataPackets.removeAll()
        }
    }
}

// MARK: - Data Packet Model
@available(iOS 17.0, *)
struct DataPacket: Identifiable {
    let id = UUID()
    var progress: Double = 0
}

// MARK: - Demo Button
@available(iOS 17.0, *)
struct DemoButton: View {
    let action: DemoAction
    let isSelected: Bool
    let isAnimating: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.blue)
                        .bounceEffect(isAnimating)
                }
                
                Text(action.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simplified Transfer View (iOS 16)
struct SimplifiedTransferView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connection line
                Path { path in
                    let startX = geometry.size.width * 0.25
                    let endX = geometry.size.width * 0.75
                    let midY = geometry.size.height / 2.0
                    
                    path.move(to: CGPoint(x: startX, y: midY))
                    path.addLine(to: CGPoint(x: endX, y: midY))
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
                )
                
                // Left device
                deviceView(position: .leading, in: geometry)
                
                // Right device
                deviceView(position: .trailing, in: geometry)
                
                // Transfer arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func deviceView(position: HorizontalAlignment, in geometry: GeometryProxy) -> some View {
        let xPosition = position == .leading ? geometry.size.width * 0.15 : geometry.size.width * 0.85
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(position == .leading ? "Device 1" : "Device 2")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .position(x: xPosition, y: geometry.size.height / 2.0)
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    NearbyShareIntroView()
}

