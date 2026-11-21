// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Testing
@testable import Launch

/// Opt-in live check of the IOKit pad scan: `MACGACHA_LIVE_PADS=1 swift test
/// --package-path Packages/LauncherKit --filter PadProbeLiveTests` prints what
/// the registry reports for any connected DualSense.
@Suite(.timeLimit(.minutes(1))) struct PadProbeLiveTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MACGACHA_LIVE_PADS"] == "1"))
    func printsDualSenseTransports() {
        print("dualSenseTransports: \(SystemPadProbe().dualSenseTransports().sorted { "\($0)" < "\($1)" })")
    }
}
