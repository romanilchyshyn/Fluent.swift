//
//  TestFixtures.swift
//  FluentBundleTests
//
//  Created by  Roman Ilchyshyn on 30.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import XCTest
import Foundation

import FluentSyntax
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
            testSuite(suite: suite, defaults: defaults, scope: .init(levels: []))
        }
    }
    
    private static func testSuite(suite: TestSuite, defaults: TestDefaults, scope: Scope) {
        if suite.skip == true {
            return
        }

        scope.levels.append(.init(name: suite.name, resources: suite.resources ?? [], bundles: suite.bundles ?? []))

        for test in suite.tests ?? [] {
            testTest(test: test, defaults: defaults, scope: scope)
        }

        for sub_suite in suite.suites ?? [] {
            testSuite(suite: sub_suite, defaults: defaults, scope: scope)
        }
    }
    
    private static func testTest(test: Test, defaults: TestDefaults, scope: Scope) {
        if test.skip == true {
            return
        }

        scope.levels.append(.init(name: test.name, resources: test.resources ?? [], bundles: test.bundles ?? []))
        
        for assert in test.asserts {
            let bundles = scope.getBundles(defaults: defaults)
            
            let bundle: FluentBundle
            if let bundle_name = assert.bundle {
                bundle = bundles[bundle_name]!
            } else if bundles.count == 1 {
                let name = Array(bundles.keys).last!
                bundle = bundles[name]!
            } else {
                fatalError()
            }
            
            if let expected_missing = assert.missing {
                let missing: Bool
                if let attr = assert.attribute {
                    if let msg = bundle.getMessage(id: assert.id) {
                        missing = msg.attributes[attr] != nil
                    } else {
                        missing = false
                    }
                } else {
                    missing = !bundle.hasMessage(id: assert.id)
                }
                
                XCTAssertEqual(missing, expected_missing, "Expected pattern to be `missing: \(expected_missing)` for \(assert.id) in \(scope.getPath())")
            
            } else {
                if let expected_value = assert.value {
                    guard let msg = bundle.getMessage(id: assert.id) else {
                        fatalError("Failed to retrieve message `\(assert.id)` in \(scope.getPath()).")
                    }
                    
                    let val: FluentSyntax.Pattern
                    if let attr = assert.attribute {
                        guard let v = msg.attributes[attr] else {
                            fatalError("Failed to retrieve an attribute of a message \(assert.id).\(attr).")
                        }
                        val = v
                    } else {
                        guard let v = msg.value else {
                            fatalError("Failed to retrieve a value of a message \(assert.id).")
                        }
                        val = v
                    }
                    
                    let args: FluentArgs? = assert.args?.mapValues {
                        switch $0 {
                        case .number(let n): return .number(.init(value: n, options: .init()))
                        case .string(let s): return .string(s)
                        }
                    }
                    
                    let (value, errors) = bundle.formatPattern(pattern: val, args: args)
                    
                     XCTAssertEqual(value, expected_value, "Values don't match in \(scope.getPath())")
                    
                    testErrors(errors: errors, reference: assert.errors)
                    
                } else {
                    fatalError("Value field expected.")
                }
            }
            
        }
    }
    
    private static func testErrors(errors: [FluentError], reference: [TestError]?) {
        guard let reference = reference else { return }
        XCTAssertEqual(errors.count, reference.count)
        
        for (error, reference) in zip(errors, reference) {
            switch error {
            case .overriding:
                XCTAssertEqual(reference.type, "Overriding")
            case .parserError:
                XCTAssertEqual(reference.type, "Parser")
            case .resolverError(let err):
                switch err {
                case .reference(let desc):
                    XCTAssertEqual(reference.desc, desc)
                    XCTAssertEqual(reference.type, "Reference")
                case .cyclic:
                    XCTAssertEqual(reference.type, "Cyclic")
                case .tooManyPlaceables:
                    XCTAssertEqual(reference.type, "TooManyPlaceables")
                default:
                    fatalError("Unimplemented")
                }
            }
        }
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

private final class ScopeLevel {
    let name: String
    let resources: [TestResource]
    let bundles: [TestBundle]
    
    init(name: String, resources: [TestResource], bundles: [TestBundle]) {
        self.name = name
        self.resources = resources
        self.bundles = bundles
    }
}

private final class Scope {
    var levels: [ScopeLevel]
    
    init(levels: [ScopeLevel]) {
        self.levels = levels
    }
    
    func getPath() -> String {
        levels.map(\.name).joined(separator: " > ")
    }
    
    func getBundles(defaults: TestDefaults?) -> [String: FluentBundle] {
        var bundles = [String: FluentBundle]()
        
        var available_resources = [TestResource]()
        
        for lvl in levels {
            for r in lvl.resources {
                available_resources.append(r)
            }

            for b in lvl.bundles {
                let name = b
                    .name ?? generateRandomHash()
                
                let bundle = createBundle(b: b, defaults: defaults, resources: available_resources)
                bundles[name] = bundle
            }
        }
        
        if bundles.isEmpty {
            let bundle = createBundle(b: nil, defaults: defaults, resources: available_resources)
            let name = generateRandomHash()
            bundles[name] = bundle
        }
        
        return bundles
    }
}

private func generateRandomHash() -> String {
    fatalError()
}

func createBundle(b: TestBundle?, defaults: TestDefaults?, resources: [TestResource]) -> FluentBundle {
    fatalError()
}
