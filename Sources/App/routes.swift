import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "Welcome to THHChain"
    }
    
    let blocksController = BlocksController()
    
    try app.register(collection: blocksController)
}
