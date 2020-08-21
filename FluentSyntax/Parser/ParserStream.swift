//
//  ParserStream.swift
//  FluentSyntax
//
//  Created by  Roman Ilchyshyn on 12.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

// FIXME: All byte related stuff needs renaming to `character`

public struct ParserStream {
    public let source: String
    public var ptr: String.Index
    
    public init(source: String) {
        self.source = source
        ptr = source.startIndex
    }
    
    public func is_current_byte(_ c: Character) -> Bool {
        currChar == c
    }
    
    public func is_byte_at(_ c: Character, pos: String.Index) -> Bool {
        pos < source.endIndex ? source[pos] == c : false
    }
    
    public mutating func expect_byte(_ c: Character) -> Result<Void, ParserError> {
        if !is_current_byte(c) {
            return .failure(.init(kind: .expectedToken(c), start: ptrOffset))
        }
        advancePtr()
        return .success(())
    }
    
    public mutating func take_byte_if(c: Character) -> Bool {
        if self.is_current_byte(c) {
            advancePtr()
            return true
        } else {
            return false
        }
    }
    
    public mutating func skip_blank_block() -> UInt {
        var count: UInt = 0
        while true {
            let start = ptr
            _ = skip_blank_inline()
            if !skip_eol() {
                ptr = start
                break
            }
            count += 1
        }
        
        return count
    }
    
    public mutating func skip_blank() {
        while true {
            switch currChar {
            case " ":
                advancePtr()
            case "\n",
                 "\r\n":
                advancePtr()
            default:
                return
            }
        }
    }
    
    public mutating func skip_blank_inline() -> UInt {
        let start = ptr
        while case .some(" ") = currChar {
            advancePtr()
        }
        
        return offset(from: start, to: ptr)
    }
    
    public mutating func skip_to_next_entry_start() {
        while case .some(let b) = currChar {
            let new_line = ptr == source.startIndex || source[source.index(ptr, offsetBy: -1)] == .some("\n")

            if new_line && (b.isASCIILetter || ["-", "#"].contains(b)) {
                break
            }

            advancePtr()
        }
    }
    
    public mutating func skip_eol() -> Bool {
        switch currChar {
        case "\n",
             "\r\n":
            advancePtr()
            return true
        default:
            return false
        }
    }
    
    public mutating func skip_unicode_escape_sequence(length: UInt) -> Result<Void, ParserError> {
        let start = self.ptr
        
        for _ in 0..<length {
            switch currChar {
            case .some(let b) where b.isASCII && b.isHexDigit:
                advancePtr()
            default:
                break
            }
        }
        
        if offset(from: start, to: ptr) != length {
            let end = isEnd ? ptr : advancedPtr() ?? ptr
            return .failure(
                .init(
                    kind: .invalidUnicodeEscapeSequence(String(source[start..<end])),
                    start: ptrOffset
                    )
                )
        }
        
        return .success(())
    }

    public func is_identifier_start() -> Bool {
        switch currChar {
        case .some(let b) where b.isASCIILetter:
            return true
        default:
            return false
        }
    }
    
    public func is_byte_pattern_continuation(b: Character) -> Bool {
        !["}", ".", "[", "*"].contains(b)
    }
    
    public func is_number_start() -> Bool {
        switch currChar {
        case .some(let b) where b == "-" || (b.isASCIINumber):
            return true
        default:
            return false
        }
    }
    
    public func is_eol() -> Bool {
        switch currChar {
        case "\n",
             "\r\n":
            return true
        default:
            return false
        }
    }
    
    public func get_slice(start: String.Index, end: String.Index) -> String {
        String(source[start..<end])
    }
    
    public mutating func skip_digits() -> Result<Void, ParserError> {
        let start = self.ptr
        
        loop: while true {
            switch currChar {
            case .some(let b) where b.isASCIINumber:
                advancePtr()
            default:
                break loop
            }
        }
        
        if start == self.ptr {
            return .failure(
                .init(
                    kind: .expectedCharRange(range: "0-9"),
                    start: ptrOffset
                )
            )
        } else {
            return .success(())
        }
    }

    // MARK: Utils -
    
    var isEnd: Bool {
        ptr == source.endIndex
    }
    
    var currChar: Character? {
         isEnd ? nil : source[ptr]
    }
    
    func charAt(_ index: String.Index) -> Character? {
        isEnd ? nil : source[index]
    }
    
    mutating func advancePtr(offset: Int? = nil) {
        if let newPtr = advancedPtr(offset: offset) {
            ptr = newPtr
        }
    }
    
    func advancedPtr(offset: Int? = nil) -> String.Index? {
        source.index(ptr, offsetBy: offset ?? 1, limitedBy: source.endIndex)
    }
    
    // MARK: Offsets
    
    var ptrOffset: UInt {
        offset(to: ptr)
    }
    
    func offset(to index: String.Index) -> UInt {
        offset(from: source.startIndex, to: index)
    }
    
    func offset(from fromIndex: String.Index, to toIndex: String.Index) -> UInt {
        UInt(source.distance(from: fromIndex, to: toIndex))
    }
    
}

// MARK: -

extension Character {
    var isASCIILetter: Bool { isASCII && isLetter }
    var isASCIINumber: Bool { isASCII && isNumber }
}
