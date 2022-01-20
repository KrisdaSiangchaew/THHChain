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
    let blockchainName = "THH Blockchain"
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
    
    func testCanCreateBlockchainAndGenesisBlock() async throws {
        let (blockchain, genesisBlock) = try await Blockchain.createBlockchain(name: blockchainName, on: app.db)
        XCTAssertNotNil(blockchain.id)
        XCTAssertNotNil(genesisBlock.id)
        XCTAssertEqual(blockchain.name, blockchainName)
        XCTAssertEqual(genesisBlock.data, genesisBlockData)
    }
    
    func testBlockchainsCanBeCreatedFromAPI() async throws {
        let totalBlockchain = 5
        let name = "blockchain"
        
        for count in 0 ..< totalBlockchain {
            let blockchainName = "\(name)-\(count)"
            try app.test(.POST, blockchainsURI + "name/\(blockchainName)", afterResponse: { response in
                let chain = try response.content.decode(Blockchain.self)
                
                XCTAssertEqual(chain.name, blockchainName)
            })
        }
        
        try app.test(.GET, blockchainsURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let chains = try response.content.decode([Blockchain].self)
            
            XCTAssertEqual(chains.count, totalBlockchain)
            
            for count in 0 ..< totalBlockchain {
                XCTAssertNotNil(chains[count].id)
                XCTAssertEqual(chains[count].name, "\(name)-\(count)")
            }
        })
    }
    
    func testBlockchainsCanBeRetrievedFromAPI() async throws {
        var bcs: [Blockchain] = []
        var blocks: [Block] = []
        
        let totalBlockchain = 5
        let name = "blockchain"
        
        for count in 0 ..< totalBlockchain {
            let (bc, block) = try await Blockchain.createBlockchain(name: "\(name) \(count)", on: app.db)
            bcs.append(bc)
            blocks.append(block)
        }
        
        try app.test(.GET, blockchainsURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let chains = try response.content.decode([Blockchain].self)
            
            XCTAssertEqual(chains.count, totalBlockchain)
            
            for count in 0 ..< totalBlockchain {
                XCTAssertNotNil(chains[count].id)
                XCTAssertEqual(chains[count].name, "\(name) \(count)")
            }
        })
    }
    
    func testGenesisBlockCanBeRetrievedFromAPIAfterNewBlockchain() async throws {
        let (bc, genesisBlock) = try await Blockchain.createBlockchain(name: "test", on: app.db)
        
        guard let blockchainID = bc.id else { throw BlockchainError.invalidBlockchain }
        
        try app.test(.GET, blockchainsURI + "\(blockchainID)/blocks", afterResponse: { response in
            let blocks = try response.content.decode([Block].self)
            
            XCTAssertEqual(blocks.count, 1)
            XCTAssertEqual(blocks[0].data, genesisBlock.data)
            XCTAssertEqual(blocks[0].hash, genesisBlock.hash)
        })
    }
    
    func testCanAddNewBlockAndRetriveThruAPI() async throws {
        let (bc, genesisBlock) = try await Blockchain.createBlockchain(name: "test", on: app.db)
        
        guard let blockchainID = bc.id else { throw BlockchainError.invalidBlockchain }
        
        let blockData = CreateBlockData(data: "Hello, World!", blockchainID: UUID())
        
        try app.test(.POST, blockchainsURI + "\(blockchainID.uuidString)/mine", beforeRequest: { req in
            try req.content.encode(blockData)
        }, afterResponse: { response in
            let block = try response.content.decode(Block.self)
            
            XCTAssertEqual(block.number, 2)
            XCTAssertEqual(block.lastHash, genesisBlockHash)
            
        })
        
        try app.test(.GET, blockchainsURI + "\(blockchainID)/blocks", afterResponse: { response in
            let blocks = try response.content.decode([Block].self)
            
            XCTAssertEqual(blocks.count, 2)
            XCTAssertEqual(blocks[0].data, genesisBlock.data)
            XCTAssertEqual(blocks[0].hash, genesisBlock.hash)
        })
    }
}
