//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent

struct BlockchainsController: RouteCollection {
    // MARK: - ENDPOINTS

    func boot(routes: RoutesBuilder) throws {
        let blockchainsRoutes = routes.grouped("api", "blockchains")
        
        blockchainsRoutes.post("name", ":blockchainName", use: createHandler)
        blockchainsRoutes.get(use: getAllHandler)
        blockchainsRoutes.get(":blockchainID", "blocks", use: getBlocksHandler)
        blockchainsRoutes.put(":blockchainID", "name", ":newName", use: updateHandler)
        blockchainsRoutes.delete(":blockchainID", use: deleteHandler)
        blockchainsRoutes.get("search", use: searchHandler)
    }
    
    // MARK: - CREATE
    
    func createHandler(_ req: Request) async throws -> Blockchain {
        guard let name = req.parameters.get("blockchainName") else { throw Abort(.badRequest) }
        return try await Blockchain.create(name: name, database: req.db)
    }
    
    // MARK: - READ
    
    func getAllHandler(_ req: Request) async throws -> [Blockchain] {
        try await Blockchain.query(on: req.db).all()
    }
    
    func getBlocksHandler(_ req: Request) async throws -> [Block] {
        guard let idString = req.parameters.get("blockchainID") else { throw Abort(.badRequest) }
        guard let id = UUID(uuidString: idString) else { throw Abort(.badRequest) }
        guard let chain = try await Blockchain.find(id, on: req.db) else { throw Abort(.badRequest) }
        return try await chain.$blocks.query(on: req.db).all()
    }
    
    // MARK: - UPDATE
    
    func updateHandler(_ req: Request) async throws -> Blockchain {
        guard let blockchainID = UUID(uuidString: req.parameters.get("blockchainID") ?? "") else { throw Abort(.badRequest) }
        guard let newName = req.parameters.get("newName") else { throw Abort(.badRequest) }
        
        async let foundChainData = Blockchain.find(blockchainID, on: req.db)
        guard let foundChain = try await foundChainData else { throw Abort(.notFound )}
        foundChain.name = newName
        try await foundChain.save(on: req.db)
        return foundChain
    }
    
    // MARK: - DELETE
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let blockchainID = UUID(uuidString: req.parameters.get("blockchainID") ?? "") else { throw Abort(.badRequest) }
        async let foundChainData = Blockchain.find(blockchainID, on: req.db)
        guard let foundChain = try await foundChainData else { throw Abort(.notFound) }
        try await foundChain.delete(on: req.db)
        return HTTPStatus.noContent
    }
    
    // MARK: - SEARCH
    func searchHandler(_ req: Request) async throws -> [Blockchain] {
        guard let searchName = req.query[String.self, at: "name"] else { throw Abort(.badRequest) }
        return try await Blockchain.query(on: req.db).filter(\.$name == searchName).all()
    }
}
