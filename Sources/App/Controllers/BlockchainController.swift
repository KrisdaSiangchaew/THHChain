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
        
        // Get unique blockchain
        blockchainsRoutes.get(":blockchainID", use: getHandler)
        
        // Add block
        blockchainsRoutes.post(":blockchainID", use: createBlockHandler)
        
        // Get all blocks
        blockchainsRoutes.get(":blockchainID", "blocks", use: getBlocksHandler)
        
        // Search for a block
        blockchainsRoutes.get(":blockchainID", "search", use: searchBlockHandler)
        
        // Is valid chain
        blockchainsRoutes.get(":blockchainID", "isValid", use: isValidChainHandler)
    }
    
    func searchBlockHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        guard let searchTerm = req.query[Int.self, at: "block"] else {
            throw Abort(.badRequest)
        }
        
        let allBlocks = try getBlocksHandler(req)
        
        return allBlocks.map { blocks in
            return blocks.filter { element in
                element.$number.wrappedValue == searchTerm
            }
        }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let bc = try req.content.decode(Blockchain.self)
        let blockchain = bc.save(on: req.db).map { bc }

        return blockchain.flatMap { bc in
            guard let genesisBlock = bc.addBlock(lastBlock: nil, data: nil) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            return genesisBlock
                .save(on: req.db)
                .map { genesisBlock }
        }
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Blockchain]> {
        Blockchain.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Blockchain> {
        return Blockchain.find(req.parameters.get("blockchainID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getBlocksHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        try getHandler(req)
            .flatMap { blockchain in
                blockchain.$blocks.get(on: req.db)
            }
    }
    
    func createBlockHandler(_ req: Request) throws -> EventLoopFuture<Block> {
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
