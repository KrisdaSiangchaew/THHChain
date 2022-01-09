//
//  File.swift
//  
//
//  Created by Krisda on 9/1/2565 BE.
//

import Vapor

struct CategoriesController: RouteCollection {
    // MARK: - ENDPOINTS
    
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoutes = routes.grouped("api", "categories")
        
        // Create
        categoriesRoutes.post(use: createHandler)
        
        // Read
        categoriesRoutes.get(use: getAllHandler)
        categoriesRoutes.get(":categoryID", use: getHandler)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let data = try req.content.decode(Category.self)
        return data.save(on: req.db).map { data }
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Category]> {
        Category.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
}
