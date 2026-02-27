//
//  Models.swift
//  SoundLab


import SwiftUI


enum SoundType: String, CaseIterable, Identifiable, Hashable {
    case click, pop, toggle, tick, drop, success, error, warning, startup
    var id: String { rawValue }
}


enum FeelType: String, CaseIterable, Identifiable, Hashable {
    case soft, aero, arcade, organic, glass, industrial, minimal, retro, crisp
    var id: String { rawValue }
}


struct SoundConfig {
    let label: String
    let systemImage: String
}


struct FeelConfig {
    let label: String
    let systemImage: String
    let color: Color
}



// MARK: - Global Values

let soundConfig: [SoundType: SoundConfig] = [
    .click:   .init(label: "Click",   systemImage: "cursorarrow.click"),
    .pop:     .init(label: "Pop",     systemImage: "circle"),
    .toggle:  .init(label: "Toggle",  systemImage: "arrow.2.squarepath"),
    .tick:    .init(label: "Tick",    systemImage: "checkmark"),
    .drop:    .init(label: "Drop",    systemImage: "arrow.down"),
    .success: .init(label: "Success", systemImage: "checkmark.circle"),
    .error:   .init(label: "Error",   systemImage: "xmark.circle"),
    .warning: .init(label: "Warning", systemImage: "exclamationmark.triangle"),
    .startup: .init(label: "Startup", systemImage: "play.circle"),
]


let feelConfig: [FeelType: FeelConfig] = [
    .soft:       .init(label: "Soft",       systemImage: "heart",         color: Color(red: 0.93, green: 0.40, blue: 0.64)),
    .aero:       .init(label: "Aero",       systemImage: "sparkles",      color: Color(red: 0.28, green: 0.55, blue: 0.98)),
    .arcade:     .init(label: "Arcade",     systemImage: "waveform",      color: Color(red: 0.65, green: 0.36, blue: 0.97)),
    .organic:    .init(label: "Organic",    systemImage: "leaf",          color: Color(red: 0.22, green: 0.72, blue: 0.44)),
    .glass:      .init(label: "Glass",      systemImage: "star",          color: Color(red: 0.12, green: 0.78, blue: 0.87)),
    .industrial: .init(label: "Industrial", systemImage: "gearshape",     color: Color(red: 0.97, green: 0.55, blue: 0.20)),
    .minimal:    .init(label: "Minimal",    systemImage: "minus",         color: Color(red: 0.60, green: 0.60, blue: 0.60)),
    .retro:      .init(label: "Retro",      systemImage: "record.circle", color: Color(red: 0.96, green: 0.76, blue: 0.20)),
    .crisp:      .init(label: "Crisp",      systemImage: "target",        color: Color(red: 0.93, green: 0.25, blue: 0.25)),
]


let feelParams: [FeelType: FeelParams] = [
    .soft:       .init(filterFreq: 2000, q: 1,  oscType: .sine,     decayMult: 1.5, gainMult: 0.7,  pitchMult: 0.8),
    .aero:       .init(filterFreq: 3500, q: 2,  oscType: .sine,     decayMult: 1.0, gainMult: 0.9,  pitchMult: 1.0),
    .arcade:     .init(filterFreq: 4000, q: 8,  oscType: .square,   decayMult: 0.5, gainMult: 1.0,  pitchMult: 1.5),
    .organic:    .init(filterFreq: 2500, q: 3,  oscType: .triangle, decayMult: 1.3, gainMult: 0.85, pitchMult: 0.9),
    .glass:      .init(filterFreq: 6000, q: 10, oscType: .sine,     decayMult: 1.2, gainMult: 0.75, pitchMult: 1.8),
    .industrial: .init(filterFreq: 3000, q: 12, oscType: .sawtooth, decayMult: 0.6, gainMult: 1.2,  pitchMult: 0.7),
    .minimal:    .init(filterFreq: 2000, q: 1,  oscType: .sine,     decayMult: 0.8, gainMult: 0.4,  pitchMult: 1.0),
    .retro:      .init(filterFreq: 1500, q: 2,  oscType: .square,   decayMult: 1.1, gainMult: 0.8,  pitchMult: 0.85),
    .crisp:      .init(filterFreq: 5500, q: 4,  oscType: .triangle, decayMult: 0.6, gainMult: 1.0,  pitchMult: 1.1),
]
