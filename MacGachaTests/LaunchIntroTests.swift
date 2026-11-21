// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Testing
@testable import MacGacha

struct LaunchIntroTests {
    @Test func frameStartsHiddenAndEndsOnTheIcon() {
        let first = IntroTimeline.frame(at: 0)
        #expect(first.split == 0)
        #expect(first.starScale == 0)
        #expect(first.wordOpacity == 0)
        #expect(first.ringOpacity == 0)
        let last = IntroTimeline.frame(at: IntroTimeline.duration)
        #expect(last.split == 0)
        #expect(last.starScale == 1)
        #expect(last.wordOpacity == 1)
    }

    @Test func frameClampsOutsideTheTimeline() {
        #expect(IntroTimeline.frame(at: -1) == IntroTimeline.frame(at: 0))
        #expect(IntroTimeline.frame(at: 99) == IntroTimeline.frame(at: IntroTimeline.duration))
    }

    @Test func halvesSeparateDuringThePullAndRejoin() {
        #expect(IntroTimeline.frame(at: 0.9).split > 0)
        #expect(IntroTimeline.frame(at: 1.15).split > 0)
        #expect(IntroTimeline.frame(at: IntroTimeline.duration).split == 0)
    }

    @Test func ringAndSparklesAreInvisibleAtBothEnds() {
        let first = IntroTimeline.frame(at: 0)
        let last = IntroTimeline.frame(at: IntroTimeline.duration)
        #expect(first.ringOpacity == 0)
        #expect(first.sparkles == 0)
        #expect(last.ringOpacity == 0)
        #expect(last.sparkles == 0)
    }

    @Test func shouldPlayOnlyWithMotionAllowedAndNoOtherDebugArguments() {
        #expect(LaunchIntro.shouldPlay(arguments: ["MacGacha"], userReduceMotion: false, systemReduceMotion: false) == true)
        #expect(LaunchIntro.shouldPlay(arguments: ["MacGacha"], userReduceMotion: true, systemReduceMotion: false) == false)
        #expect(LaunchIntro.shouldPlay(arguments: ["MacGacha"], userReduceMotion: false, systemReduceMotion: true) == false)
        #expect(LaunchIntro.shouldPlay(arguments: ["MacGacha", "-MacGachaDebugGame", "genshin"],
            userReduceMotion: false, systemReduceMotion: false) == false)
        #expect(LaunchIntro.shouldPlay(arguments: ["MacGacha", "-MacGachaDebugIntro"],
            userReduceMotion: false, systemReduceMotion: false) == true)
    }
}
