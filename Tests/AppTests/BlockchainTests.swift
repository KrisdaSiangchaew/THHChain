//
//  File.swift
//  
//
//  Created by Krisda on 10/1/2565 BE.
//

@testable import App
import XCTVapor

final class BlockchainTests: XCTestCase {
    func testBlockchainsCanBeRetrievedFromAPI() throws {
        let expectedName = "THH Blochchain"
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        
        let chain = Blockchain(name: expectedName)
        try chain.save(on: app.db).wait()
        
        let chain2 = Blockchain(name: "Kad Chain")
        try chain2.save(on: app.db).wait()
        
        try app.test(.GET, "api/blockchains", afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let users = try response.content.decode([Blockchain].self)
            
            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(users[0].name, expectedName)
            XCTAssertEqual(users[0].id, chain.id)
        })
    }
}
