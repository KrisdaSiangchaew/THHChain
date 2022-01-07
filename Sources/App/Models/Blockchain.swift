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
    
    init(id: UUID?, name: String) {
        self.id = id
        self.name = name
    }
}

extension Blockchain: Content { }

extension Blockchain {
    func addGenesisBlock() -> Block? {
        guard let blockchainID = self.id else {
            return nil
        }
        return Block.genesis(blockchainID: blockchainID)
    }
    
    static func isValidChain(blocks: [Block]) -> HTTPStatus {
        if blocks[0] != Block.genesis(blockchainID: blocks[0].id!) {
            return HTTPStatus.conflict
        }
        
        for index in (1 ..< blocks.count) {
            let lastBlock = blocks[index - 1]
            let block = blocks[index]
            
            if (block.lastHash != lastBlock.hash) || (block.hash != Block.hash(block: block)) {
                return HTTPStatus.badRequest
            }
        }
        
        return HTTPStatus.accepted
    }
}
