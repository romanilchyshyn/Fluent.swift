//
//  FixturesInfrastructure.swift
//  FluentBundleTests
//
//  Created by  Roman Ilchyshyn on 30.08.2020.
//  Copyright © 2020  Roman Ilchyshyn. All rights reserved.
//

import Foundation

struct TestBundle: Decodable {
    let name: String?
    let locales: [String]?
    let resources: [String]?
    let useIsolating: Bool?
    let functions: [String]?
    let transform: String?
    let errors: [TestError]?
}

struct TestResource: Decodable {
    let name: String?
    let errors: [TestError]?
    let source: String
}

struct TestSetup: Decodable {
    let bundles: [TestBundle]?
    let resources: [TestResource]?
}

struct TestError: Decodable {
    let type: String
    let desc: String?
}

enum TestArgumentValue: Decodable {
    case string(String)
    case number(Double)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else {
            let string = try container.decode(String.self)
            self = .string(string)
        }
    }

}

struct TestAssert: Decodable {
    let bundle: String?
    let id: String
    let attribute: String?
    let value: String?
    let args: [String: TestArgumentValue]?
    let errors: [TestError]?
    let missing: Bool?
}

struct Test: Decodable {
    let name: String
    let skip: Bool?
    let bundles: [TestBundle]?
    let resources: [TestResource]?
    let asserts: [TestAssert]
}

struct TestSuite: Decodable {
    let name: String
    let skip: Bool?
    
    let bundles: [TestBundle]?
    let resources: [TestResource]?
    
    let tests: [Test]?
    let suites: [TestSuite]?
}

struct TestFixture: Decodable {
    let suites: [TestSuite]
}

struct BundleDefaults: Decodable {
    let useIsolating: Bool?
    let transform: String?
    let locales: [String]?
}

struct TestDefaults: Decodable {
    let bundle: BundleDefaults
}
