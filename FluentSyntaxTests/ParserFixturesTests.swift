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
        let ftlUrls = bundle.urls(forResourcesWithExtension: "ftl", subdirectory: "fixtures")!
        
        for url in ftlUrls {
            print("START: \(url.lastPathComponent)")
            
            let s = try! String(contentsOf: url, encoding: .utf8)
            
            let r = parse(source: s)
        
            if case .success = r {
                print("   OK: \(url.lastPathComponent)")
            } else {
                print(" FAIL: \(url.lastPathComponent)")
            }
            
        }
        
    }
    
    func test_ParseFixture() {
        let fixture = "tab"
        
        print("START: \(fixture)")
        
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: fixture, withExtension: "ftl", subdirectory: "fixtures")!
        let s = try! String(contentsOf: url, encoding: .utf8)
        
        let r = parse(source: s)
        
        if case .success = r {
            print("OK: \(fixture)")
        } else {
            print("FAIL: \(fixture)")
        }
    }
    
    func test_ParseFixturesCompare() {
        
    }
    
    func test_ParseBenchFixtures() {
        // TODO: Need to implement
    }

}
