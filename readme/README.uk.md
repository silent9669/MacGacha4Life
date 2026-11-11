<p align="center"><img src="../assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">Грайте в Genshin Impact, Honkai: Star Rail і Zenless Zone Zero на Mac.<br>Нативний лаунчер Liquid Glass для Apple Silicon.</p>

[![English](https://img.shields.io/badge/English-555555?style=for-the-badge)](../README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-0078D4?style=for-the-badge)](README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-555555?style=for-the-badge)](README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-555555?style=for-the-badge)](README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-555555?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=for-the-badge)](README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-555555?style=for-the-badge)](README.vi.md)

![Лаунчер: бічна панель, арт Zenless Zone Zero і панель Play](../assets/screenshots/launcher.jpg)

![Головна](../assets/screenshots/home.jpg)

> Заснований на [MacGacha](https://github.com/deruta74/MacGacha) від [deruta74](https://github.com/deruta74): рушій лаунчера належить їм. Підтримайте [оригінальний проєкт](https://github.com/deruta74/MacGacha).

## Можливості

- **Головна.** Кожна гра — картка із запуском одним натисканням, час у грі, вільне місце та свіжі події HoYoPlay.
- **Сторінка гри.** Арт на всю ширину, скляна панель дій і картки: графіка, обмеження кадрів, оверлей продуктивності, час у грі та розмір на диску.
- **Усе під контролем.** Встановлення, оновлення, перевірка й озвучення з офіційних серверів HoYoverse, а також Wine, DXMT і D3DMetal. Завантаження можна ставити на паузу.
- **Допомога та продуктивність.** Пошук проблем гри в інтернеті, відомі проблеми, звіт про помилку з даними про систему та чекліст налаштувань, що впливають на швидкість.
- **Quick Play у рядку меню.** Поки гра працює, лаунчер показує статичні зображення й не забирає в неї GPU.
- **Додатково (за бажанням).** Оверлей Metal, розблокування частоти кадрів Genshin і об'ємний звук. Типово вимкнено.

## Встановлення

1. Завантажте `MacGacha4Life-<версія>.dmg` зі сторінки [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest), відкрийте його й перетягніть **MG4L** до **Програм**.
2. Відкрийте застосунок. macOS повідомить, що не може перевірити розробника: MacGacha не нотаризований Apple. Натисніть **Готово**, відкрийте **Системні налаштування → Конфіденційність і безпека** та натисніть **Усе одно відкрити**.
3. Усе ще блокується? Виконайте в Терміналі й відкрийте застосунок знову:

```bash
xattr -dr com.apple.quarantine /Applications/MG4L.app
```

Потрібен Mac з Apple Silicon і macOS 27 або новіша. Якщо Rosetta 2 немає, її запропонують встановити під час першого запуску. Оновлення надходять через **Перевірити оновлення…** в меню застосунку.

## Допомога

Знайшли помилку чи маєте ідею? [Створіть issue](https://github.com/silent9669/MacGacha4Life/issues). Із проблемами встановлення чи запуску додайте діагностичний архів: **Діагностика** в бічній панелі → **Експортувати діагностику…**. Шляхи й токени з нього вилучаються.

## Це безпечно?

Користуйтеся на власний ризик. Щоб ігри запускалися у Wine, MacGacha застосовує обхідні рішення для античита від спільноти (jadeite, прошарок Steam). Вони можуть суперечити умовам використання HoYoverse, тож блокування облікового запису можливе. Якщо маєте сумніви, спершу спробуйте новий безплатний обліковий запис. Функції, що змінюють процес гри, як-от розблокування частоти кадрів Genshin Impact, типово вимкнені й попереджають про ризик перед увімкненням. MacGacha завантажує ігри лише з офіційних серверів HoYoverse, перевіряє кожен файл і ніколи не просить пароль.

MacGacha4Life — неофіційний проєкт, не пов'язаний із HoYoverse (COGNOSPHERE) та Apple Inc. Назви ігор і торгові марки належать їхнім власникам. Код і документація можуть створюватися за допомогою ШІ-агентів. Програма надається «як є», без гарантій.

## Подяки

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) ❤️ · [Wine](https://www.winehq.org) і CodeWeavers · [DXMT](https://github.com/3Shain/dxmt) (3Shain) · [jadeite](https://codeberg.org/mkrsym1/jadeite) (mkrsym1) · [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock) (34736384, MIT): його метод використовує розблокування частоти кадрів · Proton від Valve — джерело прошарку Steam · dbc-hbin за збірки Wine 11.20 + D3DMetal · an-anime-team і Michael Nelson за виправлення збою в материковому Китаї · Apple за D3DMetal і Game Porting Toolkit на умовах Apple, які застосунок просить прийняти.

## Ліцензія

Copyright (C) 2026 deruta74 і silent9669. Вільне ПЗ за [GNU General Public License v3.0](../LICENSE) з однією додатковою умовою за розділом 7(b) (див. [NOTICE](../NOTICE)): кожна поширювана копія та кожний похідний від MacGacha твір мають зберігати посилання на https://github.com/deruta74/MacGacha у вихідному коді та на екрані «Про програму». Будь-яка поширювана версія лишається під GPL-3.0 із доступним кодом. Компоненти, які застосунок завантажує під час роботи, і самі ігри мають власні ліцензії.
