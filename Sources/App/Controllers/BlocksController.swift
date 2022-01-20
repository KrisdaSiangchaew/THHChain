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
        
        // create new block
        blocksRoutes.post("mine", use: createHandler)
        
        // get all blocks
        blocksRoutes.get(use: getAllHandler)
        
        
        blocksRoutes.get(":blockID", use: getHandler)
        blocksRoutes.get(":blockID", "blockchain", use: getBlockchainHandler)
        blocksRoutes.put(":blockID", use: updateHandler)
        blocksRoutes.get("search", use: searchHandler)
        blocksRoutes.get("sorted", use: sortedHandler)
        
        // Block-category
        blocksRoutes.post(":blockID", "categories", ":categoryID", use: addCategoryHandler)
        blocksRoutes.get(":blockID", "categories", use: getCategoriesHandler)
        blocksRoutes.delete(":blockID", "categories", ":categoryID", use: removeCategoriesHandler)
    }
    
    // MARK: - CREATE
    
    func createHandler(_ req: Request) async throws -> Block {
        let createBlockData = try req.content.decode(CreateBlockData.self)
        
        let blockchainID = createBlockData.blockchainID.uuidString
        let blockData = createBlockData.data
        
        guard let id = UUID(uuidString: blockchainID) else { throw Abort(.badRequest) }
        guard let chain = try await Blockchain.find(id, on: req.db) else { throw Abort(.badRequest) }
        
        return try await chain.addBlock(data: blockData, on: req.db)
    }

    // MARK: - READ
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Block> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func getAllHandler(_ req: Request) async throws -> [Block] {
        return try await Block.query(on: req.db).all()
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
    
    // MARK: - BLOCK-CATEGORY-PIVOT
    func addCategoryHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let blockQuery = Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return blockQuery.and(categoryQuery)
            .flatMap { block, category in
                block
                    .$categories
                    .attach(category, on: req.db)
                    .transform(to: HTTPStatus.created)
            }
            
    }
    
    func getCategoriesHandler(_ req: Request) throws -> EventLoopFuture<[Category]> {
        Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { block in
                block.$categories.get(on: req.db)
            }
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let blockQuery = Block.find(req.parameters.get("blockID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return blockQuery.and(categoryQuery)
            .flatMap { block, category in
                block
                    .$categories
                    .detach(category, on: req.db)
                    .transform(to: HTTPStatus.noContent)
            }
    }
}
