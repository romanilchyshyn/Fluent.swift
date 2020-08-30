//
//  TestFixtures.swift
//  FluentBundleTests
//
//  Created by  Roman Ilchyshyn on 30.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import XCTest
import Foundation

@testable import FluentBundle

final class TestFixtures: XCTestCase {
    
    func testStart() {
        let bundle = Bundle(for: type(of: self))
        
        let defaultsURL = bundle.url(forResource: "defaults", withExtension: "json", subdirectory: "fixtures")!
        let defaults = try! Self.getDefaults(url: defaultsURL)
        
        for url in bundle.urls(forResourcesWithExtension: "json", subdirectory: "fixtures")!.sorted(by: { $0.path < $1.path }) {
            if url.pathComponents.contains("defaults.json") {
                continue
            }
                
            print("++++ \(url.path)")
            let fixture = try! Self.getFixture(url: url)
            
            Self.testFixture(fixture: fixture, defaults: defaults)
        }
    }
    
    private static func testFixture(fixture: TestFixture, defaults: TestDefaults) {
        for suite in fixture.suites {
            fatalError("Unimplemented.")
        }
    }
    
    private static func testSuite(suite: TestSuite, defaults: TestDefaults, scope: Scope) {
         
    }
    
    // MARK: - Utils
    
    private static func getDefaults(url: URL) throws -> TestDefaults {
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(TestDefaults.self, from: data)
    }
    
    private static func getFixture(url: URL) throws -> TestFixture {
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(TestFixture.self, from: data)
    }
    
}
