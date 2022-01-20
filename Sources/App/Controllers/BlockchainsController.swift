//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Vapor
import Fluent
import Foundation

struct BlockchainsController: RouteCollection {
    // MARK: - ENDPOINTS

    func boot(routes: RoutesBuilder) throws {
        let blockchainsRoutes = routes.grouped("api", "blockchains")
        
        // create new blockchain
        blockchainsRoutes.post("name", ":blockchainName", use: createHandler)
        
        // get all blockchains
        blockchainsRoutes.get(use: getAllHandler)
        
        // get all blocks of a chain
        blockchainsRoutes.get(":blockchainID", "blocks", use: getAllBlocksHandler)
        
        // get specific block of a chain
        blockchainsRoutes.get(":blockchainID", ":blockID", use: getSpecificBlockHandler)
        
        // update a blockchain
        blockchainsRoutes.put(":blockchainID", "name", ":newName", use: updateHandler)
        
        // delete a chain
        blockchainsRoutes.delete(":blockchainID", use: deleteHandler)
        
        blockchainsRoutes.get("search", use: searchHandler)
    }
    
    // MARK: - CREATE
    
    func createHandler(_ req: Request) async throws -> Blockchain {
        guard let name = req.parameters.get("blockchainName") else { throw Abort(.badRequest) }
        let (blockchain, _) = try await Blockchain.createBlockchain(name: name, on: req.db)
        return blockchain
    }
    
    // MARK: - READ
    
    func getAllHandler(_ req: Request) async throws -> [Blockchain] {
        try await Blockchain.query(on: req.db).all()
    }
    
    func getAllBlocksHandler(_ req: Request) async throws -> [Block] {
        guard let idString = req.parameters.get("blockchainID") else { throw Abort(.badRequest) }
        guard let id = UUID(uuidString: idString) else { throw Abort(.badRequest) }
        guard let chain = try await Blockchain.find(id, on: req.db) else { throw Abort(.badRequest) }
        return try await chain.$blocks.query(on: req.db).all()
    }
    
    func getSpecificBlockHandler(_ req: Request) async throws -> Block {
        guard let idString = req.parameters.get("blockchainID") else { throw Abort(.badRequest) }
        guard let blockIDString = req.parameters.get("blockID") else { throw Abort(.badRequest) }
        
        guard let id = UUID(uuidString: idString) else { throw Abort(.badRequest) }
        guard let blockID = UUID(uuidString: blockIDString) else { throw Abort(.badRequest) }
        
        guard let chain = try await Blockchain.find(id, on: req.db) else { throw Abort(.badRequest) }
        
        let foundBlock = try await chain.$blocks.query(on: req.db).all().first(where: { $0.id == blockID })
        
        guard let foundBlock = foundBlock else {
            throw (BlockchainError.cannotFindBlock)
        }

        return foundBlock
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
