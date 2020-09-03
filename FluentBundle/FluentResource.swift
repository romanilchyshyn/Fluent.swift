//
//  FluentResource.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 22.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import FluentSyntax

public final class FluentResource {
    
    public let string: String
    public let ast: Resource
    
    public init(string: String, ast: Resource) {
        self.string = string
        self.ast = ast
    }
    
    static func create(source: String) -> Result<FluentResource, FluentResourceCreateError> {
        let result: Result<FluentResource, FluentResourceCreateError>
        
        let parseResult = parse(source: source)
        switch parseResult {
        case .success(let resource):
            result = .success(.init(string: source, ast: resource))
        case .failure(let err):
            result = .failure(
                .init(resource: .init(string: source, ast: err.resource),
                errors: err.errors
                )
            )
        }
        
        return result
    }
    
}

public struct FluentResourceCreateError: Error {
    let resource: FluentResource
    let errors: [ParserError]
}
