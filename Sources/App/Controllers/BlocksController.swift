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
//    let blockchainID: UUID
}

struct BlocksController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let blocksRoutes = routes.grouped("api", "blocks")
        
        // Create new block
        blocksRoutes.post(use: createHandler)

        // Read
        blocksRoutes.get(use: getAllHandler)
        blocksRoutes.get(":blockID", use: getHandler)
        blocksRoutes.get("last", use: getLastHandler)
        blocksRoutes.get(":blockID", "blockchain", use: getBlockchainHandler)

        // Search
        blocksRoutes.get("search", use: searchHandler)

        // Sorted
        blocksRoutes.get("sorted", use: sortedHandler)
    }
    
    // MARK: - CREATE BLOCK
    func createHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let data = try req.content.decode(CreateBlockData.self)
        let lastBlock = try getLastHandler(req)
        
        return lastBlock.flatMap { previousBlock in
            let newBlock = Block.mineBlock(lastBlock: previousBlock, data: data.data)
            return newBlock
                .save(on: req.db)
                .map { newBlock }
        }
    }

    // MARK: - READ
    func getHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        Block.query(on: req.db).all()
    }

    func getLastHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        Block.query(on: req.db)
            .all()
            .map { $0.last }
            .unwrap(or: Abort(.notFound))
    }
    
    func getBlockchainHandler(_ req: Request) throws -> EventLoopFuture<Blockchain> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { block in
                block.$blockchain.get(on: req.db)
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
