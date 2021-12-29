//
//  File.swift
//  
//
//  Created by Krisda on 28/12/2564 BE.
//

import Vapor
import Fluent
import CryptoKit

final class Block: Model {
    static let schema = "blocks"
    
    @ID
    var id: UUID?
    
    @Field(key: "timestamp")
    var timestamp: Double
    
    @Field(key: "lastHash")
    var lastHash: String
    
    @Field(key: "hash")
    var hash: String
    
    @Field(key: "data")
    var data: String
    
    @Field(key: "nonce")
    var nonce: Int
    
    @Field(key: "difficulty")
    var difficulty: Int
    
    init() {}
    
    init(id: UUID? = nil, timestamp: Double? = nil, lastHash: String, hash: String, data: String, nonce: Int, difficulty: Int? = nil) {
        self.id = id
        self.timestamp = timestamp ?? Date().timeIntervalSince1970
        self.lastHash = lastHash
        self.hash = hash
        self.data = data
        self.nonce = nonce
        self.difficulty = difficulty ?? BlockConstants.DIFFICULTY.rawValue
    }
}

extension Block: Content {}

extension Block {
    static func genesis() -> Block {
        let genesis = Block(lastHash: "", hash: "", data: "genesis-block", nonce: 0)
        return mineBlock(lastBlock: genesis, data: genesis.data)
    }
    
    static func mineBlock(lastBlock: Block, data: String) -> Block {
        var timestamp: Double = 0
        var nonce: Int = 0
        var difficulty: Int = BlockConstants.DIFFICULTY.rawValue
        var hash: String

        repeat {
            timestamp = Date().timeIntervalSince1970
            nonce += 1
            difficulty = Block.adjustDifficulty(lastBlock, timestamp)
            hash = Block.hash(timestamp: timestamp, lastHash: lastBlock.lastHash, data: data, nonce: nonce, difficulty: difficulty)
        } while hash.prefix(difficulty) != String(repeating: "0", count: difficulty)
        
        return Block(timestamp: timestamp, lastHash: lastBlock.lastHash, hash: hash, data: data, nonce: nonce, difficulty: difficulty)
    }
    
    static func hash(
        timestamp: Double,
        lastHash: String,
        data: String,
        nonce: Int,
        difficulty: Int
    ) -> String {
        let inputString = "\(timestamp)\(lastHash)\(data)\(nonce)\(difficulty)"
        return ChainUtil.hash(inputString: inputString)
    }
    
    static func hash(block: Block) -> String {
        return Block.hash(timestamp: block.timestamp, lastHash: block.lastHash, data: block.data, nonce: block.nonce, difficulty: block.difficulty)
    }
    
    static func adjustDifficulty(_ lastBlock: Block, _ currentTime: Double) -> Int {
        var difficulty = lastBlock.difficulty
        difficulty = Int(lastBlock.timestamp) + BlockConstants.MINE_RATE.rawValue > Int(currentTime) ? difficulty + 1: difficulty - 1
        return difficulty
    }
}
