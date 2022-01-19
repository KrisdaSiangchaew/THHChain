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
    var timestamp: Date
    
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
    
    @Siblings(through: BlockCategoryPivot.self, from: \.$block, to: \.$category)
    var categories: [Category]
    
    init() {}
    
    init(id: UUID? = nil, number: Int, timestamp: Date, lastHash: String, hash: String, data: String, nonce: Int, difficulty: Int? = nil, blockchainID: Blockchain.IDValue) {
        self.id = id
        self.number = number
        self.timestamp = timestamp
        self.lastHash = lastHash
        self.hash = hash
        self.data = data
        self.nonce = nonce
        self.difficulty = difficulty ?? BlockConstants.DIFFICULTY.rawValue
        self.$blockchain.id = blockchainID
    }
}

extension Block: Content {
    func beforeEncode() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        ContentConfiguration.global.use(encoder: encoder, for: .json)
    }
    
    func afterDecode() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        ContentConfiguration.global.use(decoder: decoder, for: .json)
    }
}

extension Block {
    static func genesis(blockchainID: UUID) -> Block {
        return Block(
            number: 1,
            timestamp: Date(),
            lastHash: "----",
            hash: "T3nGH3NgH3ng",
            data: "Genesis Block",
            nonce: 0,
            difficulty: BlockConstants.DIFFICULTY.rawValue,
            blockchainID: blockchainID
        )
    }
    
    static func lastBlock(of blockchainID: UUID, in database: Database) async throws -> Block {
        guard let blockchain = try await Blockchain.find(blockchainID, on: database) else { throw BlockchainError.invalidBlockchain }
        return try await blockchain.lastBlock(in: database)
    }
    
    static func addBlock(data: String, lastBlock: Block, in database: Database) async throws -> Block {
        let minedBlock = await Block.mineBlock(lastBlock: lastBlock, data: data)
        try await minedBlock.save(on: database)
        return minedBlock
    }
    
    static func mineBlock(lastBlock: Block, data: String) async -> Block {
        let minedBlock = Task { () -> Block in
            var timestamp: Date = Date()
            var nonce: Int = 0
            var difficulty: Int = BlockConstants.DIFFICULTY.rawValue
            var hash: String = ""
            
            repeat {
                timestamp = Date()
                nonce += 1
                difficulty = Block.adjustDifficulty(lastBlock, timestamp)
                hash = Block.hash(timestamp: timestamp, lastHash: lastBlock.hash, data: data, nonce: nonce, difficulty: difficulty)
            } while hash.prefix(difficulty) != String(repeating: "0", count: difficulty)
            
            return Block(id: UUID(), number: lastBlock.number + 1, timestamp: timestamp, lastHash: lastBlock.hash, hash: hash, data: data, nonce: nonce, difficulty: difficulty, blockchainID: lastBlock.$blockchain.id)
        }
        return await minedBlock.value
    }
    
    static func hash(
        timestamp: Date,
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
    
    static func adjustDifficulty(_ lastBlock: Block, _ timestamp: Date) -> Int {
        var difficulty = lastBlock.difficulty
        let timeDifference = timestamp.timeIntervalSince(lastBlock.timestamp)
        difficulty += BlockConstants.MINE_RATE.rawValue > Int(timeDifference) ? 1 : -1
        
        if difficulty < 0 { difficulty = 0 }
        
        return difficulty
    }
}

extension Block: Equatable {
    static func == (lhs: Block, rhs: Block) -> Bool {
        Block.hash(block: lhs) == Block.hash(block: rhs)
    }
}
