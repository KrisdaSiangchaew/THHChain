//
//  File.swift
//  
//
//  Created by Krisda on 9/1/2565 BE.
//

import Fluent

struct CreateBlockCategoryPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlockCategoryPivot.schema)
            .id()
            .field("blockID", .uuid, .required, .references(Block.schema, "id", onDelete: .cascade))
            .field("categoryID", .uuid, .required, .references(Category.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlockCategoryPivot.schema).delete()
    }
    
    
}
