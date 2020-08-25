//
//  Errors.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 22.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import FluentSyntax

public enum FluentError: Error {
    case overriding(kind: String, id: String)
    case parserError(ParserError)
    case resolverError(ResolverError)
}

extension Array: Error where Element == FluentError {}
