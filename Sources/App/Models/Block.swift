//
//  Block.swift
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
    
    @Field(key: "number")
    var number: Int
    
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
    
    @Parent(key: "blockchainID")
    var blockchain: Blockchain
    
    init() {}
    
    init(id: UUID? = nil, number: Int, timestamp: Double? = nil, lastHash: String, hash: String, data: String, nonce: Int, difficulty: Int? = nil, blockchainID: Blockchain.IDValue) {
        self.id = id
        self.number = number
        self.timestamp = timestamp ?? Date().timeIntervalSince1970
        self.lastHash = lastHash
        self.hash = hash
        self.data = data
        self.nonce = nonce
        self.difficulty = difficulty ?? BlockConstants.DIFFICULTY.rawValue
        self.$blockchain.id = blockchainID
    }
}

extension Block: Content {}

extension Block {
    static func genesis(blockchainID: UUID) -> Block {
        return Block(
            id: UUID(),
            number: 1,
            timestamp: 1641486927.59881,
            lastHash: "----",
            hash: "T3nGH3NgH3ng",
            data: "Genesis Block",
            nonce: 0,
            difficulty: BlockConstants.DIFFICULTY.rawValue,
            blockchainID: blockchainID)
    }
    
    static func mineBlock(lastBlock: Block, data: String) -> Block {
        let blockNumber = lastBlock.number + 1
        let lastHash = lastBlock.hash
        var timestamp: Double = 0
        var nonce: Int = 0
        var difficulty: Int = BlockConstants.DIFFICULTY.rawValue
        var hash: String

        repeat {
            timestamp = Date().timeIntervalSince1970
            nonce += 1
            difficulty = Block.adjustDifficulty(lastBlock, timestamp)
            hash = Block.hash(timestamp: timestamp, lastHash: lastHash, data: data, nonce: nonce, difficulty: difficulty)
        } while hash.prefix(difficulty) != String(repeating: "0", count: difficulty)
        
        return Block(id: UUID(), number: blockNumber, timestamp: timestamp, lastHash: lastBlock.hash, hash: hash, data: data, nonce: nonce, difficulty: difficulty, blockchainID: lastBlock.$blockchain.id)
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
        difficulty += Int(lastBlock.timestamp) + BlockConstants.MINE_RATE.rawValue > Int(currentTime) ? 1 : -1
        
        if difficulty < 0 { difficulty = 0 }
        
        return difficulty
    }
}

extension Block: Equatable {
    static func == (lhs: Block, rhs: Block) -> Bool {
        Block.hash(block: lhs) == Block.hash(block: rhs)
    }
}
