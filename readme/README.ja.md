<p align="center"><img src="../assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">Mac で『原神』『崩壊：スターレイル』『ゼンレスゾーンゼロ』を遊ぼう。<br>Apple Silicon 向けのネイティブな Liquid Glass ランチャー。</p>

[![English](https://img.shields.io/badge/English-555555?style=for-the-badge)](../README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-555555?style=for-the-badge)](README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-555555?style=for-the-badge)](README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-555555?style=for-the-badge)](README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-555555?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-0078D4?style=for-the-badge)](README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-555555?style=for-the-badge)](README.vi.md)

![ランチャー：サイドバー、ゼンレスゾーンゼロのアートと Play バー](../assets/screenshots/launcher.jpg)

![ホーム](../assets/screenshots/home.jpg)

> [deruta74](https://github.com/deruta74) の [MacGacha](https://github.com/deruta74/MacGacha) をもとにしています。ランチャーのエンジンはオリジナルのものです。[オリジナルのプロジェクト](https://github.com/deruta74/MacGacha)にもぜひスターを。

## 機能

- **ホーム。** 各ゲームをカードで表示。ワンクリックで Play でき、プレイ時間、空き容量、最新の HoYoPlay イベントも確認できます。
- **ゲームごとのページ。** 全面アート、ガラス調のアクションバー、グラフィックス、フレーム上限、パフォーマンスオーバーレイ、プレイ時間、ディスク使用量のカード。
- **お任せ管理。** HoYoverse の公式サーバーからインストール、アップデート、修復、音声パックの取得を行い、Wine、DXMT、D3DMetal も管理します。ダウンロードは一時停止できます。
- **ヘルプとパフォーマンス。** ゲームの問題をウェブで検索し、既知の問題を確認し、システム情報つきで不具合を報告し、速度に影響する設定をチェックできます。
- **メニューバーから Quick Play。** プレイ中のランチャーは静止画を表示し、ゲームと GPU を奪い合いません。
- **オプション機能。** Metal パフォーマンスオーバーレイ、『原神』のフレームレート解除、サラウンド。すべて初期設定ではオフです。

## インストール

1. [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest) から `MacGacha4Life-<バージョン>.dmg` をダウンロードして開き、**MG4L** を**アプリケーション**にドラッグします。
2. アプリを開きます。MacGacha は Apple の公証を受けていないため、macOS は開発元を確認できないと表示します。**完了**をクリックし、**システム設定 → プライバシーとセキュリティ**を開いて**このまま開く**をクリックします。
3. それでもブロックされる場合は、ターミナルで次を実行してからアプリを開き直してください：

```bash
xattr -dr com.apple.quarantine /Applications/MG4L.app
```

Apple Silicon の Mac と macOS 27 以降が必要です。Rosetta 2 がない場合は初回起動時にインストールを案内します。アップデートはアプリメニューの**アップデートを確認…**から届きます。

## ヘルプ

不具合やアイデアがあれば [issue を作成](https://github.com/silent9669/MacGacha4Life/issues)してください。インストールや起動の問題では、診断バンドルを添付してください：サイドバーの**診断** → **診断バンドルを書き出す…**。パスとトークンは取り除かれます。

## 安全ですか？

自己責任でご利用ください。Wine で動かすため、MacGacha はコミュニティのアンチチートの回避策（jadeite、Steam ランチャーのシム）を使います。これらは HoYoverse の利用規約に反する可能性があり、アカウント停止の恐れがあります。不安な場合は、まず新しい基本無料のアカウントで試してください。『原神』のフレームレート解除のようにゲームのプロセスを変更する機能は初期設定でオフで、オンにする前に警告します。MacGacha は HoYoverse の公式サーバーからのみゲームをダウンロードし、すべてのファイルを検証し、パスワードを求めることはありません。

MacGacha4Life は非公式のプロジェクトで、HoYoverse（COGNOSPHERE）および Apple Inc. とは関係ありません。ゲーム名と商標は各所有者に帰属します。ここにあるコードとドキュメントは AI エージェントの支援で作成されている場合があります。本ソフトウェアは現状のまま、保証なしで提供されます。

## 謝辞

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) ❤️ · [Wine](https://www.winehq.org) と CodeWeavers · 3Shain の [DXMT](https://github.com/3Shain/dxmt) · mkrsym1 の [jadeite](https://codeberg.org/mkrsym1/jadeite) · 34736384 の [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock)（MIT）：フレームレート解除はその手法を使っています · Steam シムの元になった Valve の Proton · Wine 11.20 + D3DMetal ビルドを提供した dbc-hbin · 中国本土でのクラッシュ修正の an-anime-team と Michael Nelson · D3DMetal と Game Porting Toolkit の Apple（Apple の条件が適用され、アプリが同意を求めます）。

## ライセンス

Copyright (C) 2026 deruta74 and silent9669. [GNU General Public License v3.0](../LICENSE) の自由ソフトウェアで、第 7(b) 条に基づく追加条件が 1 つあります（[NOTICE](../NOTICE) を参照）。配布するすべてのコピーと MacGacha に基づく成果物は、ソースコードと「このアプリについて」画面に https://github.com/deruta74/MacGacha へのリンクを残す必要があります。配布するすべてのバージョンは GPL-3.0 のままでソースを公開します。アプリが実行時にダウンロードするコンポーネントとゲームには、それぞれ別のライセンスが適用されます。
