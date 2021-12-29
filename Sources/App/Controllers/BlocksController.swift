//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

struct BlocksController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let blocksRoutes = routes.grouped("api", "blocks")
        
        // Create
        blocksRoutes.post(use: createHandler)
        
        // Read
        blocksRoutes.get(use: getAllHandler)
        blocksRoutes.get(":blockID", use: getHandler)
        blocksRoutes.get("last", use: getLastHandler)
        
        // Update
        blocksRoutes.put(":blockID", use: updateHandler)
        
        // Delete
        blocksRoutes.delete(":blockID", use: deleteHandler)
        
        // Search
        blocksRoutes.get("search", use: searchHandler)
        
        // Sorted
        blocksRoutes.get("sorted", use: sortedHandler)
    }
    
    // MARK: - CREATE
    func createHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let block = try req.content.decode(Block.self)
        // 1. get the last block, if there is none, generate genesis block
        // 2. extract the lastHash
        // 3. create a new block
        // 4. save and return new block
        return block.save(on: req.db).map {
            block
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
    
    // MARK: - UPDATE
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        let updatedBlock = try req.content.decode(Block.self)
        return Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { block in
                block.timestamp = updatedBlock.timestamp
                block.lastHash = updatedBlock.lastHash
                block.hash = updatedBlock.hash
                block.data = updatedBlock.data
                return block.save(on: req.db).map {
                    block
                }
            }
    }
    
    // MARK: - DELETE
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { block in
                block.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    // MARK: - SEARCH
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Block.query(on: req.db).group(.or) { or in
            or.filter(\.$hash == searchTerm)
            or.filter(\.$data == searchTerm)
        }.all()
    }
    
    // MARK: - SORTED
    func sortedHandler(_ req: Request) throws -> EventLoopFuture<[Block]> {
        Block.query(on: req.db)
            .sort(\.$timestamp, .ascending)
            .all()
    }

}
