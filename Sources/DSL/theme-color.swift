/// A colour token: 24-bit sRGB, converted down for targets with fewer
/// colours. Encodes as `#rrggbb`.
public struct ThemeColor:
    Sendable,
    Hashable
{
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// `#rgb`, `#rrggbb`, `rgb(r g b)`, `rgb(r, g, b)` (integers or
    /// percentages; an alpha component is ignored).
    public init?(
        css source: String
    ) {
        let source = String(
            source
                .drop { $0 == " " }
                .reversed()
                .drop { $0 == " " }
                .reversed()
        ).lowercased()

        if source.hasPrefix("#") {
            guard let color = Self.hex(String(source.dropFirst())) else {
                return nil
            }
            self = color
            return
        }

        guard source.hasPrefix("rgb"),
              let open = source.firstIndex(of: "("),
              source.hasSuffix(")")
        else {
            return nil
        }

        let inner = source[source.index(after: open)..<source.index(before: source.endIndex)]
        let separators: Set<Character> = [",", " ", "/"]
        let arguments: [String] = inner
            .split { separators.contains($0) }
            .map { String($0) }

        guard arguments.count == 3 || arguments.count == 4 else {
            return nil
        }

        var channels: [UInt8] = []

        for argument in arguments.prefix(3) {
            guard let channel = Self.channel(argument) else {
                return nil
            }
            channels.append(channel)
        }

        self.init(
            red: channels[0],
            green: channels[1],
            blue: channels[2]
        )
    }

    public var hex: String {
        "#" + [red, green, blue].map { component in
            let digits = String(component, radix: 16)
            return digits.count == 1 ? "0" + digits : digits
        }.joined()
    }

    /// The nearest colour of the xterm 256-colour palette (cube or grey ramp).
    public var indexed: UInt8 {
        let levels: [Int] = [0, 95, 135, 175, 215, 255]

        func nearestLevel(_ value: UInt8) -> Int {
            levels.indices.min {
                abs(levels[$0] - Int(value)) < abs(levels[$1] - Int(value))
            } ?? 0
        }

        let r = nearestLevel(red)
        let g = nearestLevel(green)
        let b = nearestLevel(blue)
        let cube = (levels[r], levels[g], levels[b])
        let cubeIndex = 16 + 36 * r + 6 * g + b

        let average = (Int(red) + Int(green) + Int(blue)) / 3
        let step = min(23, max(0, (average - 8 + 5) / 10))
        let grey = 8 + 10 * step

        let cubeDistance = distance(to: cube)
        let greyDistance = distance(to: (grey, grey, grey))

        return UInt8(greyDistance < cubeDistance ? 232 + step : cubeIndex)
    }

    /// The nearest of the 16 standard terminal colours (0–7 normal, 8–15
    /// bright), by xterm's default palette.
    public var basic: UInt8 {
        let index = Self.basicPalette.indices.min {
            distance(to: Self.basicPalette[$0]) < distance(to: Self.basicPalette[$1])
        } ?? 0
        return UInt8(index)
    }
}

extension ThemeColor: Codable {
    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        let source = try container.decode(String.self)

        guard let color = ThemeColor(css: source) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "not a CSS colour: \(source)"
            )
        }

        self = color
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }
}

private extension ThemeColor {
    static let basicPalette: [(Int, Int, Int)] = [
        (0, 0, 0), (205, 0, 0), (0, 205, 0), (205, 205, 0),
        (0, 0, 238), (205, 0, 205), (0, 205, 205), (229, 229, 229),
        (127, 127, 127), (255, 0, 0), (0, 255, 0), (255, 255, 0),
        (92, 92, 255), (255, 0, 255), (0, 255, 255), (255, 255, 255),
    ]

    func distance(
        to other: (Int, Int, Int)
    ) -> Int {
        let r = Int(red) - other.0
        let g = Int(green) - other.1
        let b = Int(blue) - other.2
        return r * r + g * g + b * b
    }

    static func hex(
        _ digits: String
    ) -> ThemeColor? {
        let expanded: String

        switch digits.count {
        case 3:
            expanded = digits.map { "\($0)\($0)" }.joined()
        case 6:
            expanded = digits
        default:
            return nil
        }

        guard let value = UInt32(expanded, radix: 16) else {
            return nil
        }

        return .init(
            red: UInt8((value >> 16) & 0xff),
            green: UInt8((value >> 8) & 0xff),
            blue: UInt8(value & 0xff)
        )
    }

    static func channel(
        _ argument: String
    ) -> UInt8? {
        if argument.hasSuffix("%") {
            guard let percent = Double(argument.dropLast()),
                  (0...100).contains(percent)
            else {
                return nil
            }
            return UInt8((percent * 255 / 100).rounded())
        }

        guard let value = Double(argument),
              (0...255).contains(value)
        else {
            return nil
        }

        return UInt8(value.rounded())
    }
}
