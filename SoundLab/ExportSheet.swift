//
//  ExportSheet.swift
//  SoundLab
    

import SwiftUI


struct ExportSheet: View {
    let engine: SoundEngine
    let currentSound: SoundType
    let sequence: [SoundType]
    let feel: FeelType

    @Environment(\.dismiss) private var dismiss
    
    @EnumStorage(key: "exportScope", defaultValue: .currentSound)
    private var exportScope: ExportScope
    
    @EnumStorage(key: "exportFormat", defaultValue: .aiff)
    private var exportFormat: ExportFormat
    

    @State private var exportResult: ExportResultState?
    @State private var errorMessage: String?


    private var params: FeelParams   { feelParams[feel] ?? feelParams[.aero]! }
    private var feelName: String     { (feelConfig[feel]?.label ?? feel.rawValue).lowercased() }
    private var accentColor: Color   { .blue }

    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            
            Divider().opacity(0.4)

            if let result = exportResult {
                successView(result)
            } else {
                exportForm
            }
        }
        .background(visualEffectBackground.ignoresSafeArea())
    }


    
    private var visualEffectBackground: some View {
        #if os(macOS)
        VisualEffectView()
        #else
        Color.platformBackground
        #endif
    }
    
    
    private var sheetHeader: some View {
        HStack {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                exportResult = nil
                dismiss()
            } label: {
                if exportResult == nil {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.platformSecondary.opacity(0.7))
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Text("Done")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.platformSecondary.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.quinary, in: .capsule)
                        .capsuleBorder(lineWidth: 1)
                }
            }
            .linkCursorStyle()
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    
    private var exportForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scope picker
                formSection(title: "CONTENT") {
                    HStack(spacing: 8) {
                        ForEach(ExportScope.allCases) { scope in
                            ScopeChip(
                                title: scope.rawValue,
                                isSelected: exportScope == scope,
                                accentColor: accentColor
                            ) {
                                withAnimation { exportScope = scope }
                            }
                        }
                    }

                    if exportScope == .fullSequence {
                        inlineMessage(
                            sequence.isEmpty ? "Select more sounds to be exported." : "Each sound will be saved as a separate file in one folder.",
                            systemIcon: sequence.isEmpty ? "exclamationmark.triangle" : "info.circle"
                        )
                    }
                }

                // Format picker
                formSection(title: "FORMAT") {
                    HStack(spacing: 8) {
                        ForEach(ExportFormat.allCases) { f in
                            ScopeChip(
                                title: f.rawValue,
                                subtitle: f == .wav ? "Uncompressed" : "Apple",
                                isSelected: exportFormat == f,
                                accentColor: accentColor
                            ) { exportFormat = f }
                        }
                    }
                }

                // Info card
                infoCard

                // Error
                if let err = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(err)
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                // Export button
                exportActionButton
            }
            .padding(20)
        }
    }

    
    private func formSection<Content: View>(title: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7.5) {
            Text(title)
                .font(.system(size: 10.6, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.platformSecondary.opacity(0.8))
                .tracking(1.6)
            content()
        }
    }


    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Export Summary")
                .font(.system(size: 12, weight: .semibold))
            
            Divider().opacity(0.4)
                .padding(.horizontal, -14)
                .padding(.vertical, 10)

            VStack(spacing: 9) {
                infoRow("Content",  exportScope == .currentSound
                    ? (soundConfig[currentSound]?.label ?? currentSound.rawValue)
                    : "\(sequence.count) files in folder")
                infoRow("Collection", feelConfig[feel]?.label ?? feel.rawValue)
                infoRow("Format",   "\(exportFormat.rawValue) · 44,100 Hz · 16-bit")
                infoRow("Output",   exportScope == .currentSound ? singleFileName : "SoundLab_\(feelName)_…/")
            }
        }
        .padding(14)
        .background(Color.platformGray5.opacity(0.4), in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.platformGray4.opacity(0.6), lineWidth: 1.5)
        )
    }

    
    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.system(size: 11))
                .foregroundStyle(Color.platformSecondary)
                .frame(width: 58, alignment: .leading)
            
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
    
    func inlineMessage(_ message: String, systemIcon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemIcon)
                
            Text(message)
        }
        #if os(macOS)
        .font(.callout)
        #else
        .font(.footnote)
        #endif
        .foregroundStyle(.orange.gradient)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.08), in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.6), lineWidth: 1.0)
        }
    }

    
    private var singleFileName: String {
        "SoundLab_\(feelName)_\((soundConfig[currentSound]?.label ?? currentSound.rawValue).lowercased()).\(exportFormat.fileExtension)"
    }


    private var exportActionButton: some View {
        Button(action: runExport) {
            HStack(spacing: 8) {
                Image(systemName: exportScope == .fullSequence ? "folder.badge.plus" : "square.and.arrow.up")
                Text(exportScope == .fullSequence ? "Export Folder" : "Export & Share")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(.blackWhite, in: .capsule)
        }
        .linkCursorStyle()
        .buttonStyle(.plain)
        .disabled(exportScope == .fullSequence && sequence.isEmpty)
    }


    private func successView(_ result: ExportResultState) -> some View {
        VStack(spacing: 20) {
            Spacer()

            // Big checkmark
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 6) {
                Text("Export Complete")
                    .font(.system(size: 16, weight: .semibold))
                switch result {
                case .single(let url):
                    Text(url.lastPathComponent)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.platformSecondary)
                        .multilineTextAlignment(.center)
                case .folder(_, let files):
                    Text("\(files.count) files exported")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.platformSecondary)
                }
            }

            // Action buttons
            VStack(spacing: 10) {
                #if os(macOS)
                macActionButtons(result)
                #else
                iosActionButtons(result)
                #endif
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    
    #if os(macOS)
    @ViewBuilder
    private func macActionButtons(_ result: ExportResultState) -> some View {
        Button {
            switch result {
            case .single(let url):
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            case .folder(let folder, _):
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folder.path)
            }
        } label: {
            Label("Reveal in Finder", systemImage: "folder")
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(.quinary, in: .capsule)
                .capsuleBorder()
        }
        .pointerStyle(.link)
        .buttonStyle(.plain)
        

        Button {
            switch result {
            case .single(let url):
                saveFileMac(url)
            case .folder(let folder, _):
                saveFolderMac(folder)
            }
        } label: {
            Label("Save As…", systemImage: "tray.and.arrow.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(.blackWhite, in: .capsule)
        }
        .pointerStyle(.link)
        .buttonStyle(.plain)
    }

    
    private func saveFileMac(_ url: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = url.lastPathComponent
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.copyItem(at: url, to: dest)
        }
    }

    
    private func saveFolderMac(_ folder: URL) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles       = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Destination"
        if panel.runModal() == .OK, let dest = panel.url {
            let target = dest.appendingPathComponent(folder.lastPathComponent)
            try? FileManager.default.copyItem(at: folder, to: target)
        }
    }
    #endif
        
    
    #if os(iOS)
    private func iosActionButtons(_ result: ExportResultState) -> some View {
        Button {
            let urls: [URL] = {
                switch result {
                case .single(let url):  return [url]
                case .folder(_, let fs): return fs
                }
            }()
            
            SharePresenter.present(with: urls)
        } label: {
            Label("Share Files", systemImage: "square.and.arrow.up")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(.blackWhite, in: .capsule)
        }
        .buttonStyle(.plain)
    }
    #endif

    

    private func runExport() {
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result: ExportResultState
                if self.exportScope == .currentSound {
                    let url = try self.engine.exportSound(
                        self.currentSound,
                        params: self.params,
                        format: self.exportFormat,
                        soundName: (soundConfig[self.currentSound]?.label ?? self.currentSound.rawValue).lowercased(),
                        feelName: self.feelName
                    )
                    result = .single(url)
                } else {
                    let (folder, files) = try self.engine.exportSequence(
                        self.sequence,
                        params: self.params,
                        format: self.exportFormat,
                        feelName: self.feelName
                    )
                    result = .folder(folder, files)
                }
                
                DispatchQueue.main.async {
                    self.exportResult = result
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}


struct ScopeChip: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? accentColor.gradient : Color.primary.gradient)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.platformSecondary.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovered ?
                        Color.platformGray5.opacity(0.8)
                        : Color.platformGray5.opacity(0.4),
                        in: .rect(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? accentColor.opacity(0.5) : Color.platformGray4.opacity(0.6), lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
