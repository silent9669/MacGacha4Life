<p align="center"><img src="assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">Play Genshin Impact, Honkai: Star Rail and Zenless Zone Zero on your Mac.<br>A native Liquid Glass launcher for Apple Silicon.</p>

[![English](https://img.shields.io/badge/English-0078D4?style=for-the-badge)](README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](readme/README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-555555?style=for-the-badge)](readme/README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-555555?style=for-the-badge)](readme/README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-555555?style=for-the-badge)](readme/README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-555555?style=for-the-badge)](readme/README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=for-the-badge)](readme/README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-555555?style=for-the-badge)](readme/README.vi.md)

![The launcher: sidebar, Zenless Zone Zero art and the Play bar](assets/screenshots/launcher.jpg)

![Home](assets/screenshots/home.jpg)
## Features

- **Home.** Every game as a card with one-click Play, your playtime, free disk space and the latest HoYoPlay events.
- **A page per game.** Full-bleed art, a glass action bar, and cards for graphics, frame limit, performance overlay, playtime and size on disk.
- **Load estimate.** A green, yellow or red dot beside each setting shows how hard it works your Mac.
- **Managed for you.** Installs, updates, repairs and voice packs from HoYoverse's official servers, plus Wine, DXMT and D3DMetal. Downloads pause and resume.
- **Help & Performance.** Search the web for a game's problems, read known issues, report a bug with your system info and check the settings that affect speed.
- **Menu bar Quick Play.** The launcher shows still images while you play, so it never competes with the game for the GPU.
- **Opt-in extras.** Metal performance overlay, Genshin frame-rate unlock and surround sound. All off by default.

## Install

1. Download `MacGacha4Life-<version>.dmg` from [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest), open it and drag **MG4L** to **Applications**.
2. Open the app. macOS says it can't verify the developer, because MacGacha isn't notarized by Apple. Click **Done**, open **System Settings → Privacy & Security** and click **Open Anyway**.
3. Still blocked? Run this in Terminal, then open the app again:

```bash
xattr -dr com.apple.quarantine /Applications/MG4L.app
```

Needs an Apple Silicon Mac with macOS 27 or later. Rosetta 2 is offered on first launch if it's missing. Updates arrive through **Check for Updates…** in the app menu.

## Help

Found a bug or have an idea? [Open an issue](https://github.com/silent9669/MacGacha4Life/issues). For install or launch problems, attach a diagnostics bundle: **Diagnostics** in the sidebar → **Export Diagnostic Bundle…**. It removes paths and tokens.

## Is it safe?

Use at your own risk. To run under Wine, MacGacha4Life uses community anti-cheat workarounds (jadeite, a Steam launcher shim) that may conflict with HoYoverse's Terms of Service, and a ban is possible. If you worry, try a new free-to-play account first. Features that change the game process, such as the Genshin Impact frame-rate unlock, are off by default and warn you before you turn them on. MacGacha4Life downloads games only from HoYoverse's official servers, verifies every file and never asks for your password.

MacGacha4Life is unofficial and not affiliated with HoYoverse (COGNOSPHERE) or Apple Inc. Game names and trademarks belong to their owners. Code and documentation here may be written with the help of AI agents. The software is provided as is, without warranty.

## Credits

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) · [Wine](https://www.winehq.org) and CodeWeavers · [DXMT](https://github.com/3Shain/dxmt) by 3Shain · [jadeite](https://codeberg.org/mkrsym1/jadeite) by mkrsym1 · [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock) by 34736384 (MIT), whose method the frame-rate unlock uses · Valve's Proton, source of the Steam shim · dbc-hbin for the Wine 11.20 + D3DMetal builds · an-anime-team and Michael Nelson for the Mainland China crash fix · Apple for D3DMetal and the Game Porting Toolkit, under Apple's terms, which the app asks you to accept.

## License

Copyright (C) 2026 silent9669. Free software under the [GNU General Public License v3.0](LICENSE) with one additional term under section 7(b) (see [NOTICE](NOTICE)): every distributed copy and work based on MacGacha4Life must keep the link to [https://github.com/silent9669/MacGacha4Life](https://github.com/silent9669/MacGacha4Life) in its source and About screen. Any distributed version must stay under GPL-3.0 with its source available. Components the app downloads at runtime, and the games, have their own licenses.
