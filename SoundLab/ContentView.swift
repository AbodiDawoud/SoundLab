//
//  ContentView.swift
//  SoundLab


import SwiftUI


struct ContentView: View {
    @StateObject private var engine = SoundEngine()

    @EnumStorage(key: "feelType", defaultValue: FeelType.soft)
    private var feel: FeelType
    
    
    @State private var selectedSounds: Set<SoundType> = [SoundType.click, SoundType.success, SoundType.error]
    @State private var currentIndex: Int              = 0
    @State private var isPlayPressed: Bool            = false
    @State private var showExportSheet: Bool          = false
    
    @AppStorage("cycleState")
    private var autoCycle: Bool = false
    
    
    private var sequence: [SoundType] {
        SoundType.allCases.filter { selectedSounds.contains($0) }
    }
    private var safeIndex: Int {
        sequence.isEmpty ? 0 : currentIndex % sequence.count
    }
    private var currentSound: SoundType {
        sequence.isEmpty ? .click : sequence[safeIndex]
    }
    private var accentColor: Color {
        feelConfig[feel]!.color
    }

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            toolbar
            #endif
                
            Spacer()

            playerSection


            // Sequence dots
            HStack(spacing: 12) {
                Text(currentSound.rawValue.uppercased())
                    .font(
                        .system(size: 10.6, weight: .bold, design: .monospaced)
                    )
                    .foregroundStyle(Color.platformSecondary.opacity(0.6))
                    .tracking(1.6)
                    
                sequenceDots
            }
            .padding(.vertical, 26)

            Spacer()
                
            Divider()
                .opacity(0.4)

            // Bottom control panel
            controlPanel
                .padding(.top, 18)
                .padding(.bottom, 24)
        }
        .animation(.easeInOut(duration: 0.3), value: feel)
        .animation(.easeInOut(duration: 0.15), value: currentSound)
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(
                engine: engine,
                currentSound: currentSound,
                sequence: sequence,
                feel: feel
            )
            #if canImport(UIKit)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            #endif
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $autoCycle) {
                    Label("Cycle", systemImage: "arrow.clockwise")
                }
                .controlSize(.regular)
                .labelStyle(.titleAndIcon)
                .toggleStyle(.button)
                .help("If checked, the sequence will automatically cycle through sounds after each play.")
            }
            
            ToolbarItem {
                Button("Export", systemImage: "square.and.arrow.up") { showExportSheet = true }
                    .controlSize(.regular)
                    .labelStyle(.titleAndIcon)
                    .help("Export the selected sound or the entire sequence to a local file.")
            }
        }
        #endif
    }

    
    private var toolbar: some View {
        HStack(spacing: 0) {
            // App wordmark
            Text("Sound Lab")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.primary.gradient)

            Spacer()

            // Export pill button
            Button { showExportSheet = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                    
                    Text("Export")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.gray.opacity(0.08), in: .capsule)
                .capsuleBorder(lineWidth: 1)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    
    private var playerSection: some View {
        HStack(spacing: 24) {
            // ← Prev
            NavArrowButton(direction: .backward, accentColor: accentColor) {
                stepSequence(by: -1)
            }
            .disabled(sequence.isEmpty)

            // Play button
            playButton

            // → Next
            NavArrowButton(direction: .forward, accentColor: accentColor) {
                stepSequence(by: 1)
            }
            .disabled(sequence.isEmpty)
        }
    }

    
    private var playButton: some View {
        Button(action: cycleAndPlay) {
            ZStack {
                // Outer ring pulse
                Circle()
                    .strokeBorder(accentColor.opacity(0.9), style: .init(lineWidth: 1.8, dash: [6, 6]))
                    .frame(width: 74, height: 74)

                // Main circle
                Circle()
                    .fill(accentColor.gradient)
                    .frame(width: 58, height: 58)
                    .shadow(color: accentColor.opacity(0.15), radius: 14, y: 5)

                Image(systemName: soundConfig[currentSound]?.systemImage ?? "speaker.wave.2")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .id(currentSound)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal:   .scale(scale: 0.4).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: currentSound)
            }
            .scaleEffect(isPlayPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPlayPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPlayPressed = true }
                .onEnded   { _ in isPlayPressed = false }
        )
        .accessibilityLabel("Play \(soundConfig[currentSound]?.label ?? currentSound.rawValue)")
    }

    
    private var sequenceDots: some View {
        HStack(spacing: 5) {
            ForEach(Array(sequence.enumerated()), id: \.element) { idx, _ in
                Capsule()
                    .fill(idx == safeIndex ? Color.blackWhite : Color.platformGray4.opacity(0.6))
                    .frame(width: idx == safeIndex ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: safeIndex)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selectedSounds)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selectedSounds)
        .frame(minHeight: 12)
    }

    
    
    // MARK: - Control panel
    
    private var controlPanel: some View {
        HStack(alignment: .top, spacing: 0) {
            // Sounds section
            VStack(spacing: 10) {
                sectionLabel("SOUNDS")
                soundGrid
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.platformGray5)
                .frame(width: 1.5, height: 112)
                .padding(.top, 26)

            // Feels section
            VStack(spacing: 10) {
                sectionLabel(feel.rawValue)
                feelGrid
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.6, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.platformSecondary.opacity(0.6))
            .tracking(1.6)
            .frame(maxWidth: .infinity)
    }
    
    
    let columns = Array(repeating: GridItem(.fixed(35), spacing: 7), count: 3)
    let columsSpacing: CGFloat = 7
    
    private var soundGrid: some View {
        VStack(spacing: columsSpacing) {
            LazyVGrid(columns: columns, spacing: columsSpacing) {
                ForEach(SoundType.allCases) { sound in
                    PillIconButton(
                        systemImage: soundConfig[sound]?.systemImage ?? "speaker",
                        label: soundConfig[sound]?.label ?? sound.rawValue,
                        isActive: selectedSounds.contains(sound),
                        isCurrent: sound == currentSound,
                        accentColor: accentColor
                    ) { toggleSound(sound) }
                }
            }
        }
    }

    private var feelGrid: some View {
        VStack(spacing: columsSpacing) {
            LazyVGrid(columns: columns, spacing: columsSpacing) {
                ForEach(FeelType.allCases) { f in
                    PillIconButton(
                        systemImage: feelConfig[f]?.systemImage ?? "waveform",
                        label: feelConfig[f]?.label ?? f.rawValue,
                        isActive: feel == f,
                        isCurrent: false,
                        accentColor: feelConfig[f]?.color ?? .blue
                    ) { handleFeelChange(f) }
                }
            }
        }
    }

    
    
    // MARK: - Actions

    private func cycleAndPlay() {
        guard !sequence.isEmpty else { return }
        let params = feelParams[feel] ?? feelParams[.aero]!
        engine.play(currentSound, params: params)
        
        
        if autoCycle {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                currentIndex += 1
            }
        }
    }

    private func stepSequence(by delta: Int) {
        guard !sequence.isEmpty else { return }
        let params = feelParams[feel] ?? feelParams[.aero]!
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            // Wrap properly for backward stepping
            currentIndex = ((currentIndex + delta) % sequence.count + sequence.count) % sequence.count
        }
        engine.play(currentSound, params: params)
    }

    private func toggleSound(_ sound: SoundType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            if selectedSounds.contains(sound) { selectedSounds.remove(sound) }
            else                              { selectedSounds.insert(sound) }
        }
    }

    private func handleFeelChange(_ newFeel: FeelType) {
        feel = newFeel
        let params = feelParams[newFeel] ?? feelParams[.aero]!
        engine.play(.toggle, params: params)
    }
}


struct NavArrowButton: View {
    enum Direction { case forward, backward }
    let direction: Direction
    let accentColor: Color
    let action: () -> Void

    @State private var isHovered  = false
    

    private var sfName: String {
        direction == .forward ? "chevron.right" : "chevron.left"
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.platformGray5.opacity(0.6))
                    .frame(width: 32, height: 32)

                Image(systemName: sfName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isHovered ? accentColor : Color.platformSecondary)
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .linkCursorStyle()
        .accessibilityLabel(direction == .forward ? "Next sound" : "Previous sound")
    }
}


struct PillIconButton: View {
    let systemImage: String
    let label: String
    let isActive: Bool
    let isCurrent: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isHovered
                                 ? Color.platformGray5.opacity(0.9)
                                 : Color.platformGray5.opacity(0.5))

                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(
                            isActive ? accentColor.opacity(0.7) : Color.platformGray4.opacity(0.6),
                            lineWidth: isActive ? 2 : 0.8
                        )

                    Image(systemName: systemImage)
                        .font(.system(size: 14.5, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? accentColor.gradient : Color.platformSecondary.gradient)
                }
                .frame(width: 36, height: 32)
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
            .animation(.easeInOut(duration: 0.18), value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
