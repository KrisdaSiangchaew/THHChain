//
//  File.swift
//  
//
//  Created by Krisda on 28/12/2564 BE.
//

import Foundation
import Vapor
import Fluent
import CryptoKit

enum Genesis: String, RawRepresentable {
    case hash = "T3nGH3NgH3ng"
    case data = "Genesis Block"
    case lastHash = "----"
}

enum BlockchainError: Error {
    case invalidGenesisBlock
    case invalidBlockchain
    case cannotFindLastBlock
    case invalidBlock
    case cannotFindBlockchain
    case cannotFindGenesisBlock
    case cannotFindBlock
}

enum BlockConstants: Int {
    case DIFFICULTY = 5
    case MINE_RATE = 10
    case INITIAL_BALANCE = 500
    case MINING_REWARD = 50
}

struct ChainUtil {
    static func hash(inputString: String) -> String {
        let inputData = Data(inputString.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

struct DBServices {
    static func save(blockchain: Blockchain, on database: Database) async throws -> Blockchain {
        try await blockchain.save(on: database)
        
        guard let chain = try await Blockchain.find(try blockchain.requireID(), on: database) else { throw BlockchainError.invalidBlockchain }
        
        return chain
    }
    
    static func getBlock(number: Int, blockchainID: UUID, on database: Database) async throws -> Block {
        guard let blockchain = try await Blockchain.find(blockchainID, on: database) else { throw BlockchainError.cannotFindBlockchain }
        let blocks = try await blockchain.$blocks.get(on: database)
        guard let genesisBlock = blocks.first(where: { block in
            block.number == number
        }) else { throw BlockchainError.cannotFindGenesisBlock }
        return genesisBlock
    }
}
