//
//  File.swift
//  
//
//  Created by Krisda on 8/1/2565 BE.
//

import Fluent
import Vapor

struct BlockchainServices {
    // MARK: - CREATE
    
    static func createBlockchain(_ req: Request) throws -> EventLoopFuture<Blockchain> {
        let bc = try req.content.decode(Blockchain.self)
        let blockchain = bc.save(on: req.db).map { bc }
        
        _ = try Self.createGenesisBlock(req, blockchain: blockchain)

        return blockchain
    }
    
    static func createGenesisBlock(_ req: Request, blockchain: EventLoopFuture<Blockchain>) throws -> EventLoopFuture<Block> {
        return blockchain.flatMap { bc in
            guard let genesisBlock = bc.addBlock(lastBlock: nil, data: nil) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            return genesisBlock
                .save(on: req.db)
                .map { genesisBlock }
        }
    }
    
    static func createBlock(_ req: Request, blockchainID: String, data: String) throws -> EventLoopFuture<Block> {
        let blockchain = try BlockchainServices.getBlockchain(req, blockchainID: blockchainID)
        let lastBlock = try BlockchainServices.getLastBlock(req, blockchainID: blockchainID)
        
        let minedBlock = blockchain.and(value: lastBlock)
            .flatMap { chain, lastBlock in
                return lastBlock
                    .map {
                        chain.addBlock(lastBlock: $0, data: data)
                    }
                    .unwrap(or: Abort(.custom(code: 3, reasonPhrase: "Cannot add new block to blockchain id: \(blockchainID)")))
            }
        
        _ = minedBlock.map { $0.save(on: req.db) }
        
        return minedBlock
    }
    
    // MARK: - READ
    
    static func getBlockchain(_ req: Request, blockchainID: String) throws -> EventLoopFuture<Blockchain> {
        guard let blockchainID = UUID(uuidString: blockchainID) else {
            return req.eventLoop.future(error: Abort(.custom(code: 4, reasonPhrase: "Cannot convert '\(blockchainID) to UUID value.")))
        }
        
        return Blockchain.find(blockchainID, on: req.db).unwrap(or: Abort(.custom(code: 1, reasonPhrase: "Blockchain ID: \(blockchainID) not found")))
    }
    
    static func getBlocks(_ req: Request, blockchainID: String) throws -> EventLoopFuture<[Block]> {
        let blockchain = try BlockchainServices.getBlockchain(req, blockchainID: blockchainID)
        let blocks = blockchain.flatMap { chain in
            chain.$blocks.get(on: req.db)
        }
        return blocks
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
    
    // MARK: - OTHERS
    
    static func verifyBlockchain(_ req: Request, blockchainID: String) throws -> EventLoopFuture<[Block]> {
        let blocks = try getBlocks(req, blockchainID: blockchainID)
        
        let result = blocks.map { Blockchain.isValidChain(blocks: $0) }
        
        return result.flatMap { value in
            if case let .failure(error) = value {
                return req.eventLoop.future(error: Abort(.custom(code: 1, reasonPhrase: "Error: \(error)")))
            } else {
                return blocks
            }
        }
    }
}
