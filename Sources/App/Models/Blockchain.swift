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
    static func create(name: String, database: Database) async throws -> Blockchain {
        let blockchain = Task { () -> Blockchain in
            let chain = Blockchain(name: name)
            try await chain.save(on: database)
            try await Block.genesis(blockchainID: try chain.requireID()).save(on: database)

            return chain
        }
        
        return try await blockchain.value
    }
    
    func lastBlock(in database: Database) async throws -> Block {
        let blocks = try await self.$blocks.get(on: database)
        guard let lastBlock = blocks.last else { throw BlockchainError.cannotFindLastBlock }
        return lastBlock
    }
    
    func addBlock(data: String, in database: Database) async throws -> Block {
        let lastBlock = try await self.lastBlock(in: database)
        let minedBlock = await Block.mineBlock(lastBlock: lastBlock, data: data)
        try await minedBlock.save(on: database)
        return minedBlock
    }
    
    static func isValidChain(blocks: [Block]) -> Result<Bool, BlockchainError> {
        
        // 1. Get all blocks in the chain
        // 2. Check for genesis block
        // 3. Check if all blocks are valid
        
        for index in (1 ..< blocks.count) {
            let lastBlock = blocks[index - 1]
            let block = blocks[index]
            
            if (block.lastHash != lastBlock.hash) || (block.hash != Block.hash(block: block)) {
                return .failure(.invalidBlockchain)
            }
        }
        
        return .success(true)
    }
}
