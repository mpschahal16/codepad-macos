import Foundation

/// A text file encoding CodePad can read and write.
struct TextEncoding: Identifiable, Hashable {
    let id: String
    let name: String
    let stringEncoding: String.Encoding
    let byteOrderMark: [UInt8]

    static let utf8 = TextEncoding(
        id: "utf8",
        name: "UTF-8",
        stringEncoding: .utf8,
        byteOrderMark: []
    )
    static let utf8BOM = TextEncoding(
        id: "utf8-bom",
        name: "UTF-8 BOM",
        stringEncoding: .utf8,
        byteOrderMark: [0xEF, 0xBB, 0xBF]
    )
    static let utf16LittleEndian = TextEncoding(
        id: "utf16-le",
        name: "UTF-16 LE",
        stringEncoding: .utf16LittleEndian,
        byteOrderMark: [0xFF, 0xFE]
    )
    static let utf16BigEndian = TextEncoding(
        id: "utf16-be",
        name: "UTF-16 BE",
        stringEncoding: .utf16BigEndian,
        byteOrderMark: [0xFE, 0xFF]
    )
    static let utf32LittleEndian = TextEncoding(
        id: "utf32-le",
        name: "UTF-32 LE",
        stringEncoding: .utf32LittleEndian,
        byteOrderMark: [0xFF, 0xFE, 0x00, 0x00]
    )
    static let utf32BigEndian = TextEncoding(
        id: "utf32-be",
        name: "UTF-32 BE",
        stringEncoding: .utf32BigEndian,
        byteOrderMark: [0x00, 0x00, 0xFE, 0xFF]
    )
    static let latin1 = TextEncoding(
        id: "latin1",
        name: "ISO-8859-1",
        stringEncoding: .isoLatin1,
        byteOrderMark: []
    )

    static let all: [TextEncoding] = [
        .utf8, .utf8BOM, .utf16LittleEndian, .utf16BigEndian,
        .utf32LittleEndian, .utf32BigEndian, .latin1
    ]

    /// Decode bytes using a byte order mark when present, then UTF-8, and
    /// finally ISO-8859-1, which can represent every byte.
    static func decode(_ data: Data) -> (encoding: TextEncoding, text: String)? {
        let bytes = [UInt8](data.prefix(4))

        if bytes.starts(with: utf32BigEndian.byteOrderMark),
           let text = String(data: data.dropFirst(4), encoding: .utf32BigEndian) {
            return (.utf32BigEndian, text)
        }
        if bytes.starts(with: utf32LittleEndian.byteOrderMark),
           let text = String(data: data.dropFirst(4), encoding: .utf32LittleEndian) {
            return (.utf32LittleEndian, text)
        }
        if bytes.starts(with: utf8BOM.byteOrderMark),
           let text = String(data: data.dropFirst(3), encoding: .utf8) {
            return (.utf8BOM, text)
        }
        if bytes.starts(with: utf16BigEndian.byteOrderMark),
           let text = String(data: data.dropFirst(2), encoding: .utf16BigEndian) {
            return (.utf16BigEndian, text)
        }
        if bytes.starts(with: utf16LittleEndian.byteOrderMark),
           let text = String(data: data.dropFirst(2), encoding: .utf16LittleEndian) {
            return (.utf16LittleEndian, text)
        }
        if let text = String(data: data, encoding: .utf8) {
            return (.utf8, text)
        }
        if let text = String(data: data, encoding: .isoLatin1) {
            return (.latin1, text)
        }
        return nil
    }

    /// Encode text with the byte order mark this encoding is saved with.
    /// Returns nil when the text contains characters this encoding cannot represent.
    func encode(_ text: String) -> Data? {
        guard let body = text.data(using: stringEncoding) else { return nil }
        return Data(byteOrderMark) + body
    }
}
