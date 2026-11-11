// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Launch
import Testing
@testable import MacGacha

struct PerformanceEstimateTests {
    private func mac(_ tier: MacProfile.Tier = .base, memory: Int = 16, lowPower: Bool = false) -> MacProfile {
        MacProfile(tier: tier, memoryGB: memory, lowPowerMode: lowPower)
    }

    private func settings(retina: Bool = false, limit: Int? = 60) -> LaunchSettings {
        LaunchSettings(backend: .d3dmetal, retina: retina, frameLimit: limit, directX12: false, compatibilityPatches: true)
    }

    @Test(arguments: [("Apple M2", MacProfile.Tier.base), ("Apple M3 Pro", .pro), ("Apple M4 Max", .max), ("Apple M2 Ultra", .ultra)])
    func chipFamilyDecidesTheTier(brand: String, tier: MacProfile.Tier) {
        #expect(MacProfile.tier(brand: brand) == tier)
    }

    @Test func retinaIsHeavyOnABaseChipAndLightOnAMax() {
        #expect(PerformanceEstimate.retinaLevel(mac: mac(.base)) == .heavy)
        #expect(PerformanceEstimate.retinaLevel(mac: mac(.pro)) == .moderate)
        #expect(PerformanceEstimate.retinaLevel(mac: mac(.max)) == .light)
    }

    @Test func eightGigabytesMakeRetinaOneStepWorse() {
        #expect(PerformanceEstimate.retinaLevel(mac: mac(.max, memory: 8)) == .moderate)
    }

    @Test func higherFrameRatesCostMore() {
        let chip = mac(.base)
        #expect(PerformanceEstimate.level(frames: 30, mac: chip) == .light)
        #expect(PerformanceEstimate.level(frames: 60, mac: chip) == .light)
        #expect(PerformanceEstimate.level(frames: 120, mac: chip) == .moderate)
        #expect(PerformanceEstimate.level(frames: 150, mac: chip) == .heavy)
    }

    @Test func noFrameLimitCountsAsUncapped() {
        let result = PerformanceEstimate.estimate(settings(limit: nil), mac: mac(.base))
        #expect(result.level == .heavy)
        #expect(result.reasons.contains(.uncapped))
    }

    @Test func overallCombinesPixelsAndFrames() {
        #expect(PerformanceEstimate.estimate(settings(), mac: mac(.pro)).level == .light)
        let heavy = PerformanceEstimate.estimate(settings(retina: true, limit: 120), mac: mac(.pro))
        #expect(heavy.level == .heavy)
        #expect(heavy.reasons == [.retina, .highFrameRate])
    }

    @Test func lowPowerModeLowersTheHeadroomAndSaysSo() {
        let normal = PerformanceEstimate.estimate(settings(limit: 120), mac: mac(.pro))
        let saving = PerformanceEstimate.estimate(settings(limit: 120), mac: mac(.pro, lowPower: true))
        #expect(saving.level > normal.level)
        #expect(saving.reasons.contains(.lowPower))
    }

    @Test func aGenshinUnlockTargetStandsInForTheFrameLimit() {
        let result = PerformanceEstimate.estimate(settings(limit: nil), mac: mac(.pro), genshinTarget: 60)
        #expect(result.level == .light)
        #expect(!result.reasons.contains(.uncapped))
    }
}
