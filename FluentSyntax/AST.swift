//
//  AST.swift
//  Fluent-syntax
//
//  Created by  Roman Ilchyshyn on 11.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

public struct Resource: Equatable {
    public let body: [ResourceEntry]
}

public enum ResourceEntry: Equatable {
    case entry(Entry)
    case junk(String)
}

public enum Entry: Equatable {
    case message(Message)
    case term(Term)
    case comment(Comment)
}

public struct Message: Equatable {
    public let id: Identifier
    public let value: Pattern?
    public let attributes: [Attribute]
    public let comment: Comment?
    
    func updatedWithComment(_ comment: Comment) -> Self {
        .init(
            id: id,
            value: value,
            attributes: attributes,
            comment: comment
        )
    }
}

public struct Term: Equatable {
    public let id: Identifier
    public let value: Pattern
    public let attributes: [Attribute]
    public let comment: Comment?
    
    func updatedWithComment(_ comment: Comment) -> Self {
        .init(
            id: id,
            value: value,
            attributes: attributes,
            comment: comment
        )
    }
}

public struct Pattern: Equatable {
    public let elements: [PatternElement]
}

public enum PatternElement: Equatable {
    case textElement(String)
    case placeable(Expression)
}

public struct Attribute: Equatable {
    public let id: Identifier
    public let value: Pattern
}

public struct Identifier: Equatable {
    public let name: String
}

public struct Variant: Equatable {
    public let key: VariantKey
    public let value: Pattern
    public let `default`: Bool
}

public enum VariantKey: Equatable {
    case identifier(name: String)
    case numberLiteral(value: String)
}

public enum Comment: Equatable {
    case comment(content: [String])
    case groupComment(content: [String])
    case resourceComment(content: [String])
}

public indirect enum InlineExpression: Equatable {
    case stringLiteral(value: String)
    case numberLiteral(value: String)
    case functionReference(id: Identifier, arguments: CallArguments?)
    case messageReference(id: Identifier, attribute: Identifier?)
    case termReference(id: Identifier, attribute: Identifier?, arguments: CallArguments?)
    case variableReference(id: Identifier)
    case placeable(expression: Expression)
}

public struct CallArguments: Equatable {
    public let positional: [InlineExpression]
    public let named: [NamedArgument]
}

public struct NamedArgument: Equatable {
    public let name: Identifier
    public let value: InlineExpression
}

public enum Expression: Equatable {
    case inlineExpression(InlineExpression)
    case selectExpression(selector: InlineExpression, variants: [Variant])
}
