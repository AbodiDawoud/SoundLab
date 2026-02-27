//
//  SoundEngine.swift
//  SoundLab


import AVFoundation
import Foundation


// MARK: - Buffer helper

func makePCMBuffer(samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer? {
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    guard let buf = AVAudioPCMBuffer(pcmFormat: format,
                                     frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
    buf.frameLength = AVAudioFrameCount(samples.count)
    let ch = buf.floatChannelData![0]
    for (i, s) in samples.enumerated() { ch[i] = s }
    return buf
}

// MARK: - DSP Helpers

private func oscSample(_ type: OscillatorType, phase: Float) -> Float {
    switch type {
    case .sine:     return sin(2 * .pi * phase)
    case .square:   return sin(2 * .pi * phase) >= 0 ? 1 : -1
    case .sawtooth: let p = phase - floor(phase); return 2 * p - 1
    case .triangle: let p = phase - floor(phase); return p < 0.5 ? 4*p-1 : 3-4*p
    }
}

private func expEnv(t: Float, attack: Float, peak: Float, duration: Float) -> Float {
    guard duration > attack else { return peak }
    if t < attack { return peak * (t / attack) }
    let dt = (t - attack) / (duration - attack)
    return max(0, peak * exp(log(0.001 / peak) * dt))
}

private func biquad(_ samples: [Float], b0: Float, b1: Float, b2: Float,
                    a1: Float, a2: Float) -> [Float] {
    var out = [Float](repeating: 0, count: samples.count)
    var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0
    for i in 0..<samples.count {
        let x0 = samples[i]
        let y0 = b0*x0 + b1*x1 + b2*x2 - a1*y1 - a2*y2
        out[i] = y0; x2 = x1; x1 = x0; y2 = y1; y1 = y0
    }
    return out
}

private func bandpass(_ s: [Float], sr: Float, freq: Float, q: Float) -> [Float] {
    let w = 2 * Float.pi * freq / sr, alpha = sin(w) / (2 * q)
    let a0 = 1 + alpha, a1 = -2 * cos(w), a2 = 1 - alpha
    return biquad(s, b0: alpha/a0, b1: 0, b2: -alpha/a0, a1: a1/a0, a2: a2/a0)
}

private func highpass(_ s: [Float], sr: Float, freq: Float) -> [Float] {
    let w = 2 * Float.pi * freq / sr, alpha = sin(w) / 2
    let b0 = (1+cos(w))/2, b1 = -(1+cos(w)), b2 = (1+cos(w))/2
    let a0 = 1+alpha, a1 = -2*cos(w), a2 = 1-alpha
    return biquad(s, b0: b0/a0, b1: b1/a0, b2: b2/a0, a1: a1/a0, a2: a2/a0)
}

private func lowpass(_ s: [Float], sr: Float, freq: Float) -> [Float] {
    let w = 2 * Float.pi * freq / sr, alpha = sin(w) / 2
    let b0 = (1-cos(w))/2, b1 = 1-cos(w), b2 = (1-cos(w))/2
    let a0 = 1+alpha, a1 = -2*cos(w), a2 = 1-alpha
    return biquad(s, b0: b0/a0, b1: b1/a0, b2: b2/a0, a1: a1/a0, a2: a2/a0)
}

// MARK: - Synthesis

func synthesizeSound(_ sound: SoundType, params: FeelParams, sampleRate: Float) -> [Float] {
    switch sound {
    case .click:   return synClick(params, sampleRate)
    case .pop:     return synPop(params, sampleRate)
    case .toggle:  return synToggle(params, sampleRate)
    case .tick:    return synTick(params, sampleRate)
    case .drop:    return synDrop(params, sampleRate)
    case .success: return synSuccess(params, sampleRate)
    case .error:   return synError(params, sampleRate)
    case .warning: return synWarning(params, sampleRate)
    case .startup: return synStartup(params, sampleRate)
    }
}

private func synClick(_ p: FeelParams, _ sr: Float) -> [Float] {
    let n = Int(sr * 0.008 * p.decayMult)
    var s = (0..<n).map { i -> Float in
        Float.random(in: -1...1) * exp(-Float(i) / (50 * p.decayMult)) * 0.5 * p.gainMult
    }
    s = bandpass(s, sr: sr, freq: p.filterFreq, q: p.q)
    return s
}

private func synPop(_ p: FeelParams, _ sr: Float) -> [Float] {
    let dur = 0.05 * p.decayMult
    let n = Int(sr * dur)
    return (0..<n).map { i in
        let t = Float(i) / sr
        let freq = 400 * p.pitchMult * pow(150 / (400 * p.pitchMult), t / dur)
        let env  = max(0, 0.35 * p.gainMult * exp(-t / (dur * 0.4)))
        return oscSample(p.oscType, phase: Float(i) * freq / sr) * env
    }
}

private func synToggle(_ p: FeelParams, _ sr: Float) -> [Float] {
    let nd = 0.012 * p.decayMult
    var noise = (0..<Int(sr * nd)).map { i -> Float in
        Float.random(in: -1...1) * exp(-Float(i) / (80 * p.decayMult)) * 0.4 * p.gainMult
    }
    noise = bandpass(noise, sr: sr, freq: 2500, q: p.q)

    let td = 0.04 * p.decayMult
    let tone = (0..<Int(sr * td)).map { i -> Float in
        let t = Float(i) / sr
        let freq = 800 * p.pitchMult * pow(400 / (800 * p.pitchMult), t / td)
        return sin(2 * .pi * Float(i) * freq / sr) * max(0, 0.15 * p.gainMult * exp(-t / (td * 0.5)))
    }

    var out = [Float](repeating: 0, count: max(noise.count, tone.count))
    for (i, v) in noise.enumerated() { out[i] += v }
    for (i, v) in tone.enumerated()  { out[i] += v }
    return out
}

private func synTick(_ p: FeelParams, _ sr: Float) -> [Float] {
    let n = Int(sr * 0.004 * p.decayMult)
    var s = (0..<n).map { i -> Float in
        Float.random(in: -1...1) * exp(-Float(i) / (20 * p.decayMult)) * 0.3 * p.gainMult
    }
    s = highpass(s, sr: sr, freq: 3000 * p.pitchMult)
    return s
}

private func synDrop(_ p: FeelParams, _ sr: Float) -> [Float] {
    let dur = 0.12 * p.decayMult
    let n   = Int(sr * dur)
    let s0  = 800 * p.pitchMult, e0 = 300 * p.pitchMult
    return (0..<n).map { i in
        let t   = Float(i) / sr
        let freq = s0 * pow(e0 / s0, t / dur)
        let env  = expEnv(t: t, attack: 0.005, peak: 0.35 * p.gainMult, duration: dur)
        return oscSample(p.oscType, phase: Float(i) * freq / sr) * env
    }
}

private func synSuccess(_ p: FeelParams, _ sr: Float) -> [Float] {
    let notes: [Float] = [523.25, 659.25, 783.99].map { $0 * p.pitchMult }
    let spacing = 0.08 * p.decayMult, noteDur = 0.15 * p.decayMult
    let total   = Int(sr * (noteDur + spacing * 2)) + 100
    var out     = [Float](repeating: 0, count: total)
    let type: OscillatorType = p.oscType == .square ? .triangle : p.oscType
    for (idx, freq) in notes.enumerated() {
        let start = Int(sr * spacing * Float(idx))
        for i in 0..<Int(sr * noteDur) {
            let t = Float(i) / sr
            let env = expEnv(t: t, attack: 0.01, peak: 0.25 * p.gainMult, duration: noteDur)
            let fi  = start + i
            if fi < out.count { out[fi] += oscSample(type, phase: Float(start+i)*freq/sr) * env }
        }
    }
    return out
}

private func synError(_ p: FeelParams, _ sr: Float) -> [Float] {
    let dur = 0.25 * p.decayMult, n = Int(sr * dur)
    let base = 180 * p.pitchMult
    let t1: OscillatorType = p.oscType == .sine ? .sawtooth : p.oscType
    let t2: OscillatorType = p.oscType == .sine ? .square   : p.oscType
    var s = (0..<n).map { i -> Float in
        let t = Float(i) / sr, prog = t / dur
        let f1 = base        * pow(80 / base,          prog)
        let f2 = base * 1.05 * pow(85/(base*1.05),     prog)
        let env = max(0, 0.2 * p.gainMult * exp(log(0.001/0.2) * prog))
        return (oscSample(t1, phase: Float(i)*f1/sr) + oscSample(t2, phase: Float(i)*f2/sr)) * 0.5 * env
    }
    s = lowpass(s, sr: sr, freq: 800)
    return s
}

private func synWarning(_ p: FeelParams, _ sr: Float) -> [Float] {
    let noteDur = 0.12 * p.decayMult, gap = 0.15 * p.decayMult
    let total   = Int(sr * (gap + noteDur)) + 100
    var out     = [Float](repeating: 0, count: total)
    let freqs: [Float] = [880 * p.pitchMult, 698 * p.pitchMult]
    let type: OscillatorType = p.oscType == .square ? .triangle : p.oscType
    for (idx, freq) in freqs.enumerated() {
        let start = Int(sr * (idx == 0 ? 0 : gap))
        for i in 0..<Int(sr * noteDur) {
            let t = Float(i) / sr
            let env = expEnv(t: t, attack: 0.01, peak: 0.3 * p.gainMult, duration: noteDur)
            let fi  = start + i
            if fi < out.count { out[fi] += oscSample(type, phase: Float(start+i)*freq/sr) * env }
        }
    }
    return out
}

private func synStartup(_ p: FeelParams, _ sr: Float) -> [Float] {
    let notes: [Float]  = [392, 493.88, 587.33, 784].map { $0 * p.pitchMult }
    let delays: [Float] = [0, 0.02, 0.04, 0.06].map { $0 * p.decayMult }
    let totalDur = 0.6 * p.decayMult
    var out = [Float](repeating: 0, count: Int(sr * totalDur) + 100)
    let type: OscillatorType = p.oscType == .square ? .triangle : p.oscType
    for (idx, freq) in notes.enumerated() {
        let start = Int(sr * delays[idx]), ndur = totalDur - delays[idx]
        let holdE = ndur * 0.3, peak = 0.14 * p.gainMult
        for i in 0..<Int(sr * ndur) {
            let t = Float(i) / sr
            let ph1 = Float(start+i) * freq / sr, ph2 = Float(start+i) * freq * 1.002 / sr
            let osc = (oscSample(type, phase: ph1) + oscSample(type, phase: ph2)) * 0.5
            let env: Float
            if t < 0.05       { env = peak * (t / 0.05) }
            else if t < holdE { env = peak }
            else              { env = max(0, peak * exp(log(0.001/peak) * (t-holdE)/(ndur-holdE))) }
            let fi = start + i
            if fi < out.count { out[fi] += osc * env }
        }
    }
    if let pk = out.map(abs).max(), pk > 0.8 { let s = 0.8/pk; out = out.map { $0*s } }
    return out
}

// MARK: - Sound Engine

class SoundEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var mixer  = AVAudioMixerNode()
    let exportSampleRate: Double = 44100

    init() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    private var liveSampleRate: Double {
        engine.outputNode.outputFormat(forBus: 0).sampleRate
    }

    // MARK: Playback

    func play(_ sound: SoundType, params: FeelParams) {
        let sr      = Float(liveSampleRate)
        let samples = synthesizeSound(sound, params: params, sampleRate: sr)
        
        guard let buf = makePCMBuffer(samples: samples, sampleRate: liveSampleRate) else { return }
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: buf.format)
        player.scheduleBuffer(buf, completionCallbackType: .dataPlayedBack) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.engine.detach(player)
                }
            }
        }
        player.play()
    }

    // MARK: Export — single sound

    func exportSound(_ sound: SoundType,
                     params: FeelParams,
                     format: ExportFormat,
                     soundName: String,
                     feelName: String) throws -> URL {
        let samples = synthesizeSound(sound, params: params, sampleRate: Float(exportSampleRate))
        guard let buf = makePCMBuffer(samples: samples, sampleRate: exportSampleRate) else {
            throw ExportError.bufferCreationFailed
        }
        return try writeFile(buf, format: format, name: "SoundLab_\(feelName)_\(soundName)",
                             inFolder: nil)
    }

    // MARK: Export — sequence as individual files inside a folder

    /// Returns the folder URL + each individual file URL for display.
    func exportSequence(_ sequence: [SoundType],
                        params: FeelParams,
                        format: ExportFormat,
                        feelName: String) throws -> (folder: URL, files: [URL]) {
        guard !sequence.isEmpty else { throw ExportError.emptySequence }

        // Create a timestamped folder in tmp
        let folderName = "SoundLab_\(feelName)_\(timestamp())"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(folderName)
        do {
            try FileManager.default.createDirectory(at: folder,
                                                    withIntermediateDirectories: true)
        } catch {
            throw ExportError.folderCreationFailed
        }

        let sr = Float(exportSampleRate)
        var files = [URL]()

        try DispatchQueue.global(qos: .userInitiated).sync {
            for (idx, sound) in sequence.enumerated() {
                let samples = synthesizeSound(sound, params: params, sampleRate: sr)
                guard let buf = makePCMBuffer(samples: samples, sampleRate: exportSampleRate) else {
                    throw ExportError.bufferCreationFailed
                }
                // Numbered prefix so they sort correctly in Finder
                let name = String(format: "%02d_%@", idx + 1,
                                  (soundConfig[sound]?.label ?? sound.rawValue).lowercased())
                let url = try writeFile(buf, format: format, name: name, inFolder: folder)
                files.append(url)
            }
        }


        return (folder, files)
    }

    // MARK: Write helpers

    private func writeFile(_ buffer: AVAudioPCMBuffer,
                           format: ExportFormat,
                           name: String,
                           inFolder folder: URL?) throws -> URL {
        let base = folder ?? FileManager.default.temporaryDirectory
        let url  = base.appendingPathComponent(name).appendingPathExtension(format.fileExtension)

        let settings: [String: Any] = [
            AVFormatIDKey:             kAudioFormatLinearPCM,
            AVSampleRateKey:           exportSampleRate,
            AVNumberOfChannelsKey:     1,
            AVLinearPCMBitDepthKey:    16,
            AVLinearPCMIsFloatKey:     false,
            AVLinearPCMIsBigEndianKey: format.isBigEndian,
        ]
        let file = try AVAudioFile(forWriting: url, settings: settings,
                                   commonFormat: .pcmFormatFloat32, interleaved: false)
        try file.write(from: buffer)
        return url
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: Date())
    }
}



// MARK: - Models

struct FeelParams {
    let filterFreq: Float
    let q: Float
    let oscType: OscillatorType
    let decayMult: Float
    let gainMult: Float
    let pitchMult: Float
}


enum OscillatorType: Equatable {
    case sine, square, sawtooth, triangle
}


enum ExportScope: String, CaseIterable, Identifiable {
    case currentSound = "Current Sound"
    case fullSequence = "Full Sequence"
    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case wav  = "WAV"
    case aiff = "AIFF"
    
    var id: String { rawValue }
    var fileExtension: String { self == .wav ? "wav" : "aiff" }
    var isBigEndian: Bool { self == .aiff }
}


enum ExportResultState {
    case single(URL)
    case folder(URL, [URL])
}


enum ExportError: LocalizedError {
    case bufferCreationFailed
    case emptySequence
    case folderCreationFailed

    var errorDescription: String? {
        switch self {
        case .bufferCreationFailed:  return "Failed to create audio buffer."
        case .emptySequence:         return "No sounds are selected to export."
        case .folderCreationFailed:  return "Could not create export folder."
        }
    }
}
