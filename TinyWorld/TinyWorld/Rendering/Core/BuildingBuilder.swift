import SceneKit

class BuildingBuilder {
    static let shared = BuildingBuilder()
    
    func buildHouse(variant: Int) -> SCNNode {
        // suburban a building-type-a.obj jusqu'a building-type-u.obj
        // a, b, c, d, e = 97, 98, 99, 100, 101
        let chars = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
        let safeVariant = abs(variant) % 10
        let letter = chars[safeVariant]
        let modelName = "building-type-\(letter)"
        
        let node = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        
        // Add a fence around it
        let fence = AssetManager.shared.getModel(named: "fence", folder: "suburban")
        fence.position = SCNVector3(1.5, 0, 1.5)
        node.addChildNode(fence)
        
        return node
    }
    
    func buildFarm() -> SCNNode {
        // Utilisons building-type-k (une grande maison/grange)
        let barn = AssetManager.shared.getModel(named: "building-type-k", folder: "suburban")
        barn.scale = SCNVector3(1.5, 1.5, 1.5)
        
        // We have planters and fences in suburban.
        let planter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
        planter.position = SCNVector3(2.0, 0, 0)
        barn.addChildNode(planter)
        
        return barn
    }
    
    func buildTree(tall: Bool = false) -> SCNNode {
        let name = tall ? "tree-large" : "tree-small"
        return AssetManager.shared.getModel(named: name, folder: "suburban")
    }
    
    func buildShop() -> SCNNode {
        return AssetManager.shared.getModel(named: "building-type-r", folder: "suburban")
    }
    
    func buildFactory() -> SCNNode {
        let node = AssetManager.shared.getModel(named: "building-type-t", folder: "suburban")
        node.scale = SCNVector3(1.2, 1.2, 1.2)
        return node
    }
}
