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
