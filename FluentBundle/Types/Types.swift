//
//  Types.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 22.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

public enum FluentValue: Equatable {
    case String(String)
    case Number // (FluentNumber)
    case Custom // (FluentType)
    case Error  // (DisplayableNode)
    case None
}
