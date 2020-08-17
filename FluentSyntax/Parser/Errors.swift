//
//  Errors.swift
//  FluentSyntax
//
//  Created by  Roman Ilchyshyn on 11.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

public struct ParserError: Equatable, Error {
    public struct Position: Equatable {
        public let start: UInt
        public let end: UInt
    }
    
    public let pos: Position
    public let slice: Position?
    public let kind: ErrorKind
    
    init(kind: ErrorKind, start: UInt, end: UInt? = nil) {
        self.kind = kind
        self.pos = Position(start: start, end: end ?? start + 1)
        self.slice = nil
    }
    
    init(pos: Position, slice: Position?, kind: ErrorKind) {
        self.pos = pos
        self.slice = slice
        self.kind = kind
    }
    
    func updatedWithSlice(_ position: Position) -> Self {
        .init(pos: pos, slice: position, kind: kind)
    }
}

extension ParserError: CustomStringConvertible {
    public var description: String {
        String(describing: kind)
    }
}

public enum ErrorKind: Equatable {
    case generic
    case expectedEntry
    case expectedToken(Character)
    case expectedCharRange(range: String)
    case expectedMessageField(entryId: String)
    case expectedTermField(entryId: String)
    case forbiddenWhitespace
    case forbiddenCallee
    case forbiddenKey
    case missingDefaultVariant
    case missingVariants
    case missingValue
    case missingVariantKey
    case missingLiteral
    case multipleDefaultVariants
    case messageReferenceAsSelector
    case termReferenceAsSelector
    case messageAttributeAsSelector
    case termAttributeAsPlaceable
    case unterminatedStringExpression
    case positionalArgumentFollowsNamed
    case duplicatedNamedArgument(String)
    case forbiddenVariantAccessor
    case unknownEscapeSequence(String)
    case invalidUnicodeEscapeSequence(String)
    case unbalancedClosingBrace
    case expectedInlineExpression
    case expectedSimpleExpressionAsSelector
}

extension ErrorKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .generic:
            return "An error occurred"
        case .expectedEntry:
            return "Expected an entry"
        case .expectedToken(let letter):
            return #"Expected a token starting with "\#(letter)""#
        case .expectedCharRange(let range):
            return #"Expected one of "\#(range)\"#
        case .expectedMessageField(let entryId):
            return #"Expected a message field for "\#(entryId)""#
        case .expectedTermField(let entryId):
            return #"Expected a term field for "\#(entryId)""#
        case .forbiddenWhitespace:
            return "Whitespace is not allowed here"
        case .forbiddenCallee:
            return "Callee is not allowed here"
        case .forbiddenKey:
            return "Key is not allowed here"
        case .missingDefaultVariant:
            return "The select expression must have a default variant"
        case .missingVariants:
            return "The select expression must have one or more variants"
        case .missingValue:
            return "Expected a value"
        case .missingVariantKey:
            return "Expected a variant key"
        case .missingLiteral:
            return "Expected a literal"
        case .multipleDefaultVariants:
            return "A select expression can only have one default variant"
        case .messageReferenceAsSelector:
            return "Message references can't be used as a selector"
        case .termReferenceAsSelector:
            return "Term references can't be used as a selector"
        case .messageAttributeAsSelector:
            return "Message attributes can't be used as a selector"
        case .termAttributeAsPlaceable:
            return "Term attributes can't be used as a placeable"
        case .unterminatedStringExpression:
            return "Unterminated string expression"
        case .positionalArgumentFollowsNamed:
            return "Positional arguments must come before named arguments"
        case .duplicatedNamedArgument(let name):
            return #"The "\#(name)" argument appears twice"#
        case .forbiddenVariantAccessor:
            return "Forbidden variant accessor"
        case .unknownEscapeSequence(let seq):
            return #"Unknown escape sequence, "\#(seq)""#
        case .invalidUnicodeEscapeSequence(let seq):
            return #"Invalid unicode escape sequence, "\#(seq)""#
        case .unbalancedClosingBrace:
            return "Unbalanced closing brace"
        case .expectedInlineExpression:
            return "Expected an inline expression"
        case .expectedSimpleExpressionAsSelector:
            return "Expected a simple expression as selector"
        }
    }
    
}
