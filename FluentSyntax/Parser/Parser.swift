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
    let result: Result<Entry, ParserError>
    switch ps.currChar! { // FIXME: Force unwrap
    case "#":
        result = get_comment(ps: &ps).map { .comment($0) }
    case "-":
        result = get_term(ps: &ps, entry_start: entry_start).map { .term($0) }
    default:
        result = get_message(ps: &ps, entry_start: entry_start).map { .message($0) }
    }
    
    return result
}

func get_message(ps: inout ParserStream, entry_start: String.Index) -> Result<Message, ParserError> {
    fatalError()
}

func get_term(ps: inout ParserStream, entry_start: String.Index) -> Result<Term, ParserError> {
    fatalError()
}


func get_identifier(ps: inout ParserStream) -> Result<Identifier, ParserError> {
    let start = ps.ptr
    
    switch ps.currChar {
    case .some(let c) where c.isASCIILetter:
        ps.advancePtr()
    default:
        return .failure(.init(kind: .expectedCharRange(range: "a-zA-Z"), start: ps.ptrOffset))
    }
    
    while case .some(let c) = ps.currChar {
        if c.isASCIILetter || c.isASCIINumber || ["_", "-"].contains(c) {
            ps.advancePtr()
        } else {
            break
        }
    }
    
    let name = ps.get_slice(start: start, end: ps.ptr)
    
    return .success(.init(name: name))
}

// -

func get_comment(ps: inout ParserStream) -> Result<Comment, ParserError> {
    fatalError()
}

// -

func get_number_literal(ps: inout ParserStream) -> Result<String, ParserError> {
    let start = ps.ptr
    _ = ps.take_byte_if(c: "-")
    
    var result = ps.skip_digits()
    if ps.take_byte_if(c: ".") {
        result = ps.skip_digits()
    }

    return result.map { _ in ps.get_slice(start: start, end: ps.ptr) }
}
