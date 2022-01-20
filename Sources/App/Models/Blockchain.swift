//
//  Blockchain.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

final class Blockchain: Model, Content {
    static let schema = "blockchains"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Children(for: \.$blockchain)
    var blocks: [Block]
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Blockchain {
    static func createBlockchain(name: String, on database: Database) async throws -> (Blockchain, Block) {
        
        let chain = Blockchain(id: UUID(), name: name)
        guard let chainID = chain.id else { throw BlockchainError.invalidBlockchain }
        let genesisBlock = Block.genesis(id: UUID(), blockchainID: chainID)
        
        try await chain.save(on: database)
        try await genesisBlock.save(on: database)
        
        return (chain, genesisBlock)
    }
    
    func blocks(on database: Database) async throws -> [Block] {
        return try await self.$blocks.get(on: database)
    }
    
    func lastBlock(on database: Database) async throws -> Block {
        let blocks = try await self.blocks(on: database)
        guard let block = blocks.last else { throw BlockchainError.cannotFindLastBlock }
        return block
    }
    
    func addBlock(data: String, on database: Database) async throws -> Block {
        let lastBlock = try await self.lastBlock(on: database)
        let minedBlock = await Block.mineBlock(lastBlock: lastBlock, data: data)
        try await minedBlock.save(on: database)
        return minedBlock
    }
    
    func firstBlock(on database: Database) async throws -> Block {
        let blocks = try await self.blocks(on: database)
        guard let block = blocks.first else { throw BlockchainError.cannotFindGenesisBlock }
        return block
    }
    
    func isValidChain(on database: Database) async throws -> Bool {
        let firstBlock = try await self.firstBlock(on: database)
        guard firstBlock.hash == Genesis.hash.rawValue,
              firstBlock.data == Genesis.data.rawValue,
              firstBlock.lastHash == Genesis.lastHash.rawValue else {
                  return false
              }

        let blocks = try await self.blocks(on: database)
        for index in (1 ..< blocks.count) {
            let lastBlock = blocks[index - 1]
            let block = blocks[index]
            
            if (block.lastHash != lastBlock.hash) || (block.hash != Block.hash(block: block)) {
                return false
            }
        }
        
        return true
    }
}
