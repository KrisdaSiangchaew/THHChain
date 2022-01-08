//
//  File.swift
//  
//
//  Created by Krisda on 8/1/2565 BE.
//

import Fluent
import Vapor

struct BlockchainServices {
    static func getBlockchain(_ req: Request, blockchainID: String) throws -> EventLoopFuture<Blockchain> {
        guard let blockchainID = UUID(uuidString: blockchainID) else {
            return req.eventLoop.future(error: Abort(.custom(code: 4, reasonPhrase: "Cannot convert '\(blockchainID) to UUID value.")))
        }
        
        return Blockchain.find(blockchainID, on: req.db).unwrap(or: Abort(.custom(code: 1, reasonPhrase: "Blockchain ID: \(blockchainID) not found")))
    }
    
    static func getLastBlock(_ req: Request, blockchainID: String) throws -> EventLoopFuture<Block> {
        let blockchain = try getBlockchain(req, blockchainID: blockchainID)
        return blockchain
            .flatMap { chain in
                chain.$blocks.get(on: req.db)
                    .map { $0.last }
                    .unwrap(or: Abort(.custom(code: 2, reasonPhrase: "Cannot find last block for blockchain id: \(blockchainID)")))
            }
    }
    
    static func createBlock(_ req: Request, blockchainID: String, data: String) throws -> EventLoopFuture<Block> {
        let blockchain = try BlockchainServices.getBlockchain(req, blockchainID: blockchainID)
        
        let lastBlock = try BlockchainServices.getLastBlock(req, blockchainID: blockchainID)
        
        return blockchain.and(value: lastBlock)
            .flatMap { chain, lastBlock in
                return lastBlock
                    .map {
                        chain.addBlock(lastBlock: $0, data: data)
                    }
                    .unwrap(or: Abort(.custom(code: 3, reasonPhrase: "Cannot add new block to blockchain id: \(blockchainID)")))
            }
    }
}
