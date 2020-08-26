//
//  FluentBundle.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 22.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import FluentSyntax

public struct FluentMessage: Equatable {
    public let value: Pattern?
    public let attributes: [String: Pattern]
}

public typealias FluentArgs = [String: FluentValue]

public final class FluentBundleBase<M> {
    public let locales: [Locale]
    public private(set) var resources: [FluentResource]
    public private(set) var entries: [String: Entry]
    public let intls: M? // FIXME: Remove optional
    public var useIsolating: Bool
    public var transform: ((String) -> String)?
    public var formatter: ((FluentValue) -> String?)?
    
    public init(locales: [Locale]) {
        self.locales = locales
        self.resources = []
        self.entries = [:]
        self.intls = nil // FIXME: Shoul be something like: `M(locales[0])`
        self.useIsolating = true
    }
    
    public func addResource(_ resource: FluentResource) -> Result<Void, [FluentError]> {
        var errors: [FluentError] = []
        
        let resourcePosition = resources.count
        
        for (entryPosition, resourceEntry) in resource.ast.body.enumerated() {
            let id: String
            let entry: Entry
            let kind: String
            
            switch resourceEntry {
            case .entry(.message(let m)):
                id = m.id.name
                entry = .message(resourcePosition, entryPosition)
                kind = "message"
            case .entry(.term(let t)):
                id = t.id.name
                entry = .term(resourcePosition, entryPosition)
                kind = "term"
            default:
                continue
            }
            
            if entries[id] == nil {
               entries[id] = entry
            } else {
                errors.append(.overriding(kind: kind, id: id))
            }
        }
        
        resources.append(resource)
        
        if errors.isEmpty {
            return .success(())
        } else {
            return .failure(errors)
        }
    }
    
    public func addResourceOverriding(_ resource: FluentResource) {
        let resourcePosition = resources.count
        
        for (entryPosition, resourceEntry) in resource.ast.body.enumerated() {
            let id: String
            let entry: Entry
            
            switch resourceEntry {
            case .entry(.message(let m)):
                id = m.id.name
                entry = .message(resourcePosition, entryPosition)
            case .entry(.term(let t)):
                id = t.id.name
                entry = .term(resourcePosition, entryPosition)
            default:
                continue
            }
            
            entries[id] = entry
        }
        
        resources.append(resource)
    }
    
    public func hasMessage(id: String) -> Bool {
        getEntryMessage(id: id) != nil
    }
    
    public func getMessage(id: String) -> FluentMessage? {
        guard let message = getEntryMessage(id: id) else { return nil }
        
        let value = message.value
        let attributes: [String: Pattern] = message.attributes.reduce(into: [:]) { (r, a) in
            r[a.id.name] = a.value
        }
        
        return FluentMessage(value: value, attributes: attributes)
    }
    
    public func formatPattern(pattern: Pattern, args: FluentArgs?) -> (result: String, errors: [FluentError]) {
        let scope = Scope(bundle: self, args: args)
        let result = pattern.resolve(scope: scope).as_string(scope: scope)
        return (result, scope.errors.map { .resolverError($0) })
    }
    
    public func addFunction(id: String, function: @escaping FluentFunction) -> Result<Void, FluentError> {
        if entries[id] == nil {
            entries[id] = .function(function)
            return .success(())
        } else {
            return .failure(.overriding(kind: "function", id: id))
        }
    }
    
}

extension FluentBundleBase: GetEntry {
    public func getEntryMessage(id: String) -> Message? {
        guard let  entry = entries[id] else { return nil }
        switch entry {
        case .message(let pos0, let pos1):
            let res = resources[pos0]
            if case .entry(.message(let msg)) = res.ast.body[pos1] {
                return msg
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    public func getEntryTerm(id: String) -> Term? {
        guard let  entry = entries[id] else { return nil }
        switch entry {
        case .term(let pos0, let pos1):
            let res = resources[pos0]
            if case .entry(.term(let term)) = res.ast.body[pos1] {
                return term
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    public func getEntryFunction(id: String) -> FluentFunction? {
        guard let  entry = entries[id] else { return nil }
        switch entry {
        case .function(let function):
            return function
        default:
            return nil
        }
    }
}
