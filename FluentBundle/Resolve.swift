//
//  Resolve.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 24.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import FluentSyntax

let maxPlaceables = 100

public enum ResolverError {
    case Reference(String)
    case MissingDefault
    case Cyclic
    case TooManyPlaceables
}

public final class Scope<M> {
    public let bundle: FluentBundleBase<M>
    /// The current arguments passed by the developer.
    public let args: FluentArgs?
    /// Local args
    fileprivate var localArgs: FluentArgs?
    /// The running count of resolved placeables. Used to detect the Billion
    /// Laughs and Quadratic Blowup attacks.
    fileprivate var placeables: Int
    /// Tracks hashes to prevent infinite recursion.
    private var travelled: [Pattern]
    /// Track errors accumulated during resolving.
    public var errors: [ResolverError]
    /// Makes the resolver bail.
    public fileprivate(set) var dirty: Bool
    
    public init(bundle: FluentBundleBase<M>, args: FluentArgs?) {
        self.bundle = bundle
        self.args = args
        self.localArgs = nil
        self.placeables = 0
        self.travelled = []
        self.errors = []
        self.dirty = false
    }
    
    public func maybe_track(pattern: Pattern, placeable: Expression) -> FluentValue {
        if travelled.isEmpty {
            travelled.append(pattern)
        }
        let result = placeable.resolve(scope: self)
        if self.dirty {
            return .error(.init(expr: placeable))
        }
        return result
    }
    
    public func track(pattern: Pattern, entry: DisplayableNode) -> FluentValue {
        if travelled.contains(pattern) {
            errors.append(.Cyclic)
            return .error(entry)
        } else {
            travelled.append(pattern)
            let result = pattern.resolve(scope: self)
            travelled.removeLast()
            return result
        }
    }
}

public protocol ResolveValue {
    func resolve<M>(scope: Scope<M>) -> FluentValue
}

func generate_ref_error<M>(scope: Scope<M>, node: DisplayableNode) -> FluentValue {
    scope.errors.append(.Reference(node.getError()))
    return .error(node)
}

extension Pattern: ResolveValue {
    public func resolve<M>(scope: Scope<M>) -> FluentValue {
        if scope.dirty {
            return .none
        }
        
        if elements.count == 1 {
            switch elements[0] {
            case .textElement(let s):
                return scope.bundle.transform
                    .map { t in .string(t(s)) }
                    ?? .string(s)
            case .placeable(let p):
                return scope.maybe_track(pattern: self, placeable: p)
            }
        }
        
        var string = ""
        for elem in elements {
            if scope.dirty {
                return .none
            }
            
            switch elem {
            case .textElement(let s):
                let stringPart = scope.bundle.transform.map { t in t(s) } ?? s
                string.append(stringPart)
            
            case .placeable(let p):
                scope.placeables += 1
                if scope.placeables > maxPlaceables {
                    scope.dirty = true
                    scope.errors.append(.TooManyPlaceables)
                    return .none
                }
                
                let needsIsolationPlaceble: Bool
                switch p {
                case .inlineExpression(.messageReference),
                    .inlineExpression(.termReference),
                    .inlineExpression(.stringLiteral):
                    needsIsolationPlaceble = false
                default:
                    needsIsolationPlaceble = true
                }
                
                let needs_isolation = scope.bundle.useIsolating && needsIsolationPlaceble
                if needs_isolation {
                    string.append("\u{2068}")
                }
                
                let result = scope.maybe_track(pattern: self, placeable: p)
                string.append(result.as_string())
                
                if needs_isolation {
                    string.append("\u{2069}")
                }
            }
        }
        
        return .string(string)
    }
}

extension Expression: ResolveValue {
    public func resolve<M>(scope: Scope<M>) -> FluentValue {
        switch self {
        case .inlineExpression(let expression):
            return expression.resolve(scope: scope)
        case .selectExpression(let selector, let variants):
            let selector = selector.resolve(scope: scope)
            switch selector {
                
            case .string,
                 .number:
                for variant in variants {
                    let key: FluentValue
                    switch variant.key {
                    case .identifier(let name):
                        key = .string(name)
                    case .numberLiteral(let value):
                        key = FluentValue(tryNumber: value)
                    }
                    if key == selector { // FIXME: matches
                        return variant.value.resolve(scope: scope)
                    }
                }
            default:
                break
            }
            
            for variant in variants {
                if variant.default {
                    return variant.value.resolve(scope: scope)
                }
            }
            
            scope.errors.append(.MissingDefault)
            
            return .none
        }
    }
}

extension InlineExpression: ResolveValue {
    public func resolve<M>(scope: Scope<M>) -> FluentValue {
        switch self {
        case .stringLiteral(let value):
            return .string(unescapeUnicode(value))
        
        case .numberLiteral(let value):
            return FluentValue(tryNumber: value)
        
        case .functionReference(let id, let arguments):
            let (resolved_positional_args, resolved_named_args) = get_arguments(scope: scope, arguments: arguments)
            let fn = scope.bundle.getEntryFunction(id: id.name)
            if let fn = fn {
                return fn(resolved_positional_args, resolved_named_args)
            } else {
                return generate_ref_error(scope: scope, node: .init(expr: self))
            }
        
        case .messageReference(let id, let attribute):
            return scope
                .bundle.getEntryMessage(id: id.name).flatMap { msg in
                    if let attribute = attribute {
                        return msg
                            .attributes
                            .first(where: { a in a.id.name == attribute.name  })
                            .map { a in scope.track(pattern: a.value, entry: .init(expr: self))  }
                    } else {
                        return msg
                            .value
                            .map { value in scope.track(pattern: value, entry: .init(expr: self)) }
                    }
                }
                ?? generate_ref_error(scope: scope, node: .init(expr: self))
            
        case .termReference(let id, let attribute, let arguments):
            let (_, resolved_named_args) = get_arguments(scope: scope, arguments: arguments)
            scope.localArgs = resolved_named_args
            
            let value: FluentValue = scope
                .bundle
                .getEntryTerm(id: id.name)
                .flatMap { term in
                    if let attr = attribute {
                        return term
                            .attributes
                            .first(where: { a in a.id.name == attr.name  })
                            .map { a in scope.track(pattern: a.value, entry: .init(expr: self)) }
                    } else {
                        return scope.track(pattern: term.value, entry: .init(expr: self))
                    }
                }
            ?? generate_ref_error(scope: scope, node: .init(expr: self))
            
            scope.localArgs = nil
            
            return value
        
        case .variableReference(let id):
            let args = scope.localArgs ?? scope.args
            if let arg = args?[id.name] {
                return arg
            } else {
                let entry: DisplayableNode = .init(expr: self)
                if scope.localArgs == nil {
                    scope
                        .errors
                        .append(.Reference(entry.getError()))
                }
                return .error(entry)
            }
        
        case .placeable(let expression):
            return expression.resolve(scope: scope)
        }
    }
}

func get_arguments<M>(scope: Scope<M>, arguments: CallArguments?) -> ([FluentValue], FluentArgs) {
    var resolved_positional_args: [FluentValue] = []
    var resolved_named_args = FluentArgs()

    if let arguments = arguments {
        for expression in arguments.positional {
            resolved_positional_args.append(expression.resolve(scope: scope))
        }
        for arg in arguments.named {
            resolved_named_args[arg.name.name] = arg.value.resolve(scope: scope)
        }
    }

    return (resolved_positional_args, resolved_named_args)
}
