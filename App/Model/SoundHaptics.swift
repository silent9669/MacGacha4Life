// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AudioToolbox
import CoreAudio
import CoreHaptics
import Foundation
import GameController
import os

/// Vibrates a DualSense from a game's own sound. Over Bluetooth a native PlayStation pad gets no
/// vibration from the game (Sony's haptics need the pad's USB audio channel), so this taps the
/// game process's audio with a Core Audio process tap, follows its low-frequency energy and drives
/// the pad's haptics through GameController. Nothing else is captured or stored.
@MainActor final class SoundHaptics {
    private var tap = AudioObjectID(kAudioObjectUnknown)
    private var aggregate = AudioObjectID(kAudioObjectUnknown)
    private var ioProc: AudioDeviceIOProcID?
    private var engine: CHHapticEngine?
    private var timer: Timer?
    private var level: Float = 0
    private var consecutiveErrors = 0
    private let meter = LowFrequencyMeter()
    private(set) var pid: pid_t?
    /// Why the last `start` failed, path-free, for the session log.
    private(set) var failure: String?
    /// Ticks, pulses played, pulse errors and the loudest low-pass RMS seen, for diagnostics.
    private(set) var stats = (ticks: 0, pulses: 0, errors: 0, maxRMS: Float(0))

    var running: Bool { pid != nil }

    /// Starts following `pid`'s sound on the first connected DualSense. Returns false when
    /// there is no DualSense, the process has no audio yet, or macOS refuses the tap.
    @discardableResult func start(pid: pid_t) -> Bool {
        stop()
        guard let pad = GCController.controllers().first(where: { $0.extendedGamepad is GCDualSenseGamepad }) else { return fail("no DualSense") }
        guard let engine = pad.haptics?.createEngine(withLocality: .default) else { return fail("haptics unavailable") }
        if let reason = startEngine(engine) { return fail(reason) }
        if let reason = startTap(pid: pid) { return fail(reason) }
        self.pid = pid
        timer = Timer.scheduledTimer(withTimeInterval: Self.tick, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        return true
    }

    private func fail(_ reason: String) -> Bool {
        stop(); failure = reason
        return false
    }

    func stop() {
        timer?.invalidate(); timer = nil
        engine?.stop(); engine = nil
        if let ioProc { AudioDeviceStop(aggregate, ioProc); AudioDeviceDestroyIOProcID(aggregate, ioProc) }
        ioProc = nil
        if aggregate != kAudioObjectUnknown { AudioHardwareDestroyAggregateDevice(aggregate) }
        if tap != kAudioObjectUnknown { AudioHardwareDestroyProcessTap(tap) }
        aggregate = AudioObjectID(kAudioObjectUnknown); tap = AudioObjectID(kAudioObjectUnknown)
        level = 0; pid = nil; failure = nil; consecutiveErrors = 0
    }

    private func startEngine(_ engine: CHHapticEngine) -> String? {
        do { try engine.start() } catch { return "haptics refused (\((error as NSError).code))" }
        // GameController haptics accept short simple patterns, not long dynamic players.
        engine.isAutoShutdownEnabled = false
        self.engine = engine
        return nil
    }

    /// nil on success, else the step that failed.
    private func startTap(pid: pid_t) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var input = pid, process = AudioObjectID(kAudioObjectUnknown), size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<pid_t>.size),
                &input, &size, &process) == noErr, process != kAudioObjectUnknown else { return "process has no audio" }
        let description = CATapDescription(stereoMixdownOfProcesses: [process])
        description.uuid = UUID(); description.isPrivate = true; description.muteBehavior = .unmuted
        let tapStatus = AudioHardwareCreateProcessTap(description, &tap)
        guard tapStatus == noErr else { return "tap refused (\(tapStatus))" }
        let settings: [String: Any] = [
            kAudioAggregateDeviceNameKey: "MG4L Haptics",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceTapListKey: [[kAudioSubTapUIDKey: description.uuid.uuidString, kAudioSubTapDriftCompensationKey: true]],
        ]
        let aggregateStatus = AudioHardwareCreateAggregateDevice(settings as CFDictionary, &aggregate)
        guard aggregateStatus == noErr else { return "aggregate refused (\(aggregateStatus))" }
        let status = AudioDeviceCreateIOProcIDWithBlock(&ioProc, aggregate, DispatchQueue(label: "mg4l.sound-haptics"),
            Self.ioBlock(meter))
        guard status == noErr, let ioProc else { return "io proc refused (\(status))" }
        let started = AudioDeviceStart(aggregate, ioProc)
        return started == noErr ? nil : "device start refused (\(started))"
    }

    /// One pulse per tick, a little longer than the tick so pulses overlap into a steady rumble.
    private static let tick = 0.05

    /// Built outside the main actor: Core Audio calls it on its own queue, and a block formed in a
    /// main-actor method would inherit that isolation and trap there.
    nonisolated static func ioBlock(_ meter: LowFrequencyMeter) -> AudioDeviceIOBlock {
        { _, data, _, _, _ in meter.consume(UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: data))) }
    }

    private func update() {
        let rms = meter.take()
        stats.ticks += 1; stats.maxRMS = max(stats.maxRMS, rms)
        let target = SoundHapticsCurve.intensity(forLevel: rms)
        // Fast attack, slower release, so hits land at once and fade naturally.
        level += (target - level) * (target > level ? 0.7 : 0.5)
        guard level >= 0.04, let engine else { return }
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: level),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)], relativeTime: 0, duration: Self.tick + 0.02)
        do {
            try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: [])).start(atTime: CHHapticTimeImmediate)
            stats.pulses += 1; consecutiveErrors = 0
        } catch {
            stats.errors += 1; consecutiveErrors += 1
            // A disconnected pad or a reset haptics server: stop, so the driver starts over in 3 s.
            if consecutiveErrors >= 20 { stop() }
        }
    }
}

/// Pure mapping from a low-pass RMS level to a haptic intensity: silent below -42 dBFS, full at -12.
enum SoundHapticsCurve {
    static func intensity(forLevel rms: Float) -> Float {
        guard rms > 0 else { return 0 }
        let db = 20 * log10(rms)
        return min(max((db + 42) / 30, 0), 1)
    }
}

/// Runs on the audio thread: a one-pole ~120 Hz low-pass over the mono mix, keeping the peak RMS
/// since the last `take()`.
final class LowFrequencyMeter: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: (filter: Float(0), peak: Float(0)))

    func consume(_ buffers: UnsafeMutableAudioBufferListPointer) {
        guard let first = buffers.first, let raw = first.mData else { return }
        let channels = max(Int(first.mNumberChannels), 1)
        let frames = Int(first.mDataByteSize) / (MemoryLayout<Float>.size * channels)
        guard frames > 0 else { return }
        let samples = raw.assumingMemoryBound(to: Float.self)
        let alpha: Float = 0.0156
        // Only the audio thread writes the filter, so it is read once and written back once.
        var y = state.withLock { $0.filter }, sum: Float = 0
        for frame in 0..<frames {
            var mono: Float = 0
            for channel in 0..<channels { mono += samples[frame * channels + channel] }
            y += alpha * (mono / Float(channels) - y)
            sum += y * y
        }
        let rms = (sum / Float(frames)).squareRoot(), filtered = y
        state.withLock { s in s.filter = filtered; s.peak = max(s.peak, rms) }
    }

    func take() -> Float { state.withLock { s in defer { s.peak = 0 }; return s.peak } }
}
