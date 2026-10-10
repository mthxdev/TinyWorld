import SceneKit

class BuildingBuilder {
    static let shared = BuildingBuilder()
    
    // Building type groups for variety
    private let cozyHouses = ["building-type-a", "building-type-b", "building-type-c", "building-type-d", "building-type-e"]
    private let largerHouses = ["building-type-f", "building-type-g", "building-type-h", "building-type-i", "building-type-j"]
    private let shopTypes = ["building-type-r", "building-type-s", "building-type-q"]
    private let factoryTypes = ["building-type-t", "building-type-u", "building-type-p", "building-type-o"]
    private let barnTypes = ["building-type-k", "building-type-l", "building-type-m", "building-type-n"]
    
    func buildHouse(variant: Int) -> SCNNode {
        let allHouses = cozyHouses + largerHouses
        let safeVariant = abs(variant) % allHouses.count
        let modelName = allHouses[safeVariant]
        
        let node = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        
        // Add subtle variation to make each house unique
        let scaleVariation = Float.random(in: 0.95...1.05)
        node.scale = SCNVector3(scaleVariation, scaleVariation, scaleVariation)
        
        return node
    }
    
    func buildFarm() -> SCNNode {
        let modelName = barnTypes[abs(Int.random(in: 0...1000)) % barnTypes.count]
        let barn = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.4...1.6)
        barn.scale = SCNVector3(scale, scale, scale)
        
        // Add planters and farm details
        let planterCount = Int.random(in: 2...4)
        for i in 0..<planterCount {
            let planter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
            let angle = Float(i) / Float(planterCount) * 2 * Float.pi
            let radius = 2.5
            planter.position = SCNVector3(sin(angle) * radius, 0, cos(angle) * radius)
            planter.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            barn.addChildNode(planter)
        }
        
        // Add a fence around the farm
        let fence = AssetManager.shared.getModel(named: "fence-low", folder: "suburban")
        fence.scale = SCNVector3(1.2, 1.0, 1.2)
        fence.position = SCNVector3(0, 0, 0)
        barn.addChildNode(fence)
        
        return barn
    }
    
    func buildTree(tall: Bool = false) -> SCNNode {
        let name = tall ? "tree-large" : "tree-small"
        let tree = AssetManager.shared.getModel(named: name, folder: "suburban")
        let scale = Float.random(in: tall ? 1.2...1.8 : 0.8...1.3)
        tree.scale = SCNVector3(scale, scale, scale)
        return tree
    }
    
    func buildShop() -> SCNNode {
        let modelName = shopTypes[abs(Int.random(in: 0...1000)) % shopTypes.count]
        let shop = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.1...1.3)
        shop.scale = SCNVector3(scale, scale, scale)
        return shop
    }
    
    func buildFactory() -> SCNNode {
        let modelName = factoryTypes[abs(Int.random(in: 0...1000)) % factoryTypes.count]
        let factory = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.1...1.4)
        factory.scale = SCNVector3(scale, scale, scale)
        return factory
    }
}
