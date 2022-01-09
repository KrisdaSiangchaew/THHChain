//
//  File.swift
//  
//
//  Created by Krisda on 9/1/2565 BE.
//

import Fluent
import Vapor

final class BlockCategoryPivot: Model {
    static let schema: String = "block-category-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "blockID")
    var block: Block
    
    @Parent(key: "categoryID")
    var category: Category
    
    init() {}
    
    init(id: UUID? = nil, block: Block, category: Category) throws {
        self.id = id
        self.$block.id = try block.requireID()
        self.$category.id = try category.requireID()
    }
}
