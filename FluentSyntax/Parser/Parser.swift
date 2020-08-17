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
    let id = get_identifier(ps: &ps)
    if case .failure(let err) = id { return .failure(err) }
    
    _ = ps.skip_blank_inline();
    
    let expectByte = ps.expect_byte("=")
    if case .failure(let err) = expectByte { return .failure(err) }
    
    // FIXME: Continue implementation
//    let value = get_pattern(ps)?;
    
    fatalError()
}

func get_term(ps: inout ParserStream, entry_start: String.Index) -> Result<Term, ParserError> {
    fatalError()
}

func get_attributes(ps: inout ParserStream) -> Result<[Attribute], ParserError> {
    var attributes: [Attribute] = []
    
    while true {
        let line_start = ps.ptr
        _ = ps.skip_blank_inline()
        if !ps.is_current_byte(".") {
            ps.ptr = line_start;
            break;
        }
        
        switch get_attribute(ps: &ps) {
        case .success(let a):
            attributes.append(a)
        case .failure:
            ps.ptr = line_start
            break
        }
    }
    
    return .success(attributes)
}

func get_attribute(ps: inout ParserStream) -> Result<Attribute, ParserError> {
    if case .failure(let err) = ps.expect_byte(".") { return .failure(err) }
    
    let idRes = get_identifier(ps: &ps)
    let id: Identifier
    switch idRes {
    case .success(let i):
        id = i
    case .failure(let err):
        return .failure(err)
    }
    
    _ = ps.skip_blank_inline();
    if case .failure(let err) = ps.expect_byte("=") { return .failure(err) }
    
    let patternRes = get_pattern(ps: &ps)
    let pattern: Pattern?
    switch patternRes {
    case .success(let p):
        pattern = p
    case .failure(let err):
        return .failure(err)
    }

    if let pattern = pattern {
        return .success(.init(id: id, value: pattern))
    } else {
        return .failure(.init(kind: .missingValue, start: ps.ptrOffset))
    }
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

func get_attribute_accessor(ps: inout ParserStream) -> Result<Identifier?, ParserError> {
    if !ps.take_byte_if(c: ".") {
        return .success(nil)
    } else {
        let ident = get_identifier(ps: &ps)
        return ident.map { .some($0) }
    }
}

func get_variant_key(ps: inout ParserStream) -> Result<VariantKey, ParserError> {
    if !ps.take_byte_if(c: "[") {
        return .failure(.init(kind: .expectedToken("["), start: ps.ptrOffset))
    }
    ps.skip_blank()

    let key: VariantKey
    if ps.is_number_start() {
        switch get_number_literal(ps: &ps) {
        case .success(let v):
            key = .numberLiteral(value: v)
        case .failure(let err):
            return .failure(err)
        }
    } else {
        switch get_identifier(ps: &ps) {
        case .success(let v):
            key = .identifier(name: v.name)
        case .failure(let err):
            return .failure(err)
        }
    }

    ps.skip_blank()

    if case .failure(let err) = ps.expect_byte("]") { return .failure(err) }
    
    return .success(key)
}

func get_variants(ps: inout ParserStream) -> Result<[Variant], ParserError> {
    var variants: [Variant] = []
    var has_default = false
    
    while ps.is_current_byte("*") || ps.is_current_byte("[") {
        let defaultVariant = ps.take_byte_if(c: "*")
        if defaultVariant {
            if has_default {
                return .failure(.init(kind: .multipleDefaultVariants, start: ps.ptrOffset))
            } else {
                has_default = true
            }
        }
        
        let keyRes = get_variant_key(ps: &ps)
        let key: VariantKey
        switch keyRes {
        case .success(let k):
            key = k
        case .failure(let err):
            return .failure(err)
        }
        
        let valueRes = get_pattern(ps: &ps)
        let value: Pattern?
        switch valueRes {
        case .success(let v):
            value = v
        case .failure(let err):
            return .failure(err)
        }
        
        if let value = value {
            variants.append(.init(key: key, value: value, default: defaultVariant))
            ps.skip_blank()
        } else {
            return .failure(.init(kind: .missingValue, start: ps.ptrOffset))
        }
        
    }
    
    if !has_default {
        return .failure(.init(kind: .missingDefaultVariant, start: ps.ptrOffset))
    } else {
        return .success(variants)
    }
}

enum TextElementTermination: Equatable {
    case LineFeed
    case CRLF
    case PlaceableStart
    case EOF
}

enum TextElementPosition: Equatable {
    case InitialLineStart
    case LineStart
    case Continuation
}

enum PatternElementPlaceholders: Equatable {
    case Placeable(Expression)
    case TextElement(start: String.Index, end: String.Index, indent: UInt, position: TextElementPosition)
}

enum TextElementType: Equatable {
    case Blank
    case NonBlank
}

func get_pattern(ps: inout ParserStream) -> Result<Pattern?, ParserError> {
    var elements: [PatternElementPlaceholders] = []
    var last_non_blank: Int?
    var common_indent: UInt?
    
    _ = ps.skip_blank_inline()
    
    var text_element_role: TextElementPosition
    if ps.skip_eol() {
        _ = ps.skip_blank_block()
        text_element_role = .LineStart
    } else {
        text_element_role = .InitialLineStart
    }
    
    while !ps.isEnd {
        if ps.currChar == "{" {
            if text_element_role == .LineStart {
                common_indent = 0
            }
            
            let expRes = get_placeable(ps: &ps)
            let exp: Expression
            switch expRes {
            case .success(let e):
                exp = e
            case .failure(let err):
                return .failure(err)
            }
            last_non_blank = elements.count
            elements.append(.Placeable(exp));
            text_element_role = .Continuation
        } else {
            let slice_start = ps.ptr
            var indent: UInt = 0
            
            if text_element_role == .LineStart {
                indent = ps.skip_blank_inline()
                if ps.isEnd {
                    break
                }
                let b = ps.currChar!
                if indent == 0 {
                    if b == "\n" {
                        break
                    }
                } else if !ps.is_byte_pattern_continuation(b: b) {
                    ps.ptr = slice_start
                    break
                }
            }
            
            let textSliceRes = get_text_slice(ps: &ps)
            let textSlice: (start: String.Index, end: String.Index, text_element_type: TextElementType, termination_reason: TextElementTermination)
            switch textSliceRes {
            case .success(let tuple):
                textSlice = tuple
            case .failure(let err):
                return .failure(err)
            }
            
            if textSlice.start != textSlice.end {
                if text_element_role == .LineStart || textSlice.text_element_type == .NonBlank {
                    if case .some(let common) = common_indent {
                        if indent < common {
                            common_indent = indent
                        }
                    } else {
                        common_indent = indent
                    }
                }
                
                if text_element_role != .LineStart
                    || textSlice.text_element_type == .NonBlank
                    || textSlice.termination_reason == .LineFeed {
                    
                    if textSlice.text_element_type == .NonBlank {
                        last_non_blank = elements.count
                    }
                    elements.append(.TextElement(
                        start: textSlice.start,
                        end: textSlice.end,
                        indent: indent,
                        position: text_element_role)
                    )
                }
            }
            
            switch textSlice.termination_reason {
            case .LineFeed:
                text_element_role = .LineStart
            case .CRLF:
                text_element_role = .Continuation
            case .PlaceableStart:
                text_element_role = .Continuation
            case .EOF:
                text_element_role = .Continuation
            }
            
        }
        
    }
    
    if let last_non_blank = last_non_blank {
        let elements: [PatternElement] = elements[..<(last_non_blank + 1)].enumerated().map { (i, elem) in
            switch elem {
            case .Placeable(let exp):
                return .placeable(exp)
            case .TextElement(let start, let end, let indent, let role):
                let updatedStart: String.Index
                if role == .LineStart {
                    if let common_indent = common_indent {
                        updatedStart = ps.source.index(start, offsetBy: Int(min(indent, common_indent)), limitedBy: ps.source.endIndex) ?? start
                    } else {
                        updatedStart = ps.source.index(start, offsetBy: Int(indent), limitedBy: ps.source.endIndex) ?? start
                    }
                } else {
                    updatedStart = start
                }
                
                let slice = ps.get_slice(start: updatedStart, end: end)
                
                if last_non_blank == i {
                    return .textElement(slice) // slice.trim_end()
                } else {
                    return .textElement(slice)
                }
            }
            
        }
        
        return .success(.init(elements: elements))
    }
    
    return .success(nil)
}

func get_text_slice(ps: inout ParserStream) -> Result<(String.Index, String.Index, TextElementType, TextElementTermination), ParserError> {
    let start_pos = ps.ptr
    var text_element_type: TextElementType = .Blank
    
    while !ps.isEnd {
        switch ps.currChar {
        case " ":
            ps.advancePtr()
        case "\n":
            ps.advancePtr()
            return .success((start_pos, ps.ptr, text_element_type, .LineFeed))
        case "\r" where ps.is_byte_at("\n", pos: ps.advancedPtr() ?? ps.ptr):
            ps.advancePtr()
            return .success((start_pos, ps.ptr, text_element_type, .CRLF))
        case "{":
            return .success((start_pos, ps.ptr, text_element_type, .PlaceableStart))
        case "}":
            return .failure(.init(kind: .unbalancedClosingBrace, start: ps.ptrOffset))
        default:
            text_element_type = .NonBlank
            ps.advancePtr()
        }
    }
    
    return .success((start_pos, ps.ptr, text_element_type, .EOF))
}

func get_comment(ps: inout ParserStream) -> Result<Comment, ParserError> {
    fatalError()
}

func get_placeable(ps: inout ParserStream) -> Result<Expression, ParserError> {
    if case .failure(let err) = ps.expect_byte("{") { return .failure(err) }
    ps.skip_blank();
    
    let expRes = get_expression(ps: &ps)
    let exp: Expression
    switch expRes {
    case .success(let e):
        exp = e
    case .failure(let err):
        return .failure(err)
    }
    
    _ = ps.skip_blank_inline()
    if case .failure(let err) = ps.expect_byte("}") { return .failure(err) }
    
    let invalid_expression_found: Bool
    switch exp {
    case .inlineExpression(.termReference(_, let attribute, _)):
        invalid_expression_found = attribute != nil
    default:
        invalid_expression_found = false
    }
    
    if invalid_expression_found {
        return .failure(.init(kind: .termAttributeAsPlaceable, start: ps.ptrOffset))
    }
    
    return .success(exp)
}

func get_expression(ps: inout ParserStream) -> Result<Expression, ParserError> {
    let expRes = get_inline_expression(ps: &ps)
    let exp: InlineExpression
    switch expRes {
    case .success(let e):
        exp = e
    case .failure(let err):
        return .failure(err)
    }
    
    ps.skip_blank()
    
    if !ps.is_current_byte("-") || !ps.is_byte_at(">", pos: ps.advancedPtr() ?? ps.ptr) {
        if case .termReference(_, let attribute, _) = exp,
            attribute != nil {
            return .failure(.init(kind: .termAttributeAsPlaceable, start: ps.ptrOffset))
        }
        return .success(.inlineExpression(exp))
    }
    
    switch exp {
    case .messageReference(_, let attribute):
        if attribute == nil {
            return .failure(.init(kind: .messageReferenceAsSelector, start: ps.ptrOffset))
        } else {
            return .failure(.init(kind: .messageAttributeAsSelector, start: ps.ptrOffset))
        }
    case .termReference(_, let attribute, _):
        if attribute == nil {
            return .failure(.init(kind: .termReferenceAsSelector, start: ps.ptrOffset))
        }
    case .stringLiteral,
         .numberLiteral,
         .variableReference,
         .functionReference:
        break
    default:
        return .failure(.init(kind: .expectedSimpleExpressionAsSelector, start: ps.ptrOffset))
    }
    
    ps.advancePtr(offset: 2)
    
    _ = ps.skip_blank_inline()
    if !ps.skip_eol() {
        return .failure(.init(kind: .expectedCharRange(range: "\n | \r\n"), start: ps.ptrOffset))
    }
    ps.skip_blank()
    
    let variants = get_variants(ps: &ps)
    
    return variants.map { .selectExpression(selector: exp, variants: $0) }
}

func get_inline_expression(ps: inout ParserStream) -> Result<InlineExpression, ParserError> {
    switch ps.currChar {
    case "\"":
        ps.advancePtr()
        let start = ps.ptr
        while !ps.isEnd {
            switch ps.currChar {
            case "\\":
                guard let nextPtr = ps.advancedPtr() else { return .failure(.init(kind: .generic, start: ps.ptrOffset)) }
                switch ps.charAt(nextPtr) {
                case "\\":
                    ps.advancePtr(offset: 2)
                case "{":
                    ps.advancePtr(offset: 2)
                case "\"":
                    ps.advancePtr(offset: 2)
                case "u":
                    ps.advancePtr(offset: 2)
                    if case .failure(let err) = ps.skip_unicode_escape_sequence(length: 4) { return .failure(err) }
                case "U":
                    ps.advancePtr(offset: 2)
                    if case .failure(let err) = ps.skip_unicode_escape_sequence(length: 6) { return .failure(err) }
                default:
                    return .failure(.init(kind: .generic, start: ps.ptrOffset))
                }
                
            case "\"":
                break
            case "\n":
                return .failure(.init(kind: .generic, start: ps.ptrOffset))
            default:
                ps.advancePtr()
            }
        }
        
        if case .failure(let err) = ps.expect_byte("\"") { return .failure(err) }
        let slice = ps.get_slice(start: start, end: ps.advancedPtr(offset: -1) ?? ps.ptr)
        return .success(.stringLiteral(value: slice))
    
    case let b where b?.isASCIINumber == true:
        let num = get_number_literal(ps: &ps)
        return num.map { .numberLiteral(value: $0) }
        
    case "-":
        ps.advancePtr()
        if ps.is_identifier_start() {
            // FIXME: Refactor ugly error mapping
            
            let idRes = get_identifier(ps: &ps)
            let id: Identifier
            switch idRes {
            case .success(let i):
                id = i
            case .failure(let err):
                return .failure(err)
            }
            
            let attributeRes = get_attribute_accessor(ps: &ps)
            let attribute: Identifier?
            switch attributeRes {
            case .success(let a):
                attribute = a
            case .failure(let err):
                return .failure(err)
            }
            
            let argumentsRes = get_call_arguments(ps: &ps)
            let arguments: CallArguments?
            switch argumentsRes {
            case .success(let a):
                arguments = a
            case .failure(let err):
                return .failure(err)
            }
            
            return .success(.termReference(id: id, attribute: attribute, arguments: arguments))
            
        } else {
            ps.advancePtr(offset: -1)
            let num = get_number_literal(ps: &ps)
            return num.map { .numberLiteral(value: $0) }
        }
    case "$":
        ps.advancePtr()
        let id = get_identifier(ps: &ps)
        return id.map { .variableReference(id: $0) }
        
    case let b where b?.isASCIILetter == true:
        // FIXME: Refactor ugly error mapping
        
        let idRes = get_identifier(ps: &ps)
        let id: Identifier
        switch idRes {
        case .success(let i):
            id = i
        case .failure(let err):
            return .failure(err)
        }
        
        let argumentsRes = get_call_arguments(ps: &ps)
        let arguments: CallArguments?
        switch argumentsRes {
        case .success(let a):
            arguments = a
        case .failure(let err):
            return .failure(err)
        }
        
        if let arguments = arguments {
            for b in id.name {
                let isValidChar = (b.isASCII && b.isUppercase) || b.isASCIINumber || b == "_" || b == "-"
                if !isValidChar {
                    return .failure(.init(kind: .forbiddenCallee, start: ps.ptrOffset))
                }
            }
            
            return .success(.functionReference(id: id, arguments: arguments))
        } else {
            let attributeRes = get_attribute_accessor(ps: &ps)
            let attribute: Identifier?
            switch attributeRes {
            case .success(let a):
                attribute = a
            case .failure(let err):
                return .failure(err)
            }
            
            return .success(.messageReference(id: id, attribute: attribute))
        }
    
    case "{":
        let exp = get_placeable(ps: &ps)
        return exp.map { .placeable(expression: $0) }
        
    default:
        return .failure(.init(kind: .expectedInlineExpression, start: ps.ptrOffset))
    }
}

func get_call_arguments(ps: inout ParserStream) -> Result<CallArguments?, ParserError> {
    ps.skip_blank()
    if !ps.take_byte_if(c: "(") {
        return .success(nil)
    }
    
    var positional: [InlineExpression] = []
    var named: [NamedArgument] = []
    var argument_names: [String] = []
    
    while !ps.isEnd {
        if ps.currChar == ")" {
            break;
        }
        
        let exprRes = get_inline_expression(ps: &ps)
        let expr: InlineExpression
        switch exprRes {
        case .success(let e):
            expr = e
        case .failure(let err):
            return .failure(err)
        }
        
        switch expr {
        case .messageReference(let id, nil):
            if ps.is_current_byte(":") {
                if argument_names.contains(id.name) {
                    return .failure(.init(kind: .duplicatedNamedArgument(id.name), start: ps.ptrOffset))
                }
                ps.advancePtr()
                ps.skip_blank()
                
                let valRes = get_inline_expression(ps: &ps)
                let val: InlineExpression
                switch valRes {
                case .success(let e):
                    val = e
                case .failure(let err):
                    return .failure(err)
                }
                
                argument_names.append(id.name)
                named.append(.init(name: .init(name: id.name), value: val))
                
            } else {
                if !argument_names.isEmpty {
                    return .failure(.init(kind: .positionalArgumentFollowsNamed, start: ps.ptrOffset))
                }
                positional.append(expr)
            }
            break
        default:
            if !argument_names.isEmpty {
                return .failure(.init(kind: .positionalArgumentFollowsNamed, start: ps.ptrOffset))
            }
            positional.append(expr)
        }
        
        ps.skip_blank()
        _ = ps.take_byte_if(c: ",")
        ps.skip_blank()
    }
    
    if case .failure(let err) = ps.expect_byte(")") { return .failure(err) }
    
    return .success(CallArguments(positional: positional, named: named))
}

func get_number_literal(ps: inout ParserStream) -> Result<String, ParserError> {
    let start = ps.ptr
    _ = ps.take_byte_if(c: "-")
    
    var result = ps.skip_digits()
    if ps.take_byte_if(c: ".") {
        result = ps.skip_digits()
    }

    return result.map { _ in ps.get_slice(start: start, end: ps.ptr) }
}
