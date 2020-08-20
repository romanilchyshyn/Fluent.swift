//
//  ParserFixtures.swift
//  FluentSyntaxTests
//
//  Created by  Roman Ilchyshyn on 18.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import XCTest
import FluentSyntax

final class ParserFixturesTests: XCTestCase {

    func test_ParseFixtures() {
        let bundle = Bundle(for: type(of: self))
        let urls = bundle.urls(forResourcesWithExtension: "ftl", subdirectory: "fixtures")!

        for url in urls.sorted(by: { $0.path < $1.path }) {
            Self.testFixture(ftlUrl: url)
        }
    }
    
    func test_ParseBenchFixtures() {
        let bundle = Bundle(for: type(of: self))
        let urls =
            bundle.urls(forResourcesWithExtension: "ftl", subdirectory: "fixtures/benches")! +
            bundle.urls(forResourcesWithExtension: "ftl", subdirectory: "fixtures/benches/contexts/browser")! +
            bundle.urls(forResourcesWithExtension: "ftl", subdirectory: "fixtures/benches/contexts/preferences")!

        for url in urls.sorted(by: { $0.path < $1.path }) {
            Self.testFixture(ftlUrl: url)
        }
    }
    
    private static func testFixture(ftlUrl: URL) {
        // Parse
        
        let ftlContent = try! String(contentsOf: ftlUrl, encoding: .utf8)
        let parseResult = parse(source: ftlContent)
        let ast: Resource
        switch parseResult {
        case .success(let resource):
            ast = resource
        case .failure(let err):
            ast = err.resource
        }

        // Encode
        
        let ftlEncodedData = try! JSONEncoder().encode(ast)
        let jsonEncodedData = try! Data(contentsOf: ftlUrl.deletingPathExtension().appendingPathExtension("json"))
        
        // Assert
        
        let actual = try! createJsonString(data: ftlEncodedData)
        let expected = try! createJsonString(data: jsonEncodedData)
        
        XCTAssertEqual(actual, expected)
    }
    
    private static func createJsonString(data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data, options: .init())
        let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        return String(data: data, encoding: .utf8)!
    }

}
