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
    
    init(source: String) throws {
        let r = parse(source: source)
        switch r {
        case .success(let resource):
            string = source
            ast = resource
        case .failure(let err):
            throw err
        }
    }
    
}
