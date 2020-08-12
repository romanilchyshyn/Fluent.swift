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
    public private(set) var ptr: String.Index
    
    public init(source: String) {
        self.source = source
        ptr = source.startIndex
    }
    
    public func is_current_byte(_ c: Character) -> Bool {
        getCurrChar() == c
    }
    
    public func is_byte_at(_ c: Character, pos: String.Index) -> Bool {
        source[pos] == c
    }
    
    public mutating func expect_byte(_ c: Character) -> Result<Void, ParserError> {
        if !is_current_byte(c) {
            return .failure(.init(kind: .expectedToken(c), start: distanceFromStart()))
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
            switch getCurrChar() {
            case " ":
                advancePtr()
            case "\n":
                advancePtr()
            case "\r" where source[advancedPtr() ?? ptr] == "\n":
                advancePtr(offset: 2)
            default:
                break
            }
        }
    }
    
    public mutating func skip_blank_inline() -> UInt {
        let start = ptr
        while case .some(" ") = getCurrChar() {
            advancePtr()
        }
        
        return distanceFrom(index: start)
    }
    
    public mutating func skip_to_next_entry_start() {
        while case .some(let b) = getCurrChar() {
            let new_line = ptr == source.startIndex || source[source.index(ptr, offsetBy: -1)] == .some("\n")

            if new_line && (b.isASCII && b.isLetter || ["-", "#"].contains(b)) {
                break
            }

            advancePtr()
        }
    }
    
    public mutating func skip_eol() -> Bool {
        switch getCurrChar() {
        case .some("\n"):
            advancePtr()
            return true
        case .some("\r") where is_byte_at("\n", pos: advancedPtr() ?? ptr):
            advancePtr(offset: 2)
            return true
        default:
            return false
        }
    }
    
    public mutating func skip_unicode_escape_sequence(length: UInt) -> Result<Void, ParserError> {
        let start = self.ptr
        
        for _ in 0..<length {
            switch getCurrChar() {
            case .some(let b) where b.isASCII && b.isHexDigit:
                advancePtr()
            default:
                break
            }
        }
        
        if distanceFrom(index: start) != length {
            let end = ptr == source.endIndex ? ptr : advancedPtr() ?? ptr
            return .failure(
                .init(
                    kind: .invalidUnicodeEscapeSequence(String(source[start..<end])),
                    start: distanceFromStart()
                    )
                )
        }
        
        return .success(())
    }

    public func is_identifier_start() -> Bool {
        switch getCurrChar() {
        case .some(let b) where b.isASCII && b.isLetter:
            return true
        default:
            return false
        }
    }
    
    public func is_byte_pattern_continuation(b: Character) -> Bool {
        !["}", ".", "[", "*"].contains(b)
    }
    
    public func is_number_start() -> Bool {
        switch getCurrChar() {
        case .some(let b) where b == "-" || (b.isASCII && b.isNumber):
            return true
        default:
            return false
        }
    }
    
    public func is_eol() -> Bool {
        switch getCurrChar() {
        case .some("\n"):
            return true
        case .some("\r") where is_byte_at("\n", pos: advancedPtr() ?? ptr):
            return true
        default:
            return false
        }
    }
    
    public func get_slice(start: UInt, end: UInt) -> String {
        String(source[source.index(source.startIndex, offsetBy: Int(start))..<source.index(source.startIndex, offsetBy: Int(end))])
    }
    
    public mutating func skip_digits() -> Result<Void, ParserError> {
        let start = self.ptr
        
        while true {
            switch getCurrChar() {
            case .some(let b) where b.isASCII && b.isNumber:
                advancePtr()
            default:
                break
            }
        }
        
        if start == self.ptr {
            return .failure(
                .init(
                    kind: .expectedCharRange(range: "0-9"),
                    start: distanceFromStart()
                )
            )
        } else {
            return .success(())
        }
    }

    // MARK: Utils -
    
    private func getCurrChar() -> Character? {
        ptr == source.endIndex ? nil : source[ptr]
    }
    
    private mutating func advancePtr(offset: Int? = nil) {
        if let newPtr = advancedPtr(offset: offset) {
            ptr = newPtr
        }
    }
    
    private func advancedPtr(offset: Int? = nil) -> String.Index? {
        source.index(ptr, offsetBy: offset ?? 1, limitedBy: source.endIndex)
    }
    
    private func distanceFromStart() -> UInt {
        distanceFrom(index: source.startIndex)
    }
    
    private func distanceFrom(index: String.Index) -> UInt {
        UInt(source.distance(from: index, to: ptr))
    }
    
}
