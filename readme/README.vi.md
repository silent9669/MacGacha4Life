<p align="center"><img src="../assets/icon.png" width="112" alt="MacGacha4Life icon"></p>
<h1 align="center">MacGacha4Life</h1>
<p align="center">Chơi Genshin Impact, Honkai: Star Rail và Zenless Zone Zero trên Mac.<br>Trình khởi chạy Liquid Glass gốc cho Apple Silicon.</p>

[![English](https://img.shields.io/badge/English-555555?style=for-the-badge)](../README.md)
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-555555?style=for-the-badge)](README.ru.md)
[![Українська](https://img.shields.io/badge/%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0-555555?style=for-the-badge)](README.uk.md)
[![Deutsch](https://img.shields.io/badge/Deutsch-555555?style=for-the-badge)](README.de.md)
[![Français](https://img.shields.io/badge/Fran%C3%A7ais-555555?style=for-the-badge)](README.fr.md)
[![简体中文](https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-555555?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=for-the-badge)](README.ja.md)
[![Tiếng Việt](https://img.shields.io/badge/Ti%E1%BA%BFng_Vi%E1%BB%87t-0078D4?style=for-the-badge)](README.vi.md)

![Trình khởi chạy: thanh bên, ảnh Zenless Zone Zero và thanh Play](../assets/screenshots/launcher.jpg)

![Trang chủ](../assets/screenshots/home.jpg)

## Tính năng

- **Trang chủ.** Mỗi game là một thẻ với nút Play một chạm, thời gian chơi, dung lượng trống và các sự kiện HoYoPlay mới nhất.
- **Mỗi game một trang.** Ảnh nghệ thuật tràn viền, thanh thao tác kính mờ và các thẻ về đồ họa, giới hạn khung hình, lớp phủ hiệu năng, thời gian chơi và dung lượng trên ổ đĩa.
- **Được quản lý giúp bạn.** Cài đặt, cập nhật, sửa chữa và gói giọng nói từ máy chủ chính thức của HoYoverse, cùng Wine, DXMT và D3DMetal. Có thể tạm dừng và tiếp tục tải xuống.
- **Trợ giúp & Hiệu năng.** Tìm trên web các sự cố của game, xem lỗi đã biết, báo lỗi kèm thông tin hệ thống và kiểm tra các cài đặt ảnh hưởng đến tốc độ.
- **Quick Play trên thanh menu.** Trình khởi chạy chỉ hiện ảnh tĩnh khi bạn chơi, nên không tranh GPU với game.
- **Tính năng tùy chọn.** Lớp phủ hiệu năng Metal, mở khóa tốc độ khung hình Genshin và âm thanh vòm. Tất cả đều tắt theo mặc định.

## Cài đặt

1. Tải `MacGacha4Life-<phiên bản>.dmg` từ [Releases](https://github.com/silent9669/MacGacha4Life/releases/latest), mở ra và kéo **MG4L** vào **Applications**.
2. Mở ứng dụng. macOS báo không thể xác minh nhà phát triển vì MacGacha chưa được Apple công chứng. Nhấn **Xong**, mở **Cài đặt Hệ thống → Quyền riêng tư & Bảo mật** và nhấn **Vẫn mở**.
3. Vẫn bị chặn? Chạy lệnh sau trong Terminal rồi mở lại ứng dụng:

```bash
xattr -dr com.apple.quarantine /Applications/MG4L.app
```

Cần Mac Apple Silicon với macOS 27 trở lên. Nếu chưa có Rosetta 2, ứng dụng sẽ đề nghị cài khi mở lần đầu. Cập nhật qua **Kiểm tra cập nhật…** trong menu ứng dụng.

## Trợ giúp

Gặp lỗi hoặc có ý tưởng? [Mở một issue](https://github.com/silent9669/MacGacha4Life/issues). Với sự cố cài đặt hoặc khởi chạy, hãy đính kèm gói chẩn đoán: **Chẩn đoán** ở thanh bên → **Xuất gói chẩn đoán…**. Gói này đã loại bỏ đường dẫn và token.

## Có an toàn không?

Hãy tự chịu rủi ro. Để chạy trên Wine, MacGacha4Life dùng các giải pháp chống gian lận của cộng đồng (jadeite, lớp giả lập trình khởi chạy Steam) có thể vi phạm Điều khoản Dịch vụ của HoYoverse, và có nguy cơ bị khóa tài khoản. Nếu lo ngại, hãy thử với một tài khoản miễn phí mới trước. Các tính năng can thiệp vào tiến trình game, như mở khóa tốc độ khung hình Genshin Impact, tắt theo mặc định và cảnh báo bạn trước khi bật. MacGacha4Life chỉ tải game từ máy chủ chính thức của HoYoverse, xác minh từng tệp và không bao giờ hỏi mật khẩu của bạn.

MacGacha4Life là dự án không chính thức, không liên kết với HoYoverse (COGNOSPHERE) hay Apple Inc. Tên game và thương hiệu thuộc về chủ sở hữu của chúng. Mã nguồn và tài liệu ở đây có thể được viết với sự hỗ trợ của tác nhân AI. Phần mềm được cung cấp nguyên trạng, không bảo hành.

## Ghi công

[deruta74/MacGacha](https://github.com/deruta74/MacGacha) · [Wine](https://www.winehq.org) và CodeWeavers · [DXMT](https://github.com/3Shain/dxmt) của 3Shain · [jadeite](https://codeberg.org/mkrsym1/jadeite) của mkrsym1 · [genshin-fps-unlock](https://github.com/34736384/genshin-fps-unlock) của 34736384 (MIT), phương pháp của dự án này được dùng cho tính năng mở khóa tốc độ khung hình · Proton của Valve, nguồn của lớp giả lập Steam · dbc-hbin cho bản dựng Wine 11.20 + D3DMetal · an-anime-team và Michael Nelson cho bản sửa lỗi treo ở Trung Quốc đại lục · Apple cho D3DMetal và Game Porting Toolkit, theo điều khoản của Apple mà ứng dụng yêu cầu bạn chấp nhận.

## Giấy phép

Copyright (C) 2026 silent9669. Phần mềm tự do theo [GNU General Public License v3.0](../LICENSE) với một điều khoản bổ sung theo mục 7(b) (xem [NOTICE](../NOTICE)): mọi bản sao được phân phối và mọi tác phẩm dựa trên MacGacha4Life phải giữ liên kết tới [https://github.com/silent9669/MacGacha4Life](https://github.com/silent9669/MacGacha4Life) trong mã nguồn và màn hình Giới thiệu. Mọi phiên bản được phân phối phải giữ giấy phép GPL-3.0 và có sẵn mã nguồn. Các thành phần ứng dụng tải về khi chạy, cùng các game, có giấy phép riêng.
