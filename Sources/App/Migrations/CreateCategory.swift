//
//  File.swift
//  
//
//  Created by Krisda on 9/1/2565 BE.
//

import Fluent

struct CreateCategory: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.schema)
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.schema).delete()
    }
    
    
}
