//
//  Number.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 24.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

public enum FluentNumberStyle: String, RawRepresentable, Equatable {
    case decimal
    case currency
    case percent
    
    public init?(rawValue: String) {
        switch rawValue {
        case Self.decimal.rawValue:
            self = .decimal
        case Self.currency.rawValue:
            self = .currency
        case Self.percent.rawValue:
            self = .percent
        default:
            self = .decimal
        }
    }
    
    public init() {
        self = .decimal
    }
}

public enum FluentNumberCurrencyDisplayStyle: String, RawRepresentable, Equatable {
    case symbol
    case code
    case name
    
    public init?(rawValue: String) {
        switch rawValue {
        case Self.symbol.rawValue:
            self = .symbol
        case Self.code.rawValue:
            self = .code
        case Self.name.rawValue:
            self = .name
        default:
            self = .symbol
        }
    }
    
    public init() {
        self = .symbol
    }
}

public struct FluentNumberOptions: Equatable {
    public private(set) var style: FluentNumberStyle
    public private(set) var currency: String?
    public private(set) var currencyDisplay: FluentNumberCurrencyDisplayStyle
    public private(set) var useGrouping: Bool
    public private(set) var minimumIntegerDigits: Int?
    public private(set) var minimumFractionDigits: Int?
    public private(set) var maximumFractionDigits: Int?
    public private(set) var minimumSignificantDigits: Int?
    public private(set) var maximumSignificantDigits: Int?
    
    init() {
        style = .init()
        currency = nil
        currencyDisplay = .init()
        useGrouping = true
        minimumIntegerDigits = nil
        minimumFractionDigits = nil
        maximumFractionDigits = nil
        minimumSignificantDigits = nil
        maximumSignificantDigits = nil
    }
    
    init(
        style: FluentNumberStyle = .init(),
        currency: String? = nil,
        currencyDisplay: FluentNumberCurrencyDisplayStyle = .init(),
        useGrouping: Bool = true,
        minimumIntegerDigits: Int? = nil,
        minimumFractionDigits: Int? = nil,
        maximumFractionDigits: Int? = nil,
        minimumSignificantDigits: Int? = nil,
        maximumSignificantDigits: Int? = nil
    ) {
        self.style = style
        self.currency = currency
        self.currencyDisplay = currencyDisplay
        self.useGrouping = useGrouping
        self.minimumIntegerDigits = minimumIntegerDigits
        self.minimumFractionDigits = minimumFractionDigits
        self.maximumFractionDigits = maximumFractionDigits
        self.minimumSignificantDigits = minimumSignificantDigits
        self.maximumSignificantDigits = maximumSignificantDigits
    }
    
    public mutating func merge(opts: FluentArgs) {
        for (key, value) in opts {
            switch (key, value) {
            case ("style", .string(let n)):
                self.style = FluentNumberStyle(rawValue: n)!
            case ("currency", .string(let n)):
                self.currency = n
            case ("currencyDisplay", .string(let n)):
                self.currencyDisplay = FluentNumberCurrencyDisplayStyle(rawValue: n)!
            case ("minimumIntegerDigits", .number(let n)):
                self.minimumIntegerDigits = Int(n)
            case ("minimumFractionDigits", .number(let n)):
                self.minimumFractionDigits = Int(n)
            case ("maximumFractionDigits", .number(let n)):
                self.maximumFractionDigits = Int(n)
            case ("minimumSignificantDigits", .number(let n)):
                self.minimumSignificantDigits = Int(n)
            case ("maximumSignificantDigits", .number(let n)):
                self.maximumSignificantDigits = Int(n)
            default:
                break
            }
        }
    }
}

public struct FluentNumber: Equatable, CustomStringConvertible {
    public let value: Double
    public let options: FluentNumberOptions
    
    public init(value: Double, options: FluentNumberOptions) {
        self.value = value
        self.options = options
    }
    
    public init?(input: String) {
        guard let value = Double(input) else { return nil }
        let pos = input.firstIndex(of: ".")?.utf16Offset(in: input)
        let mfd: Int?
        if let pos = pos {
            mfd = input.count - pos - 1
        } else {
            mfd = nil
        }
        
        self.value = value
        self.options = FluentNumberOptions(minimumFractionDigits: mfd)
    }
    
    public var description: String {
        let val = "\(value)"
        guard let minfd = options.minimumFractionDigits else { return val }
        
        if let pos = val.firstIndex(of: ".")?.utf16Offset(in: val) {
            let frac_num = val.count - pos - 1
            let missing = frac_num > minfd ? 0 : minfd - frac_num
            return "\(val)\(String(repeating: "0", count: missing))"
        } else {
            return "\(val).\(String(repeating: "0", count: minfd))"
        }
    }
}

extension FluentValue {
    init(input: FluentNumber) {
        self = .number(input)
    }
}

extension Int {
    init(_ n: FluentNumber) {
        self = Int(n.value)
    }
}
