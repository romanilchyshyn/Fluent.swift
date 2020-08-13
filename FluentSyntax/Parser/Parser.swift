//
//  Parser.swift
//  FluentSyntax
//
//  Created by  Roman Ilchyshyn on 13.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

public struct ParseError: Error {
    public let resource: Resource
    public let errors: [ParserError]
}

public func parse(source: String) -> Result<Resource, ParseError> {
    var errors = [ParserError]()
    var ps = ParserStream(source: source)
    var body = [ResourceEntry]()
    
    _ = ps.skip_blank_block()
    var last_comment: Comment?
    var last_blank_count: UInt = 0
    
    while !ps.isEnd {
        let entry_start = ps.ptr
        var entry = get_entry(ps: &ps, entry_start: entry_start)
        
        if let comment = last_comment {
            switch entry {
            case .success(.message(let message)) where last_blank_count < 2:
                entry = .success(.message(message.updatedWithComment(comment)))
            case .success(.term(let term)) where last_blank_count < 2:
                entry = .success(.term(term.updatedWithComment(comment)))
            default:
                body.append(.entry(.comment(comment)))
            }
        }
        
        switch entry {
        case .success(.comment(let comment)):
            last_comment = comment
        case .success(let entry):
            body.append(.entry(entry))
        case .failure(let err):
            ps.skip_to_next_entry_start()
            let errWithSlice = err.updatedWithSlice(
                ParserError.Position(
                    start: ps.offset(to: entry_start),
                    end: ps.ptrOffset)
            )
            errors.append(errWithSlice)
            let slice = ps.get_slice(start: entry_start, end: ps.ptr)
            body.append(.junk(slice))
        }
        
        last_blank_count = ps.skip_blank_block()
    }
    
    if let last_comment = last_comment {
        body.append(.entry(.comment(last_comment)))
    }
    
    if errors.isEmpty {
        return .success(Resource(body: body))
    } else {
        return .failure(ParseError(resource: Resource(body: body), errors: errors))
    }
}

func get_entry(ps: inout ParserStream, entry_start: String.Index) -> Result<Entry, ParserError> {
    fatalError()
}
