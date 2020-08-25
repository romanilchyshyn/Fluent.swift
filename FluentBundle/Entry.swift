//
//  Entry.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 23.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import FluentSyntax

public typealias FluentFunction = ([FluentValue], FluentArgs) -> FluentValue

public enum Entry {
    case message(Int, Int)
    case term(Int, Int)
    case function(FluentFunction)
}

public protocol GetEntry {
    func getEntryMessage(id: String) -> Message?
    func getEntryTerm(id: String) -> Term?
    func getEntryFunction(id: String) -> FluentFunction?
}
