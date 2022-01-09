import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "Welcome to THHChain"
    }
    
    let blockchainsController = BlockchainsController()
    try app.register(collection: blockchainsController)

    let blocksController = BlocksController()
    try app.register(collection: blocksController)
    
    let categoriesController = CategoriesController()
    try app.register(collection: categoriesController)
}
