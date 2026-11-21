// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Testing
@testable import MacGacha

struct MotionPolicyTests {
    @Test func reducedWhenAnyInputAsksForIt() {
        #expect(MotionPolicy.reduced(user: false, system: false, gameRunning: false) == false)
        #expect(MotionPolicy.reduced(user: true, system: false, gameRunning: false) == true)
        #expect(MotionPolicy.reduced(user: false, system: true, gameRunning: false) == true)
        #expect(MotionPolicy.reduced(user: false, system: false, gameRunning: true) == true)
        #expect(MotionPolicy.reduced(user: true, system: true, gameRunning: true) == true)
    }
}
