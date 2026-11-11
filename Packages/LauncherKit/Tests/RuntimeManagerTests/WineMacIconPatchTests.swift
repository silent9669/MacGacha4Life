// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Testing
@testable import RuntimeManager

@Test func iconPatchRefusesUnknownImages() {
    #expect(WineMacIconPatch.patched(Data()) == nil)
    #expect(WineMacIconPatch.patched(Data([0xcf, 0xfa, 0xed, 0xfe] + [UInt8](repeating: 0xff, count: 4096))) == nil)
    #expect(WineMacIconPatch.patched(Data([0xcf, 0xfa, 0xed, 0xfe, 7, 0, 0, 1] + [UInt8](repeating: 0, count: 4096))) == nil)
}

/// `MACGACHA_WINEMAC=/absolute/winemac.so` checks a real module: one code byte and
/// one page hash change, and the ad-hoc signature still verifies.
@Test(.enabled(if: ProcessInfo.processInfo.environment["MACGACHA_WINEMAC"] != nil)) func iconPatchKeepsARealModuleSigned() throws {
    let original = try Data(contentsOf: URL(fileURLWithPath: ProcessInfo.processInfo.environment["MACGACHA_WINEMAC"]!))
    let patched = try #require(WineMacIconPatch.patched(original))
    #expect(patched.count == original.count)
    let changed = zip(original, patched).enumerated().filter { $0.element.0 != $0.element.1 }.map(\.offset)
    #expect(changed.count <= 33 && patched[changed[0]] == 0xc3)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("winemac-\(UUID().uuidString).so")
    try patched.write(to: url); defer { try? FileManager.default.removeItem(at: url) }
    let verify = Process()
    verify.executableURL = URL(fileURLWithPath: "/usr/bin/codesign"); verify.arguments = ["--verify", "--strict", url.path]
    try verify.run(); verify.waitUntilExit()
    #expect(verify.terminationStatus == 0)
}
