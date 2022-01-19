//
//  File.swift
//  
//
//  Created by Krisda on 10/1/2565 BE.
//

@testable import App
import XCTVapor
import Foundation
import XCTest

final class BlockchainTests: XCTestCase {
    let blockchainsName = "THH Blockchain"
    let genesisBlockData = "Genesis Block"
    let genesisBlockHash = "T3nGH3NgH3ng"
    let blockchainsURI = "api/blockchains/"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testCreateNewBlockchainAlsoCreatesGenesisBlock() async throws {
        _ = try await Blockchain.create(name: blockchainsName, database: app.db)
        
        let foundBlockchains = try await Blockchain.query(on: app.db).all()
        let foundBlocks = try await Block.query(on: app.db).all()
        
        XCTAssertNotNil(foundBlockchains)
        XCTAssertEqual(foundBlockchains.count, 1)
        XCTAssertNotNil(foundBlockchains[0].id)
        XCTAssertEqual(foundBlockchains[0].name, blockchainsName)
        
        XCTAssertNotNil(foundBlocks)
        XCTAssertEqual(foundBlocks.count, 1)
        XCTAssertNotNil(foundBlocks[0].id)
        XCTAssertEqual(foundBlocks[0].data, genesisBlockData)
        
        XCTAssertEqual(foundBlocks[0].$blockchain.id, foundBlockchains[0].id!)
    }
    
    func testBlockchainsCanBeRetrievedFromAPI() async throws {
        let blockchain = try await Blockchain.create(name: blockchainsName, database: app.db)
        _ = try await Blockchain.create(name: "test", database: app.db)
        
        try app.test(.GET, blockchainsURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let blockchains = try response.content.decode([Blockchain].self)
            
            XCTAssertEqual(blockchains.count, 2)
            XCTAssertEqual(blockchains[0].name, blockchainsName)
            XCTAssertEqual(blockchains[0].id, blockchain.id)
        })
    }
    
    func testBlockchainAddBlockFunctionToAddMultipleBlocks() async throws {
        let blockchain = try await Blockchain.create(name: "One", database: app.db)
        
        let lastBlock = try await blockchain.lastBlock(in: app.db)
        
        async let block1Task = Block.addBlock(data: "block1", lastBlock: lastBlock, in: app.db)
        let block1 = try await block1Task
        
        async let block2Task = Block.addBlock(data: "block2", lastBlock: block1, in: app.db)
        let block2 = try await block2Task
        
        async let block3Task = Block.addBlock(data: "block3", lastBlock: block2, in: app.db)
        let block3 = try await block3Task
        
        XCTAssertEqual(block1.lastHash, genesisBlockHash)
        XCTAssertEqual(block2.lastHash, block1.hash)
        XCTAssertEqual(block3.lastHash, block2.hash)
                                                   

//        let blocksCount = try await blockchain.$blocks.query(on: app.db).all().count
//
//        XCTAssertEqual(blocksCount + 1, totalBlocks)
    }
    
    func testBlockchainCanBeSavedWithAPI() throws {
        let newChain = Blockchain(name: blockchainsName)
        
        try app.test(.POST, blockchainsURI, beforeRequest: { req in
            try req.content.encode(newChain)
        }, afterResponse: { response in
            let content = try response.content.decode(Blockchain.self)
            XCTAssertEqual(content.name, blockchainsName)
            XCTAssertNotNil(content.id)
            
            try app.test(.GET, blockchainsURI, afterResponse: { response in
                let users = try response.content.decode([Blockchain].self)
                
                XCTAssertEqual(users.count, 1)
                XCTAssertEqual(users[0].name, blockchainsName)
                XCTAssertEqual(users[0].id, content.id)
            })
        })
    }
    
//    func testBlockchainCanAddNewBlockFromAPI() throws {
//        let blockchain = try Blockchain.create(database: app.db)
//        XCTAssertNotNil(blockchain.id)
//
//        let genesisBlock = try Blockchain.createGenesisBlock(blockchainID: blockchain.id!, database: app.db)
//        XCTAssertNotNil(genesisBlock.id)
//
//        try app.test(.POST, "\(blockchainsURI)\(blockchain.id!)", beforeRequest: { req in
//            try req.content.encode(block1)
//        }, afterResponse: { response in
//            let block = try response.content.decode(Block.self)
//            XCTAssertEqual(block.number, 2)
//            XCTAssertEqual(block.data, block1Name)
//            XCTAssertEqual(block.lastHash, genesisBlock.hash)
//        })
//    }
    
//    func testBlockchainStartsWithGenesisBlock() throws {
//        let newBlockchain = Blockchain(name: blockchainsName)
//        
//        try app.test(.POST, blockchainsURI, beforeRequest: { req in
//            try req.content.encode(newBlockchain)
//        }, afterResponse: { response in
//            let blockchain = try response.content.decode(Blockchain.self)
//            XCTAssertEqual(blockchain.name, blockchainsName)
//            XCTAssertNotNil(blockchain.id)
//            
//            try app.test(.GET, "\(blockchainsURI)\(blockchain.id!)/blocks", afterResponse: { response2 in
//                let blocks = try response2.content.decode([Block].self)
//                let genesisBlock = Block.genesis(blockchainID: blockchain.id!)
//                XCTAssertEqual(blocks.count, 1)
//                XCTAssertEqual(blocks[0], genesisBlock)
//            })
//        })
//    }
}
