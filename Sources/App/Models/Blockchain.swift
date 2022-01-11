//
//  Blockchain.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

final class Blockchain: Model {
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

extension Blockchain: Content { }

extension Blockchain {
    enum BlockchainError: Error {
        case invalidGenesisBlock
        case invalidBlockchain
    }
    
    func addBlock(lastBlock: Block?, data: String?) -> Block? {
        guard let blockchainID = self.id else {
            return nil
        }
        
        guard let lastBlock = lastBlock, let data = data else {
            return Block.genesis(blockchainID: blockchainID)
        }
        
        return Block.mineBlock(lastBlock: lastBlock, data: data)
    }
    
    static func isValidChain(blocks: [Block]) -> Result<Bool, BlockchainError> {
        if blocks[0] != Block.genesis(blockchainID: blocks[0].id!) {
            return .failure(.invalidGenesisBlock)
        }
        
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
