<p align="center"><img src="../assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">Jouez à Genshin Impact, Honkai: Star Rail et Zenless Zone Zero sur votre Mac.<br>Un lanceur Liquid Glass natif pour Apple Silicon.</p>

[![English](https://img.shields.io/badge/English-555555?style=for-the-badge)](../README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-555555?style=for-the-badge)](README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-555555?style=for-the-badge)](README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-0078D4?style=for-the-badge)](README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-555555?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=for-the-badge)](README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-555555?style=for-the-badge)](README.vi.md)

![Le lanceur : barre latérale, visuel de Zenless Zone Zero et barre Play](../assets/screenshots/launcher.jpg)

![Accueil](../assets/screenshots/home.jpg)

> Basé sur [MacGacha](https://github.com/deruta74/MacGacha) de [deruta74](https://github.com/deruta74), dont le moteur de lanceur est utilisé ici. Merci de soutenir le [projet d'origine](https://github.com/deruta74/MacGacha).

## Fonctionnalités

- **Accueil.** Chaque jeu en carte avec Play en un clic, votre temps de jeu, l'espace libre et les derniers événements HoYoPlay.
- **Une page par jeu.** Visuel plein cadre, barre d'action en verre et cartes pour le graphisme, la limite d'images, la superposition de performances, le temps de jeu et la taille sur le disque.
- **Tout est géré.** Installation, mises à jour, réparation et voix depuis les serveurs officiels de HoYoverse, plus Wine, DXMT et D3DMetal. Les téléchargements se mettent en pause.
- **Aide et performances.** Cherchez les problèmes d'un jeu sur le web, lisez les problèmes connus, signalez un bug avec les infos système et vérifiez les réglages qui influent sur la vitesse.
- **Quick Play dans la barre des menus.** Pendant que vous jouez, le lanceur affiche des images fixes et ne prend pas de GPU au jeu.
- **Extras facultatifs.** Superposition de performances Metal, déblocage de la fréquence d'images de Genshin et son surround. Tout est désactivé par défaut.

## Installation

1. Téléchargez `MacGacha4Life-<version>.dmg` depuis [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest), ouvrez-le et faites glisser **MG4L** dans **Applications**.
2. Ouvrez l'app. macOS indique qu'il ne peut pas vérifier le développeur, car MacGacha n'est pas notarié par Apple. Cliquez sur **Terminé**, ouvrez **Réglages Système → Confidentialité et sécurité** puis cliquez sur **Ouvrir quand même**.
3. Toujours bloquée ? Lancez ceci dans le Terminal, puis rouvrez l'app :

```bash
xattr -dr com.apple.quarantine /Applications/MG4L.app
```

Nécessite un Mac Apple Silicon sous macOS 27 ou plus récent. Rosetta 2 est proposé au premier lancement s'il manque. Les mises à jour passent par **Rechercher des mises à jour…** dans le menu de l'app.

## Aide

Un bug ou une idée ? [Ouvrez un ticket](https://github.com/silent9669/MacGacha4Life/issues). Pour un souci d'installation ou de lancement, joignez un lot de diagnostic : **Diagnostic** dans la barre latérale → **Exporter le lot de diagnostic…**. Les chemins et jetons en sont retirés.

## Est-ce sûr ?

À vos risques et périls. Pour tourner sous Wine, MacGacha utilise des contournements d'anti-triche de la communauté (jadeite, une couche Steam) qui peuvent enfreindre les conditions d'utilisation de HoYoverse, et un bannissement reste possible. En cas de doute, essayez d'abord avec un nouveau compte gratuit. Les fonctions qui modifient le processus du jeu, comme le déblocage de la fréquence d'images de Genshin Impact, sont désactivées par défaut et vous avertissent avant activation. MacGacha ne télécharge les jeux que depuis les serveurs officiels de HoYoverse, vérifie chaque fichier et ne demande jamais votre mot de passe.

MacGacha4Life est non officiel et sans lien avec HoYoverse (COGNOSPHERE) ni Apple Inc. Les noms de jeux et marques appartiennent à leurs propriétaires. Le code et la documentation peuvent être rédigés avec l'aide d'agents IA. Le logiciel est fourni tel quel, sans garantie.

## Remerciements

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) ❤️ · [Wine](https://www.winehq.org) et CodeWeavers · [DXMT](https://github.com/3Shain/dxmt) de 3Shain · [jadeite](https://codeberg.org/mkrsym1/jadeite) de mkrsym1 · [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock) de 34736384 (MIT), dont le déblocage reprend la méthode · Proton de Valve, source de la couche Steam · dbc-hbin pour les builds Wine 11.20 + D3DMetal · an-anime-team et Michael Nelson pour la correction du plantage en Chine continentale · Apple pour D3DMetal et le Game Porting Toolkit, selon les conditions d'Apple que l'app vous demande d'accepter.

## Licence

Copyright (C) 2026 deruta74 et silent9669. Logiciel libre sous [GNU General Public License v3.0](../LICENSE) avec une condition supplémentaire au titre de la section 7(b) (voir [NOTICE](../NOTICE)) : chaque copie distribuée et chaque œuvre dérivée de MacGacha doit conserver le lien vers https://github.com/deruta74/MacGacha dans son code source et son écran À propos. Toute version distribuée reste sous GPL-3.0 avec son code source. Les composants que l'app télécharge à l'exécution et les jeux ont leurs propres licences.
