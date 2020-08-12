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
        source[ptr] == c
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

    // MARK: Utils
    
    private mutating func advancePtr() {
        ptr = source.index(after: ptr)
    }
    
    private func distanceFromStart() -> UInt {
        UInt(source.distance(from: source.startIndex, to: ptr))
    }
    
}
