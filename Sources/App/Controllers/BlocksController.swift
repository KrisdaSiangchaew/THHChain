//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

struct CreateBlockData: Content {
    let data: String
    let blockchainID: UUID
}

struct BlocksController: RouteCollection {
    // MARK: - ENDPOINTS
    
    func boot(routes: RoutesBuilder) throws {
        let blocksRoutes = routes.grouped("api", "blocks")
        
        // Create
        blocksRoutes.post(use: createHandler)

        // Read
        blocksRoutes.get(use: getAllHandler)
        blocksRoutes.get(":blockID", use: getHandler)
        blocksRoutes.get(":blockID", "blockchain", use: getBlockchainHandler)
        
        // Update
        blocksRoutes.put(":blockID", use: updateHandler)

        // Search
        blocksRoutes.get("search", use: searchHandler)

        // Sorted
        blocksRoutes.get("sorted", use: sortedHandler)
    }
    
    // MARK: - CREATE
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let createBlock = try req.content.decode(CreateBlockData.self)
        
        let blockchainID = createBlock.blockchainID.uuidString
        let blockData = createBlock.data
        
        return try BlockchainServices.createBlock(req, blockchainID: blockchainID, data: blockData)
    }

    // MARK: - READ
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        Block.query(on: req.db).all()
    }
    
    func getBlockchainHandler(_ req: Request) throws -> EventLoopFuture<Blockchain> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { block in
                block.$blockchain.get(on: req.db)
            }
    }
    
    // MARK: - UPDATE
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let block = try getHandler(req)
        let updateData = try req.content.decode(CreateBlockData.self)
        return block.flatMap { content in
            content.data = updateData.data
            content.$blockchain.id = updateData.blockchainID
            return content.save(on: req.db).map { content }
        }
    }

    // MARK: - SEARCH
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        guard let searchTerm = req.query[Int.self, at: "block"] else {
            throw Abort(.badRequest)
        }
        
        return Block.query(on: req.db)
            .filter(\.$number == searchTerm)
            .all()
    }

    // MARK: - SORTED
    func sortedHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        Block.query(on: req.db)
            .sort(\.$number, .ascending)
            .all()
    }
}
