//
//  File.swift
//  
//
//  Created by Krisda on 29/12/2564 BE.
//

import Fluent

struct CreateBlockchain: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("blockchains")
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("blockchains").delete()
    }
    
    
}
