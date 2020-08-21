//
//  AST+Encodable.swift
//  FluentSyntax
//
//  Created by  Roman Ilchyshyn on 19.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

public func serialize(resourse: Resource) throws -> Data {
    return try JSONEncoder().encode(resourse)
}

extension Resource: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case body
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Resource", forKey: .type)
        try container.encode(body, forKey: .body)
    }
}

extension ResourceEntry: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case content
        case annotations
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .entry(let entry):
            try entry.encode(to: encoder)
        case .junk(let junk):
            try container.encode("Junk", forKey: .type)
            try container.encode(junk, forKey: .content)
            try container.encode([String](), forKey: .annotations)
        }
    }
}

extension Entry: Encodable {

    enum CodingKeys: String, CodingKey {
        case type
        case content
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .message(let message):
            try message.encode(to: encoder)
        case .term(let term):
            try term.encode(to: encoder)
        case .comment(.comment(let content)):
            try container.encode("Comment", forKey: .type)
            try container.encode(content.joined(separator: "\n"), forKey: .content)
        case .comment(.groupComment(let content)):
            try container.encode("GroupComment", forKey: .type)
            try container.encode(content.joined(separator: "\n"), forKey: .content)
        case .comment(.resourceComment(let content)):
            try container.encode("ResourceComment", forKey: .type)
            try container.encode(content.joined(separator: "\n"), forKey: .content)
        }
    }
}

extension Message: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case value
        case attributes
        case comment
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Message", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(comment, forKey: .comment)
    }
}

extension Term: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case value
        case attributes
        case comment
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Term", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(comment, forKey: .comment)
    }
}

extension Pattern: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case elements
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Pattern", forKey: .type)
        
        var elements: [PatternElement] = []
        
        var buffer = ""
        for element in self.elements {
            switch element {
                
            case .textElement(let text):
                buffer.append(text)
            case .placeable:
                if !buffer.isEmpty {
                    elements.append(.textElement(buffer))
                    buffer = ""
                }
                
                elements.append(element)
            }
        }
        
        if !buffer.isEmpty {
            elements.append(.textElement(buffer))
        }
        
        try container.encode(elements, forKey: .elements)
    }
}

extension PatternElement: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case expression
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .textElement(let s):
            try container.encode("TextElement", forKey: .type)
            try container.encode(s, forKey: .value)
        case .placeable(let placeble):
            try container.encode("Placeable", forKey: .type)
            try container.encode(placeble, forKey: .expression)
        }
    }
}

extension Attribute: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Attribute", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
    }
}

extension Identifier: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Identifier", forKey: .type)
        try container.encode(name, forKey: .name)
    }
}

extension Variant: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case key
        case value
        case `default`
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Variant", forKey: .type)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encode(`default`, forKey: .default)
    }
}

extension VariantKey: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case name
        case value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .identifier(name: let name):
            try container.encode("Identifier", forKey: .type)
            try container.encode(name, forKey: .name)
        case .numberLiteral(value: let value):
            try container.encode("NumberLiteral", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

extension Comment: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case content
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .comment(content: let content):
            try container.encode("Comment", forKey: .type)
            try container.encode(content.joined(separator: "\n"), forKey: .content)
        case .groupComment(content: let content):
            try container.encode("GroupComment", forKey: .type)
            try container.encode(content.joined(separator: "\n"), forKey: .content)
        case .resourceComment(content: let content):
            try container.encode("ResourceComment", forKey: .type)
            try container.encode(content.joined(separator: "\n"), forKey: .content)
        }
    }
}

extension InlineExpression: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case id
        case arguments
        case attribute
        case expression
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .stringLiteral(value: let value):
            try container.encode("StringLiteral", forKey: .type)
            try container.encode(value, forKey: .value)
        case .numberLiteral(value: let value):
            try container.encode("NumberLiteral", forKey: .type)
            try container.encode(value, forKey: .value)
        case .functionReference(id: let id, arguments: let arguments):
            try container.encode("FunctionReference", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(arguments, forKey: .arguments)
        case .messageReference(id: let id, attribute: let attribute):
            try container.encode("MessageReference", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(attribute, forKey: .attribute)
        case .termReference(id: let id, attribute: let attribute, arguments: let arguments):
            try container.encode("TermReference", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(attribute, forKey: .attribute)
            try container.encode(arguments, forKey: .arguments)
        case .variableReference(id: let id):
            try container.encode("VariableReference", forKey: .type)
            try container.encode(id, forKey: .id)
        case .placeable(expression: let expression):
            try container.encode("Placeable", forKey: .type)
            try container.encode(expression, forKey: .expression)
        }
    }
}

extension CallArguments: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case positional
        case named
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("CallArguments", forKey: .type)
        try container.encode(positional, forKey: .positional)
        try container.encode(named, forKey: .named)
    }
}

extension NamedArgument: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case name
        case value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("NamedArgument", forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }
}

extension Expression: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case selector
        case variants
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .inlineExpression(let expression):
            try expression.encode(to: encoder)
        case .selectExpression(let selector, let variants):
            try container.encode("SelectExpression", forKey: .type)
            try container.encode(selector, forKey: .selector)
            try container.encode(variants, forKey: .variants)
        }
    }
    
}
