//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

struct CreateBlockchainBlockData: Content {
    let data: String
}

struct BlockchainsController: RouteCollection {
    // MARK: - ENDPOINTS

    func boot(routes: RoutesBuilder) throws {
        let blockchainsRoutes = routes.grouped("api", "blockchains")
            
        // Create
        blockchainsRoutes.post(use: createHandler)
        blockchainsRoutes.post(":blockchainID", use: createBlockHandler)
        
        // Read
        blockchainsRoutes.get(use: getAllHandler)
        blockchainsRoutes.get(":blockchainID", use: getHandler)
        blockchainsRoutes.get(":blockchainID", "blocks", use: getBlocksHandler)
        
        // Is valid chain
        blockchainsRoutes.get(":blockchainID", "verify", use: verifyBlockchainHandler)
    }
    
    // MARK: - CREATE
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Blockchain> {
        try BlockchainServices.createBlockchain(req)
    }
    
    func createBlockHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let newBlock = try req.content.decode(CreateBlockchainBlockData.self)
        
        guard let blockchainID = req.parameters.get("blockchainID") else {
            return req.eventLoop.future(error: Abort(.notFound))
        }
        
        return try BlockchainServices.createBlock(req, blockchainID: blockchainID, data: newBlock.data)
    }
    
    // MARK: - READ
    
    func getBlocksHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        let blockchainID = try getBlockchainID(req)
        
        return try BlockchainServices.getBlocks(req, blockchainID: blockchainID)
    }

    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Blockchain]> {
        Blockchain.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Blockchain> {
        let blockchainID = try getBlockchainID(req)
        
        return try BlockchainServices.getBlockchain(req, blockchainID: blockchainID)
    }
    
    // MARK: - OTHERS
    
    func getBlockchainID(_ req: Request) throws -> String {
        return req.parameters.get("blockchainID") ?? ""
    }
    
    func verifyBlockchainHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        let blockchainID = try getBlockchainID(req)
        
        return try BlockchainServices.verifyBlockchain(req, blockchainID: blockchainID)
    }
}
