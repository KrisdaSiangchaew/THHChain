//
//  File.swift
//  
//
//  Created by Krisda on 28/12/2564 BE.
//

import Fluent

struct CreateBlock: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Block.schema)
            .id()
            .field("number", .int, .required)
            .field("timestamp", .date, .required)
            .field("lastHash", .string, .required)
            .field("hash", .string, .required)
            .field("data", .string, .required)
            .field("nonce", .int, .required)
            .field("difficulty", .int, .required)
            .field("blockchainID", .uuid, .required, .references(Blockchain.schema, "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("blocks").delete()
    }
    

}
