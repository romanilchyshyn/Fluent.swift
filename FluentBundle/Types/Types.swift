//
//  Types.swift
//  FluentBundle
//
//  Created by  Roman Ilchyshyn on 22.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

public enum FluentValue: Equatable {
    case string(String)
    case number(FluentNumber)
    case custom // (FluentType)
    case error  // (DisplayableNode)
    case none
}
