//
//  Types.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 22.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import FluentSyntax

public enum DisplayableNodeType: Equatable {
    case message(String)
    case term(String)
    case variable(String)
    case function(String)
    case expression
}

public struct DisplayableNode: Equatable {
    let nodeType: DisplayableNodeType
    let attribute: String?
    
    init(
        nodeType: DisplayableNodeType = .expression,
        attribute: String? = nil
    ) {
        self.nodeType = nodeType
        self.attribute = attribute
    }
    
    init(expr: Expression) {
        switch expr {
        case .inlineExpression(let inlineExpression):
            self.init(expr: inlineExpression)
        case .selectExpression:
            self.init()
        }
    }
    
    init(expr: InlineExpression) {
        switch expr {
        case .messageReference(let id, let attribute):
            self.init(nodeType: .message(id.name), attribute: attribute?.name)
        case .termReference(let id, let attribute, _):
            self.init(nodeType: .term(id.name), attribute: attribute?.name)
        case .variableReference(let id):
            self.init(nodeType: .variable(id.name), attribute: nil)
        case .functionReference(let id, _):
            self.init(nodeType: .function(id.name), attribute: nil)
        default:
            self.init()
        }
    }
    
    public func getError() -> String {
        if attribute == nil {
            switch nodeType {
            case .message:
                return "Unknown message: \(self)"
            case .term:
                return "Unknown term: \(self)"
            case .variable:
                return "Unknown variable: \(self)"
            case .function:
                return "Unknown function: \(self)"
            case .expression:
                return "Failed to resolve an expression."
            }
        } else {
            return "Unknown attribute: \(self)"
        }
    }
}

public protocol FluentType: AnyEquatable {
    func as_string() -> String
}

public protocol AnyEquatable: Any {
    func eq(_ rhs: Any) -> Bool
}
extension AnyEquatable where Self: Equatable {
    public func eq(_ rhs: Any) -> Bool {
        if let r = rhs as? Self {
            return self == r
        } else {
            return false
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: DisplayableNode) {
        switch value.nodeType {
        case .message(let id):
            appendInterpolation("\(id)")
        case .term(let id):
            appendInterpolation("-\(id)")
        case .variable(let id):
            appendInterpolation("$\(id)")
        case .function(let id):
            appendInterpolation("\(id)()")
        case .expression:
            appendInterpolation("???")
        }
        if let attribute = value.attribute {
            appendInterpolation(".\(attribute)")
        }
    }
}

public enum FluentValue: Equatable {

    case string(String)
    case number(FluentNumber)
    case custom(FluentType)
    case error(DisplayableNode)
    case none
    
    func as_string(scope: Scope) -> String {
        if let formatter = scope.bundle.formatter,
            let val = formatter(self) {
            return val
        }
        
        switch self {
        case .string(let s):
            return s
        case .number(let n):
            return "\(n)"
        case .error(let d):
            return "{\(d)}"
        case .none:
            return "???"
        case .custom(let c):
            return c.as_string()
        }
    }
    
    public static func == (lhs: FluentValue, rhs: FluentValue) -> Bool {
        switch (lhs, rhs) {
        case (.string(let l), .string(let r)):
            return l == r
        case (.number(let l), .number(let r)):
            return l == r
        case (.custom(let l), .custom(let r)):
            return l.eq(r)
        default:
            return false
        }
    }
}
