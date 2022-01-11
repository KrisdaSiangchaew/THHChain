//
//  File.swift
//  
//
//  Created by Krisda on 10/1/2565 BE.
//

@testable import App
import XCTVapor

final class BlockchainTests: XCTestCase {
    let blockchainsName = "THH Blockchain"
    let blockchainsURI = "api/blockchains"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testBlockchainsCanBeRetrievedFromAPI() throws {
        let blockchain = try Blockchain.create(name: blockchainsName, database: app.db)
        _ = try Blockchain.create(database: app.db)
        
        try app.test(.GET, blockchainsURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let users = try response.content.decode([Blockchain].self)
            
            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(users[0].name, blockchainsName)
            XCTAssertEqual(users[0].id, blockchain.id)
        })
    }
}
