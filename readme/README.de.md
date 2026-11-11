<p align="center"><img src="../assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">Spiele Genshin Impact, Honkai: Star Rail und Zenless Zone Zero auf deinem Mac.<br>Ein nativer Liquid-Glass-Launcher für Apple Silicon.</p>

[![English](https://img.shields.io/badge/English-555555?style=for-the-badge)](../README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-555555?style=for-the-badge)](README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-0078D4?style=for-the-badge)](README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-555555?style=for-the-badge)](README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-555555?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=for-the-badge)](README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-555555?style=for-the-badge)](README.vi.md)

![Der Launcher: Seitenleiste, Zenless-Zone-Zero-Artwork und Play-Leiste](../assets/screenshots/launcher.jpg)

![Start](../assets/screenshots/home.jpg)

> Basiert auf [MacGacha](https://github.com/deruta74/MacGacha) von [deruta74](https://github.com/deruta74), dessen Launcher-Engine dieses Projekt nutzt. Unterstütze bitte das [Originalprojekt](https://github.com/deruta74/MacGacha).

## Funktionen

- **Start.** Jedes Spiel als Karte mit Play per Klick, deine Spielzeit, freier Speicher und die neuesten HoYoPlay-Events.
- **Eine Seite pro Spiel.** Randlose Artworks, eine gläserne Aktionsleiste und Karten für Grafik, Framelimit, Leistungs-Overlay, Spielzeit und Größe auf dem Datenträger.
- **Alles verwaltet.** Installation, Updates, Reparatur und Sprachpakete von den offiziellen HoYoverse-Servern, dazu Wine, DXMT und D3DMetal. Downloads lassen sich pausieren.
- **Hilfe & Leistung.** Probleme eines Spiels im Web suchen, bekannte Probleme lesen, Fehler mit Systeminfos melden und die Einstellungen prüfen, die die Geschwindigkeit beeinflussen.
- **Quick Play in der Menüleiste.** Während du spielst, zeigt der Launcher Standbilder und nimmt dem Spiel keine GPU-Leistung weg.
- **Optionale Extras.** Metal-Leistungs-Overlay, Genshin-Framerate-Freischaltung und Surround-Sound. Standardmäßig alles aus.

## Installation

1. Lade `MacGacha-<Version>.dmg` von [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest) herunter, öffne die Datei und ziehe **MacGacha** in **Programme**.
2. Öffne die App. macOS meldet, dass der Entwickler nicht überprüft werden kann, weil MacGacha nicht von Apple notarisiert ist. Klicke auf **Fertig**, öffne **Systemeinstellungen → Datenschutz & Sicherheit** und klicke auf **Trotzdem öffnen**.
3. Wird sie weiter blockiert? Führe das im Terminal aus und öffne die App erneut:

```bash
xattr -dr com.apple.quarantine /Applications/MacGacha.app
```

Erfordert einen Mac mit Apple Silicon und macOS 27 oder neuer. Fehlt Rosetta 2, wird es beim ersten Start angeboten. Updates kommen über **Nach Updates suchen…** im App-Menü.

## Hilfe

Fehler gefunden oder eine Idee? [Eröffne ein Issue](https://github.com/silent9669/MacGacha4Life/issues). Bei Problemen mit Installation oder Start hänge ein Diagnosepaket an: **Diagnose** in der Seitenleiste → **Diagnosepaket exportieren…**. Pfade und Tokens werden entfernt.

## Ist das sicher?

Nutzung auf eigene Gefahr. Damit die Spiele unter Wine starten, nutzt MacGacha Anti-Cheat-Workarounds der Community (jadeite, einen Steam-Launcher-Shim). Sie können gegen die Nutzungsbedingungen von HoYoverse verstoßen, eine Sperrung ist möglich. Wenn du Bedenken hast, probiere es zuerst mit einem neuen Free-to-play-Konto. Funktionen, die den Spielprozess verändern, etwa die Framerate-Freischaltung für Genshin Impact, sind standardmäßig aus und warnen dich vor dem Einschalten. MacGacha lädt Spiele nur von den offiziellen HoYoverse-Servern, prüft jede Datei und fragt nie nach deinem Passwort.

MacGacha4Life ist inoffiziell und steht in keiner Verbindung zu HoYoverse (COGNOSPHERE) oder Apple Inc. Spielnamen und Marken gehören ihren Inhabern. Code und Dokumentation können mit Hilfe von KI-Agenten entstehen. Die Software wird ohne Gewähr bereitgestellt.

## Danksagung

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) ❤️ · [Wine](https://www.winehq.org) und CodeWeavers · [DXMT](https://github.com/3Shain/dxmt) von 3Shain · [jadeite](https://codeberg.org/mkrsym1/jadeite) von mkrsym1 · [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock) von 34736384 (MIT), dessen Methode die Framerate-Freischaltung nutzt · Valves Proton, Quelle des Steam-Shims · dbc-hbin für die Wine-11.20-+-D3DMetal-Builds · an-anime-team und Michael Nelson für die Korrektur des Absturzes in Festlandchina · Apple für D3DMetal und das Game Porting Toolkit zu Apples Bedingungen, die die App dich akzeptieren lässt.

## Lizenz

Copyright (C) 2026 deruta74 und silent9669. Freie Software unter der [GNU General Public License v3.0](../LICENSE) mit einer zusätzlichen Bedingung nach Abschnitt 7(b) (siehe [NOTICE](../NOTICE)): Jede weitergegebene Kopie und jedes auf MacGacha basierende Werk muss den Link zu https://github.com/deruta74/MacGacha im Quellcode und im Info-Bildschirm behalten. Jede weitergegebene Version bleibt unter GPL-3.0 mit verfügbarem Quellcode. Komponenten, die die App zur Laufzeit lädt, und die Spiele haben eigene Lizenzen.
