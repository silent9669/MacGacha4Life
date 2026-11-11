// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import CryptoKit
import Foundation

/// Wine's Mac driver replaces the Dock icon with the game's own square exe icon.
/// A Game Mode helper already carries a rounded icon, so its private copy of
/// `winemac.so` returns at once from `macdrv_set_application_icon`. The shared
/// runtime file is never changed.
enum WineMacIconPatch {
    static let module = "winemac.so"

    /// The patched module with its ad-hoc page hash kept valid, or nil for any
    /// layout other than a thin x86_64 image with that symbol and SHA-256 hashes.
    static func patched(_ data: Data) -> Data? {
        var bytes = [UInt8](data)
        func word(_ at: Int, width: Int = 4, big: Bool = false) -> Int? {
            guard at >= 0, at <= bytes.count - width else { return nil }
            let value = (0..<width).reduce(UInt64(0)) { $0 | UInt64(bytes[at + $1]) << UInt64((big ? width - $1 - 1 : $1) * 8) }
            return Int(exactly: value)
        }
        guard word(0) == 0xfeedfacf, word(4) == 0x0100_0007, let count = word(16), let size = word(20),
            count <= 8192, size <= bytes.count - 32 else { return nil }
        var segments: [(address: Int, length: Int, offset: Int)] = []
        var symbols: (offset: Int, count: Int, strings: Int, stringsSize: Int)?
        var signature: Int?
        var cursor = 32
        for _ in 0..<count {
            guard let kind = word(cursor), let length = word(cursor + 4), length >= 8, length <= 32 + size - cursor else { return nil }
            switch kind {
            case 0x19:
                guard let address = word(cursor + 24, width: 8), let offset = word(cursor + 40, width: 8), let fileSize = word(cursor + 48, width: 8) else { return nil }
                segments.append((address, fileSize, offset))
            case 0x2:
                guard let offset = word(cursor + 8), let number = word(cursor + 12), let strings = word(cursor + 16), let stringsSize = word(cursor + 20) else { return nil }
                symbols = (offset, number, strings, stringsSize)
            case 0x1d: signature = word(cursor + 8)
            default: break
            }
            cursor += length
        }
        guard let symbols, symbols.count <= 1 << 20, symbols.offset <= bytes.count - symbols.count * 16,
            symbols.strings <= bytes.count - symbols.stringsSize else { return nil }
        let name = Array("_macdrv_set_application_icon".utf8) + [0]
        var target: Int?
        for index in 0..<symbols.count {
            let entry = symbols.offset + index * 16
            guard let string = word(entry), let address = word(entry + 8, width: 8) else { return nil }
            // N_SECT: a symbol defined in this image.
            guard bytes[entry + 4] & 0x0e == 0x0e, string <= symbols.stringsSize - name.count,
                bytes[(symbols.strings + string)..<(symbols.strings + string + name.count)].elementsEqual(name) else { continue }
            guard let segment = segments.first(where: { address >= $0.address && address - $0.address < $0.length }) else { return nil }
            target = segment.offset + address - segment.address
            break
        }
        guard let target, target < bytes.count else { return nil }
        bytes[target] = 0xc3 // ret

        guard let signature else { return Data(bytes) }
        guard word(signature, big: true) == 0xfade_0cc0, let blobs = word(signature + 8, big: true), blobs <= 64 else { return nil }
        for index in 0..<blobs {
            guard let offset = word(signature + 16 + index * 8, big: true) else { return nil }
            let blob = signature + offset
            guard word(blob, big: true) == 0xfade_0c02 else { continue } // CodeDirectory
            guard let hashes = word(blob + 16, big: true), let slots = word(blob + 28, big: true), let limit = word(blob + 32, big: true),
                blob + 39 < bytes.count, bytes[blob + 36] == 32, bytes[blob + 37] == 2, (1...20).contains(bytes[blob + 39]) else { return nil }
            let shift = Int(bytes[blob + 39]), page = target >> shift, start = page << shift
            let end = min(start + 1 << shift, limit), slot = blob + hashes + page * 32
            guard page < slots, end > target, end <= bytes.count, slot <= bytes.count - 32 else { return nil }
            bytes.replaceSubrange(slot..<(slot + 32), with: Array(SHA256.hash(data: bytes[start..<end])))
        }
        return Data(bytes)
    }
}
