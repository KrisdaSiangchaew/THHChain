//
//  File.swift
//  
//
//  Created by Krisda on 9/1/2565 BE.
//

import Fluent
import Vapor

final class Category: Model, Content {
    static var schema: String = "categories"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: BlockCategoryPivot.self, from: \.$category, to: \.$block)
    var blocks: [Block]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
