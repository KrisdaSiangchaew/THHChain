//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

struct BlockchainsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let blockchainsRoutes = routes.grouped("api", "blockchain")
        
        // Create new blockchain
        blockchainsRoutes.post(use: createHandler)
        
        // Get all blockchains
        blockchainsRoutes.get(use: getAllHandler)
        
        // Get all blocks
        blockchainsRoutes.get(":blockchainID", "blocks", use: getBlocksHandler)
        
        // Add block
        blockchainsRoutes.post(":blockchainID", "add", use: addBlockHandler)
        
        // Is valid chain
        blockchainsRoutes.get(":blockchainID", "isValid", use: isValidChainHandler)
        
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let bc = try req.content.decode(Blockchain.self)
        let blockchain = bc.save(on: req.db).map { bc }
        guard let blockchainID = bc.id else {
            return req.eventLoop.future(error: Abort(.internalServerError))
        }
        return blockchain.flatMap { bc in
            let genesisBlock = Block.genesis(blockchainID: blockchainID)
            return genesisBlock
                .save(on: req.db)
                .map { genesisBlock }
        }
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Blockchain]> {
        Blockchain.query(on: req.db).all()
    }
    
    func getBlocksHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        Blockchain.find(req.parameters.get("blockchainID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { blockchain in
                blockchain.$blocks.get(on: req.db)
            }
    }
    
    func addBlockHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let data = try req.content.decode(CreateBlockData.self)
        let lastBlock = try getBlocksHandler(req).map { $0.last }.unwrap(or: Abort(.notFound))
        
        return lastBlock.flatMap { previousBlock in
            let newBlock = Block.mineBlock(lastBlock: previousBlock, data: data.data)
            return newBlock
                .save(on: req.db)
                .map { newBlock }
        }
    }
    
    func isValidChainHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let allBlocks = try getBlocksHandler(req)
        let result = allBlocks.map { Blockchain.isValidChain(blocks: $0) }
        _ = result.map { print("Is valid chain: \($0)")}
        return result
    }
}
