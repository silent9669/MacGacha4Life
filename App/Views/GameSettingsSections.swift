// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Launch
import LauncherCore
import RuntimeManager
import SwiftUI

/// How one game launches, right on its page. Every change is saved at once and applies the next time Play is pressed.
/// The strip draws it as one compact panel: fixed-height hairline rows, labels left, controls right.
struct GameSettingsSections: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame

    @State private var showsFpsRisk = false
    @State private var customFpsTarget = false
    @State private var mac = MacProfile.current()

    private var settings: Binding<LaunchSettings> {
        Binding(
            get: { model.launchSettings(for: game.id) },
            set: { newValue in
                do { try model.saveLaunchSettings(newValue, for: game.id) } catch { model.show(error) }
            }
        )
    }

    /// With one display there is nothing to choose, unless a choice was saved while another was connected.
    private var offersDisplayChoice: Bool {
        model.connectedDisplays.count > 1 || settings.wrappedValue.display != nil
    }

    private var missingDisplay: DisplayChoice? {
        guard let chosen = settings.wrappedValue.display,
            !model.connectedDisplays.contains(where: { $0.id == chosen.id }) else { return nil }
        return chosen
    }

    /// Selects by ID so a display that reports a new name still matches the saved choice.
    private var displayID: Binding<String?> {
        Binding(
            get: { settings.wrappedValue.display?.id },
            set: { id in
                var value = settings.wrappedValue
                if let id {
                    let name = model.connectedDisplays.first { $0.id == id }?.name ?? value.display?.name ?? ""
                    value.display = DisplayChoice(id: id, name: name)
                } else {
                    value.display = nil
                }
                settings.wrappedValue = value
            }
        )
    }

    private static func name(of display: String) -> String {
        display.isEmpty ? String(localized: "Unnamed Display") : display
    }

    /// Star Rail stores its frame rate in its own settings, which accept 30, 60 or 120.
    private var offersStarRailUnlock: Bool { LaunchResolver.offersStarRailUnlock(game.id) }

    /// Turning the unlock on lifts a lower frame limit, so the unlock isn't silently capped.
    private var unlockFPS: Binding<Bool> {
        Binding(
            get: { settings.wrappedValue.unlockFPS },
            set: { isOn in
                var value = settings.wrappedValue
                value.unlockFPS = isOn
                if isOn, let limit = value.frameLimit, limit < value.unlockTarget { value.frameLimit = value.unlockTarget }
                settings.wrappedValue = value
            }
        )
    }

    /// The first time it's turned on, the risk warning has to be confirmed before the switch moves.
    private var genshinFpsUnlock: Binding<Bool> {
        Binding(
            get: { model.genshinFpsUnlock(for: game.id) },
            set: { isOn in
                if isOn, !model.genshinFpsRiskAcknowledged {
                    showsFpsRisk = true
                    return
                }
                do { try model.setGenshinFpsUnlock(isOn, for: game.id) } catch { model.show(error) }
            }
        )
    }

    private var genshinFpsTarget: Binding<Int> {
        Binding(
            get: { model.genshinFpsTarget(for: game.id) },
            set: { target in
                do { try model.setGenshinFpsTarget(target, for: game.id) } catch { model.show(error) }
            }
        )
    }

    private var genshinFpsCustom: Binding<Bool> {
        Binding(
            get: { customFpsTarget },
            set: { custom in
                customFpsTarget = custom
                if !custom { genshinFpsTarget.wrappedValue = 120 }
            }
        )
    }

    private var genshinTarget: Int? {
        model.offersGenshinFps(for: game.id) && model.genshinFpsUnlock(for: game.id) ? model.genshinFpsTarget(for: game.id) : nil
    }

    private var frames: Int { settings.wrappedValue.frameLimit ?? genshinTarget ?? PerformanceEstimate.frames(for: settings.wrappedValue) }

    /// Only Zenless Zone Zero has a DirectX 12 renderer, and only D3DMetal runs it.
    private var offersDirectX12: Bool { Recipes.recipe(for: game.id)?.supportsDirectX12 == true }

    /// One setting row: label (with its load dot) left, the switch sharing the
    /// trailing edge with the segmented pickers. Labels shrink before they truncate.
    private func toggleRow(_ title: LocalizedStringKey, _ level: LoadLevel,
        isOn: Binding<Bool>, hairline: Bool = true, disabled: Bool = false) -> some View {
        PanelRow(hairline: hairline) {
            cell(title, level)
        } control: {
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .disabled(disabled)
                .gamepadTarget("setting-\(String(describing: title))") { if !disabled { isOn.wrappedValue.toggle() } }
        }
    }

    /// A row label: one line, shrinking before it truncates.
    private func cell(_ title: LocalizedStringKey, _ level: LoadLevel) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            LoadDot(level: level)
        }
    }

    /// The one toggle that depends on the game: DirectX 12 for ZZZ, the FPS unlocks for
    /// Star Rail and Genshin, nothing for a game without one.
    @ViewBuilder private var perGameToggle: some View {
        if offersDirectX12 {
            toggleRow("DirectX 12", settings.wrappedValue.directX12 ? PerformanceEstimate.directX12Level(mac: mac) : .light,
                isOn: settings.directX12, disabled: settings.wrappedValue.backend != .d3dmetal)
        } else if offersStarRailUnlock {
            toggleRow("Unlock 120 FPS", unlockFPS.wrappedValue ? PerformanceEstimate.level(frames: settings.wrappedValue.unlockTarget, mac: mac) : .light,
                isOn: unlockFPS)
        } else if model.offersGenshinFps(for: game.id) {
            toggleRow("Unlock frame rate", genshinFpsUnlock.wrappedValue ? PerformanceEstimate.level(frames: genshinFpsTarget.wrappedValue, mac: mac) : .light,
                isOn: genshinFpsUnlock)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
        StripPanel(title: "Settings") {
            PanelContent(height: 26) {
                LoadSummary(estimate: PerformanceEstimate.estimate(settings.wrappedValue, mac: mac, genshinTarget: genshinTarget), compact: true)
            }
            PanelRow(height: 28) {
                Text("Graphics")
            } control: {
                Picker("Graphics", selection: settings.backend) {
                    Text("D3DMetal", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.d3dmetal)
                    Text("DXMT", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.dxmt)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .gamepadTarget("setting-graphics") {
                    settings.backend.wrappedValue = settings.backend.wrappedValue == .d3dmetal ? .dxmt : .d3dmetal
                }
            }
            PanelRow(height: 28) {
                cell("Frame limit", PerformanceEstimate.level(frames: frames, mac: mac))
            } control: {
                // Five segments need ~200 pt; a menu keeps the label whole when
                // the strip column is too narrow for the segmented control.
                ViewThatFits(in: .horizontal) {
                    Picker("Frame limit", selection: settings.frameLimit) {
                        Text("Off").tag(Int?.none)
                        ForEach([30, 60, 90, 120], id: \.self) { fps in
                            Text(fps.formatted()).tag(Int?.some(fps))
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    Picker("Frame limit", selection: settings.frameLimit) {
                        Text("Off").tag(Int?.none)
                        ForEach([30, 60, 90, 120], id: \.self) { fps in
                            Text(fps.formatted()).tag(Int?.some(fps))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                }
                .gamepadTarget("setting-frame-limit") {
                    let limits: [Int?] = [nil, 30, 60, 90, 120]
                    let index = limits.firstIndex(of: settings.frameLimit.wrappedValue) ?? 0
                    settings.frameLimit.wrappedValue = limits[(index + 1) % limits.count]
                }
            }
            if model.offersGenshinFps(for: game.id), genshinFpsUnlock.wrappedValue {
                PanelRow(height: 28) {
                    Text("Target")
                } control: {
                    Picker("Target", selection: genshinFpsCustom) {
                        Text(120.formatted()).tag(false)
                        Text("Custom").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                }
                if customFpsTarget {
                    PanelRow(height: 28) {
                        Text("Frames per second")
                    } control: {
                        TextField("Frames per second", value: genshinFpsTarget, format: .number,
                            prompt: Text(verbatim: "61–360"))
                            .labelsHidden()
                            .frame(width: 72)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            if offersDisplayChoice {
                PanelRow(height: 28) {
                    Text("Display")
                } control: {
                    Picker("Display", selection: displayID) {
                        Text("Main Display").tag(String?.none)
                        ForEach(model.connectedDisplays, id: \.id) { display in
                            Text(Self.name(of: display.name)).tag(String?.some(display.id))
                        }
                        if let missing = missingDisplay {
                            Text("\(Self.name(of: missing.name)) (Not Connected)",
                                comment: "A chosen display that is unplugged; the argument is its name")
                                .tag(String?.some(missing.id))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }
            perGameToggle
            toggleRow("Retina resolution", settings.wrappedValue.retina ? PerformanceEstimate.retinaLevel(mac: mac) : .light,
                isOn: settings.retina)
            toggleRow("Performance overlay", .light, isOn: settings.metalHUD)
            if model.offersSurround(for: game.id) {
                toggleRow("Surround sound", .light, isOn: settings.surroundSound)
            }
            PanelRow(hairline: false) {
                Text("Compatibility patches")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } control: {
                Toggle("Compatibility patches", isOn: settings.compatibilityPatches)
                    .labelsHidden()
                    .gamepadTarget("setting-compatibility") { settings.compatibilityPatches.wrappedValue.toggle() }
            }
        }
        // The only note the page keeps: HoYoverse may treat the FPS helper as third-party.
        if model.offersGenshinFps(for: game.id) {
            Text("Loads a small helper into the game that raises its 60 FPS limit. HoYoverse may treat it as a third-party tool, so use it at your own risk.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        }
        .onAppear { customFpsTarget = model.genshinFpsTarget(for: game.id) != 120 }
        .sheet(isPresented: $showsFpsRisk) {
            FpsRiskSheet(gameName: game.name) {
                model.acknowledgeGenshinFpsRisk()
                do { try model.setGenshinFpsUnlock(true, for: game.id) } catch { model.show(error) }
            }
        }
    }

}
