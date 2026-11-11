<p align="center"><img src="../assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">在 Mac 上玩《原神》《崩坏：星穹铁道》和《绝区零》。<br>面向 Apple Silicon 的原生 Liquid Glass 启动器。</p>

[![English](https://img.shields.io/badge/English-555555?style=for-the-badge)](../README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-555555?style=for-the-badge)](README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-555555?style=for-the-badge)](README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-555555?style=for-the-badge)](README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-0078D4?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=for-the-badge)](README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-555555?style=for-the-badge)](README.vi.md)

![启动器：侧边栏、绝区零美术图和 Play 栏](../assets/screenshots/launcher.jpg)

![主页](../assets/screenshots/home.jpg)

> 基于 [deruta74](https://github.com/deruta74) 的 [MacGacha](https://github.com/deruta74/MacGacha)，本项目使用其启动器引擎。请为[原项目](https://github.com/deruta74/MacGacha)点 Star。

## 功能

- **主页。** 每款游戏一张卡片，一键 Play，并显示游戏时长、剩余磁盘空间和最新的 HoYoPlay 活动。
- **每款游戏一个页面。** 全幅美术图、玻璃质感的操作栏，以及图形、帧率上限、性能悬浮层、游戏时长和磁盘占用卡片。
- **全程托管。** 从 HoYoverse 官方服务器安装、更新、修复和下载语音包，并管理 Wine、DXMT 与 D3DMetal。下载可暂停和继续。
- **帮助与性能。** 在网上搜索游戏问题、查看已知问题、附带系统信息反馈问题，并检查影响速度的设置。
- **菜单栏 Quick Play。** 游戏运行时启动器只显示静态图片，不与游戏争用 GPU。
- **可选扩展。** Metal 性能悬浮层、《原神》帧率解锁和环绕声，默认全部关闭。

## 安装

1. 从 [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest) 下载 `MacGacha-<版本>.dmg`，打开后将 **MacGacha** 拖到**应用程序**。
2. 打开应用。macOS 会提示无法验证开发者，因为 MacGacha 未经 Apple 公证。点击**完成**，打开**系统设置 → 隐私与安全性**，点击**仍要打开**。
3. 仍被拦截？在终端运行下面的命令，然后再打开应用：

```bash
xattr -dr com.apple.quarantine /Applications/MacGacha.app
```

需要搭载 Apple Silicon 且系统为 macOS 27 或更高版本的 Mac。缺少 Rosetta 2 时，首次启动会提示安装。更新通过应用菜单中的**检查更新…**获取。

## 帮助

发现问题或有想法？[提交 issue](https://github.com/silent9669/MacGacha4Life/issues)。遇到安装或启动问题时，请附上诊断包：侧边栏的**诊断** → **导出诊断包…**。其中的路径和令牌会被移除。

## 安全吗？

使用风险自负。为了在 Wine 下运行，MacGacha 使用社区的反作弊变通方案（jadeite、Steam 启动器垫片），可能违反 HoYoverse 的服务条款，存在封号可能。如果担心，可先用新的免费账号试用。会修改游戏进程的功能（例如《原神》帧率解锁）默认关闭，并在开启前提示风险。MacGacha 只从 HoYoverse 官方服务器下载游戏，校验每个文件，也从不索要你的密码。

MacGacha4Life 是非官方项目，与 HoYoverse（COGNOSPHERE）及 Apple Inc. 无关联。游戏名称和商标归各自所有者所有。此处的代码和文档可能借助 AI 代理编写。软件按现状提供，不提供任何担保。

## 致谢

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) ❤️ · [Wine](https://www.winehq.org) 与 CodeWeavers · 3Shain 的 [DXMT](https://github.com/3Shain/dxmt) · mkrsym1 的 [jadeite](https://codeberg.org/mkrsym1/jadeite) · 34736384 的 [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock)（MIT），帧率解锁采用其方法 · Valve 的 Proton，Steam 垫片的来源 · dbc-hbin 提供的 Wine 11.20 + D3DMetal 构建 · an-anime-team 与 Michael Nelson 对中国大陆崩溃问题的修复 · Apple 的 D3DMetal 和 Game Porting Toolkit，适用 Apple 的条款，应用会请你接受。

## 许可证

Copyright (C) 2026 deruta74 和 silent9669。依据 [GNU General Public License v3.0](../LICENSE) 发布的自由软件，并附加第 7(b) 条的一项条款（见 [NOTICE](../NOTICE)）：每个分发的副本和基于 MacGacha 的作品都必须在源码和“关于”界面中保留指向 https://github.com/deruta74/MacGacha 的链接。任何分发版本都必须继续使用 GPL-3.0 并提供源码。应用在运行时下载的组件和游戏本身适用各自的许可证。
