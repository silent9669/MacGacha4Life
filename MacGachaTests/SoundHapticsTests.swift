// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import CoreAudio
import Testing
@testable import MacGacha

struct SoundHapticsTests {
    @Test func curveIsSilentWhenQuietAndFullWhenLoud() {
        #expect(SoundHapticsCurve.intensity(forLevel: 0) == 0)
        #expect(SoundHapticsCurve.intensity(forLevel: 0.001) == 0)
        #expect(SoundHapticsCurve.intensity(forLevel: 0.5) == 1)
        let middle = SoundHapticsCurve.intensity(forLevel: 0.0447)
        #expect(middle > 0.45 && middle < 0.55)
    }

    @Test func meterFollowsBassAndIgnoresHighPitch() {
        func peak(frequency: Double) -> Float {
            let meter = LowFrequencyMeter(), frames = 4800
            var samples = (0..<frames).flatMap { i -> [Float] in
                let v = Float(0.8 * sin(2 * Double.pi * frequency * Double(i) / 48000)); return [v, v]
            }
            return samples.withUnsafeMutableBytes { raw in
                var list = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 2,
                    mDataByteSize: UInt32(raw.count), mData: raw.baseAddress))
                meter.consume(UnsafeMutableAudioBufferListPointer(&list))
                return meter.take()
            }
        }
        let bass = peak(frequency: 60), whistle = peak(frequency: 4000)
        #expect(bass > 0.25)
        #expect(whistle < bass / 10)
    }
}
