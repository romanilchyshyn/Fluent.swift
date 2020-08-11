//
//  Unicode.swift
//  Fluent-syntax
//
//  Created by  Roman Ilchyshyn on 11.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

private let unknownChar: Character = "�"

private func encodeUnicode(_ s: String) -> Character? {
    return UInt32(s, radix: 16)
        .flatMap { n in UnicodeScalar(n) }
        .map { c in Character(c) }
}

public func unescapeUnicode(_ input: String) -> String {
    var result = ""

    var ptr = input.startIndex
    
    while ptr < input.endIndex {
        
        if input[ptr] != "\\" {
            result.append(input[ptr])
            ptr = input.index(after: ptr)
            continue;
        }
        
        ptr = input.index(after: ptr)
        
        let newChar: Character
        switch input[ptr] {
        case "\\":
            newChar = "\\"
        case "\"":
            newChar = "\""
        case let u where u == "u" || u == "U":
            let start = input.index(after: ptr)
            let len = u == "u" ? 4 : 6
            if let newPtr = input.index(ptr, offsetBy: len, limitedBy: input.endIndex) {
                ptr = newPtr
                newChar = encodeUnicode(String(input[start...ptr])) ?? unknownChar
            } else {
                ptr = input.endIndex
                newChar = unknownChar
                result.append(newChar)
                continue
            }
            
        default:
            newChar = unknownChar
        }
        
        result.append(newChar)
        
        ptr = input.index(after: ptr)
    }
    
    
    return result
}
