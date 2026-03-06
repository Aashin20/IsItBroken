//
//  PalpationTestScreen.swift
//  IsItBroken?
//
//  Created for Swift Student Challenge
//

import SwiftUI
import RealityKit
import Combine

// MARK: - Design System

extension Color {
    static let appBG           = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let ink             = Color(red: 0.08, green: 0.10, blue: 0.18)
    static let inkSecondary    = Color(red: 0.42, green: 0.44, blue: 0.52)
    static let teal            = Color(red: 0.05, green: 0.58, blue: 0.60)
    static let tealLight       = Color(red: 0.05, green: 0.58, blue: 0.60).opacity(0.10)
    static let modelBG         = Color(red: 0.91, green: 0.93, blue: 0.96)
    static let card            = Color.white
    static let painRed         = Color(red: 0.92, green: 0.24, blue: 0.24)
    static let painRedLight    = Color(red: 0.92, green: 0.24, blue: 0.24).opacity(0.10)
    static let clearGreen      = Color(red: 0.16, green: 0.70, blue: 0.50)
    static let clearGreenLight = Color(red: 0.16, green: 0.70, blue: 0.50).opacity(0.10)
    static let divider         = Color(red: 0.88, green: 0.89, blue: 0.92)
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct PalpationZone: Identifiable {
    let id = UUID()
    let name: String
    let shortName: String
    let instruction: String
    let anatomyNote: String
    let markerPosition: SIMD3<Float>
    let icon: String
}

let palpationZones: [PalpationZone] = [
    PalpationZone(name: "Lateral Malleolus", shortName: "Outer Ankle",
                  instruction: "Press firmly on the back edge of the bony bump on the outside of your ankle.",
                  anatomyNote: "Posterior edge, distal 6 cm",
                  markerPosition: [0.05, 0.01, -0.04], icon: "arrow.right.circle.fill"),
    PalpationZone(name: "Medial Malleolus", shortName: "Inner Ankle",
                  instruction: "Press firmly on the back edge of the bony bump on the inside of your ankle.",
                  anatomyNote: "Posterior edge, distal 6 cm",
                  markerPosition: [-0.04, 0.01, -0.05], icon: "arrow.left.circle.fill"),
    PalpationZone(name: "5th Metatarsal Base", shortName: "Outer Mid-Foot",
                  instruction: "Press on the bony prominence on the outer edge of your mid-foot.",
                  anatomyNote: "Proximal base of 5th metatarsal",
                  markerPosition: [0.06, -0.08, 0.13], icon: "arrow.down.right.circle.fill"),
    PalpationZone(name: "Navicular Bone", shortName: "Inner Mid-Foot",
                  instruction: "Press on the bony ridge along the inner arch of your foot.",
                  anatomyNote: "Proximal navicular",
                  markerPosition: [-0.04, -0.05, 0.10], icon: "arrow.down.left.circle.fill"),
]

// MARK: - AR Manager

final class FootARManager: ObservableObject {
    let arView: ARView
    private var wrapper: ModelEntity?
    private var modelAnchor = AnchorEntity(world: .zero)
    private var isSetUp = false
    private var currentScale: Float = 1.0
    @Published private(set) var isLoaded = false
    
    private var pulseTimer: AnyCancellable?
    private var pulsePhase: Float = 0.0

    init() {
        arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1))
    }

    func setupIfNeeded() {
        guard !isSetUp else { return }
        isSetUp = true; setupScene(); setupGestures(); loadModel()
    }

    private func setupScene() {
        let key = DirectionalLight(); key.light.color = .white; key.light.intensity = 2200
        key.shadow = .init(maximumDistance: 2, depthBias: 1.5)
        let fill = DirectionalLight(); fill.light.color = UIColor(red: 1, green: 0.95, blue: 0.88, alpha: 1); fill.light.intensity = 900
        let rim = DirectionalLight(); rim.light.color = UIColor(red: 0.65, green: 0.85, blue: 1, alpha: 1); rim.light.intensity = 700
        [([1, 2, 1.5] as [Float], key), ([-1.5, -0.5, 0.5], fill), ([0, 0.5, -2], rim)].forEach { pos, light in
            let a = AnchorEntity(world: SIMD3<Float>(pos[0], pos[1], pos[2])); a.addChild(light); arView.scene.addAnchor(a)
        }
        let cam = PerspectiveCamera(); cam.camera.fieldOfViewInDegrees = 45
        let ca = AnchorEntity(world: .zero); ca.addChild(cam); arView.scene.addAnchor(ca)
        modelAnchor.name = "FootAnchor"; arView.scene.addAnchor(modelAnchor)
    }

    private func setupGestures() {
        arView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        arView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
    }

    private func loadModel() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let loaded = try? await Entity(named: "Foot2") {
                let c = ModelEntity(); c.addChild(loaded); modelAnchor.addChild(c); wrapper = c
                try? await Task.sleep(nanoseconds: 50_000_000)
                autoFit(c); isLoaded = true; updateMarker(zoneIndex: 0)
            }
        }
    }

    func updateMarker(zoneIndex: Int) {
            guard isLoaded, zoneIndex < palpationZones.count, let wrapper else { return }
            
            pulseTimer?.cancel()
            wrapper.children.filter { $0.name.contains("Highlight") }.forEach { $0.removeFromParent() }
            
            let zone = palpationZones[zoneIndex]
            let baseRadius: Float = 0.015
            
            let brightRed = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            
            var initialGlowMat = UnlitMaterial(color: brightRed)
            initialGlowMat.blending = .transparent(opacity: .init(floatLiteral: 0.0))
            
            let ring = ModelEntity(mesh: .generateSphere(radius: baseRadius), materials: [initialGlowMat])
            ring.name = "HighlightGlow"
            ring.position = zone.markerPosition
            wrapper.addChild(ring)
            
            pulsePhase = 0.0
            pulseTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self, weak wrapper] _ in
                    guard let self, let wrapper else { return }
                    
                    self.pulsePhase += 1.0 / (1.5 * 60.0)
                    if self.pulsePhase > 1.0 { self.pulsePhase -= 1.0 }
                    
                    guard let ring = wrapper.findEntity(named: "HighlightGlow") as? ModelEntity else { return }
                    
                    let t = self.pulsePhase
                    let easeOutT = 1.0 - pow(1.0 - t, 3.0)
                    
                    ring.scale = SIMD3<Float>(repeating: Float(1.0 + 2.0 * easeOutT))
                    
                    let alphaValue = Float(1.0 - pow(t, 1.5))
                    
                    var glowMat = UnlitMaterial(color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: CGFloat(alphaValue)))
                    glowMat.blending = .transparent(opacity: .init(floatLiteral: alphaValue))
                    
                    ring.model?.materials = [glowMat]
                }
        }
    func stopPulse() { pulseTimer?.cancel() }

    private func autoFit(_ entity: Entity) {
        let b = entity.visualBounds(relativeTo: modelAnchor)
        let m = max(b.extents.x, b.extents.y, b.extents.z)
        guard m > 0 else { return }
        entity.position -= (b.max + b.min) * 0.5
        entity.scale = SIMD3<Float>(repeating: 0.22 / m)
        modelAnchor.position = [0, -0.02, -0.50]
        modelAnchor.orientation = simd_quatf(angle: .pi / 8, axis: [0, 1, 0])
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard g.state == .changed else { return }
        let t = g.translation(in: arView)
        modelAnchor.orientation = (simd_quatf(angle: Float(t.x)*0.012, axis:[0,1,0]) * simd_quatf(angle: Float(t.y)*0.012, axis:[1,0,0]) * modelAnchor.orientation).normalized
        g.setTranslation(.zero, in: arView)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        if g.state == .began { g.scale = CGFloat(currentScale) }
        else if g.state == .changed { currentScale = min(max(Float(g.scale), 0.3), 3.5); modelAnchor.scale = SIMD3<Float>(repeating: currentScale) }
    }
}

struct FootARViewWrapper: UIViewRepresentable {
    let manager: FootARManager; let zoneIndex: Int
    func makeUIView(context: Context) -> ARView { manager.setupIfNeeded(); return manager.arView }
    func updateUIView(_ uiView: ARView, context: Context) { manager.updateMarker(zoneIndex: zoneIndex) }
}

// MARK: - Shared Small Components

struct StepBadge: View {
    let step: Int; let total: Int
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(Color.teal).frame(width: 6, height: 6)
            Text("Step \(step) of \(total)")
                .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(.teal).kerning(0.5)
        }
        .padding(.horizontal, 11).padding(.vertical, 6)
        .background(Capsule().fill(Color.tealLight).overlay(Capsule().stroke(Color.teal.opacity(0.18), lineWidth: 1)))
    }
}

// NOTE: ProgressSegment is defined here and used by AssessmentProgressBar (SharedProgressBar.swift).
// Do NOT redeclare it in any other file.
struct ProgressSegment: View {
    let index: Int
    let current: Int

    private var fraction: Double {
        if index <= current { return 1.0 }
        return 0.0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.divider)
                
                if fraction > 0 {
                    Capsule()
                        .fill(index < current ? Color.teal : Color.teal.opacity(0.38))
                        .frame(width: geo.size.width * fraction)
                }
            }
        }
        .frame(height: 5)
        .animation(.spring(response: 0.45, dampingFraction: 0.80), value: current)
        .clipped()
    }
}
struct ZoneChip: View {
    let zone: PalpationZone
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: zone.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.teal)
            Text(zone.shortName.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.teal)
                .kerning(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.tealLight)
                .overlay(Capsule().stroke(Color.teal.opacity(0.15), lineWidth: 1))
        )
    }
}

struct AnatomyTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(.inkSecondary)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.appBG).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.divider, lineWidth: 1)))
    }
}

struct ModelHintView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.2.circlepath").font(.system(size: 11, weight: .semibold))
            Text("Drag to rotate")
            Color.divider.frame(width: 1, height: 12).cornerRadius(1)
            Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 11, weight: .semibold))
            Text("Pinch to zoom")
        }
        .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.inkSecondary)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.85)).shadow(color: .black.opacity(0.06), radius: 6, y: 2))
    }
}

// MARK: - Refactored Decisive Buttons

struct PalpActionButton: View {
    let label: String
    let isPainful: Bool
    let action: () -> Void

    private var bgColor: Color {
        isPainful ? Color.painRedLight : Color.tealLight
    }

    private var textColor: Color {
        isPainful ? Color.painRed : Color.teal
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(bgColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(textColor.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: textColor.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Main Palpation Test Screen

struct PalpationTestScreen: View {
    let canBearWeight: Bool
    
    @StateObject private var arManager = FootARManager()
    @State private var currentIndex = 0
    @State private var results: [UUID: Bool] = [:]
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var cardScale: CGFloat = 1
    @State private var navigateToResults = false
    @State private var modelVisible = false
    @State private var headerVisible = false
    let deepSlate = Color(red: 0.15, green: 0.18, blue: 0.25)
    let calmingTeal = Color(red: 0.08, green: 0.62, blue: 0.62)
    
    var currentZone: PalpationZone {
        let safeIndex = min(currentIndex, palpationZones.count - 1)
        return palpationZones[safeIndex]
    }
    
    private var barStep: Int { currentIndex + 1 }
    
    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                AssessmentProgressBar(currentStep: barStep)
                    .padding(.bottom, 20)
                
                instructionAndZoneHeader
                modelSection
                    .padding(.horizontal, 24)
                    .layoutPriority(1)
                
                HStack(spacing: 14) {
                    PalpActionButton(label: "No Pain", isPainful: false) {
                        recordAnswer(hasPain: false)
                    }
                    PalpActionButton(label: "It Hurts", isPainful: true) {
                        recordAnswer(hasPain: true)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
            
            NavigationLink(
                destination: AssessmentResultsView(
                    canBearWeight: canBearWeight,
                    palpationResults: results,
                    zones: palpationZones
                ),
                isActive: $navigateToResults
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Sub-views
    
    private var instructionAndZoneHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Press firmly on the highlighted area")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.ink)
                    Spacer()
                    Text("If pressing causes sharp pain, select \"It Hurts\"")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundColor(.inkSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    
    private var headerView: some View {
        HStack(spacing: 6) {
            Image(systemName: "cross.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(calmingTeal)
            
            Text("IsItBroken?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(deepSlate)
            
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
    
    private var modelSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.modelBG.opacity(0.4))
            
            
            FootARViewWrapper(manager: arManager, zoneIndex: currentIndex)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            
            ZoneChip(zone: currentZone)
                .padding(.leading, 15)
                .padding(.top, 15)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ModelHintView()
                    Spacer()
                }
                .padding(.bottom, 16)
                .scaleEffect(0.9)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Logic
    
    private func recordAnswer(hasPain: Bool) {
        guard cardOpacity == 1 else { return }
        
        results[currentZone.id] = hasPain
        let dir: CGFloat = hasPain ? -1 : 1
        
        withAnimation(.easeIn(duration: 0.16)) {
            cardOffset = dir * 50
            cardOpacity = 0
            cardScale = 0.96
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            if currentIndex >= palpationZones.count - 1 {
                arManager.stopPulse()
                navigateToResults = true
                cardOffset = 0
                cardOpacity = 1
                cardScale = 1
            } else {
                currentIndex += 1
                cardOffset = dir * -50
                cardScale = 0.96
                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                    cardOffset = 0
                    cardOpacity = 1
                    cardScale = 1
                }
            }
        }
    }
}
