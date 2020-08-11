//
//  UnicodeTests.swift
//  Fluent-syntaxTests
//
//  Created by  Roman Ilchyshyn on 11.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import XCTest
import Fluent_syntax

class UnicodeTests: XCTestCase {

    func test_unescapeUnicode() {
        XCTAssertEqual(unescapeUnicode(""), "")
        XCTAssertEqual(unescapeUnicode("foo"), "foo")
        XCTAssertEqual(unescapeUnicode("foo \\\\"), "foo \\")
        XCTAssertEqual(unescapeUnicode("foo \\\""), "foo \"")
        XCTAssertEqual(unescapeUnicode("foo \\\\ faa"), "foo \\ faa")
        XCTAssertEqual(
            unescapeUnicode("foo \\\\ faa \\\\ fii"),
            "foo \\ faa \\ fii"
        )
        XCTAssertEqual(
            unescapeUnicode("foo \\\\\\\" faa \\\"\\\\ fii"),
            "foo \\\" faa \"\\ fii"
        )
        XCTAssertEqual(unescapeUnicode("\\u0041\\u004F"), "AO")
        XCTAssertEqual(unescapeUnicode("\\uA"), "�")
        XCTAssertEqual(unescapeUnicode("\\uA0Pl"), "�")
        XCTAssertEqual(unescapeUnicode("\\d Foo"), "� Foo")
    }

}
