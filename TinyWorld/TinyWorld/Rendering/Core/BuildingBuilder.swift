import SceneKit

class BuildingBuilder {
    static let shared = BuildingBuilder()
    
    // Building type groups for variety - using all available suburban kit models
    private let cozyCottages = ["building-type-a", "building-type-b", "building-type-c", "building-type-d", "building-type-e"]
    private let familyHomes = ["building-type-f", "building-type-g", "building-type-h", "building-type-i", "building-type-j"]
    private let shopTypes = ["building-type-r", "building-type-s", "building-type-q"]
    private let factoryTypes = ["building-type-t", "building-type-u", "building-type-p", "building-type-o"]
    private let barnTypes = ["building-type-k", "building-type-l", "building-type-m", "building-type-n"]
    
    // Additional decorative elements available
    private let fenceTypes = ["fence", "fence-1x2", "fence-1x3", "fence-1x4", "fence-2x2", "fence-2x3", "fence-3x2", "fence-3x3", "fence-low"]
    private let pathTypes = ["path-stones-short", "path-stones-long", "path-stones-messy", "path-short", "path-long", "path-wood", "path-woodCorner"]
    private let drivewayTypes = ["driveway-short", "driveway-long"]
    private let planterTypes = ["planter"]
    private let treeTypes = ["tree-large", "tree-small"]
    
    func buildHouse(variant: Int) -> SCNNode {
        let allHouses = cozyCottages + familyHomes
        let safeVariant = abs(variant) % allHouses.count
        let modelName = allHouses[safeVariant]
        
        let node = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        
        // Add subtle variation to make each house unique
        let scaleVariation = Float.random(in: 0.92...1.08)
        node.scale = SCNVector3(scaleVariation, scaleVariation, scaleVariation)
        
        // Add small foundation/platform for better ground integration
        if let geo = node.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let depth = max.z - min.z
            let foundationHeight: Float = 0.08
            
            let foundationGeo = SCNBox(
                width: CGFloat(width * scaleVariation * 1.05),
                height: CGFloat(foundationHeight),
                length: CGFloat(depth * scaleVariation * 1.05),
                chamferRadius: 0.05
            )
            let foundationMat = SCNMaterial()
            foundationMat.lightingModel = .physicallyBased
            foundationMat.diffuse.contents = UIColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0)
            foundationMat.roughness.contents = NSNumber(value: 0.9)
            foundationMat.metalness.contents = NSNumber(value: 0.0)
            foundationGeo.materials = [foundationMat]
            
            let foundationNode = SCNNode(geometry: foundationGeo)
            foundationNode.position = SCNVector3(0, -foundationHeight / 2, 0)
            node.addChildNode(foundationNode)
        }
        
        return node
    }
    
    func buildFarm() -> SCNNode {
        let modelName = barnTypes[abs(Int.random(in: 0...1000)) % barnTypes.count]
        let barn = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.4...1.7)
        barn.scale = SCNVector3(scale, scale, scale)
        
        // Add foundation
        if let geo = barn.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let depth = max.z - min.z
            let foundationHeight: Float = 0.1
            
            let foundationGeo = SCNBox(
                width: CGFloat(width * scale * 1.1),
                height: CGFloat(foundationHeight),
                length: CGFloat(depth * scale * 1.1),
                chamferRadius: 0.08
            )
            let foundationMat = SCNMaterial()
            foundationMat.lightingModel = .physicallyBased
            foundationMat.diffuse.contents = UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
            foundationMat.roughness.contents = NSNumber(value: 0.95)
            foundationMat.metalness.contents = NSNumber(value: 0.0)
            foundationGeo.materials = [foundationMat]
            
            let foundationNode = SCNNode(geometry: foundationGeo)
            foundationNode.position = SCNVector3(0, -foundationHeight / 2, 0)
            barn.addChildNode(foundationNode)
        }
        
        // Add planters and farm details
        let planterCount = Int.random(in: 3...5)
        for i in 0..<planterCount {
            let planter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
            let angle = Float(i) / Float(planterCount) * 2 * Float.pi
            let radius: Float = 2.8
            planter.position = SCNVector3(sin(angle) * radius, 0.05, cos(angle) * radius)
            planter.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            let planterScale = Float.random(in: 0.9...1.2)
            planter.scale = SCNVector3(planterScale, planterScale, planterScale)
            barn.addChildNode(planter)
        }
        
        // Add a fence around the farm
        let fenceType = fenceTypes.randomElement()!
        let fence = AssetManager.shared.getModel(named: fenceType, folder: "suburban")
        let fenceScale = Float.random(in: 1.3...1.6)
        fence.scale = SCNVector3(fenceScale, 1.0, fenceScale)
        fence.position = SCNVector3(0, 0.05, 0)
        barn.addChildNode(fence)
        
        // Add a driveway/path leading to barn
        let driveType = drivewayTypes.randomElement()!
        let driveway = AssetManager.shared.getModel(named: driveType, folder: "suburban")
        driveway.position = SCNVector3(0, 0.02, Float(depth * scale * 0.6))
        driveway.eulerAngles.y = Float.pi
        barn.addChildNode(driveway)
        
        // Add a few trees around the farm
        let treeCount = Int.random(in: 2...4)
        for _ in 0..<treeCount {
            let tree = AssetManager.shared.getModel(named: treeTypes.randomElement()!, folder: "suburban")
            let angle = Float.random(in: 0...(2 * Float.pi))
            let dist = Float.random(in: 4.0...7.0)
            tree.position = SCNVector3(sin(angle) * dist, 0.05, cos(angle) * dist)
            tree.scale = SCNVector3(Float.random(in: 1.0...1.5), Float.random(in: 1.0...1.5), Float.random(in: 1.0...1.5))
            tree.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            barn.addChildNode(tree)
        }
        
        return barn
    }
    
    func buildTree(tall: Bool = false) -> SCNNode {
        let name = tall ? "tree-large" : "tree-small"
        let tree = AssetManager.shared.getModel(named: name, folder: "suburban")
        let scale = Float.random(in: tall ? 1.3...2.0 : 0.9...1.4)
        tree.scale = SCNVector3(scale, scale, scale)
        
        // Add small base for ground integration
        if let geo = tree.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let depth = max.z - min.z
            let baseHeight: Float = 0.05
            
            let baseGeo = SCNCylinder(radius: CGFloat(max(width, depth) * scale * 0.4), height: CGFloat(baseHeight))
            let baseMat = SCNMaterial()
            baseMat.lightingModel = .physicallyBased
            baseMat.diffuse.contents = UIColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0)
            baseMat.roughness.contents = NSNumber(value: 0.95)
            baseMat.metalness.contents = NSNumber(value: 0.0)
            baseGeo.materials = [baseMat]
            
            let baseNode = SCNNode(geometry: baseGeo)
            baseNode.position = SCNVector3(0, -baseHeight / 2, 0)
            tree.addChildNode(baseNode)
        }
        
        return tree
    }
    
    func buildShop() -> SCNNode {
        let modelName = shopTypes[abs(Int.random(in: 0...1000)) % shopTypes.count]
        let shop = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.1...1.4)
        shop.scale = SCNVector3(scale, scale, scale)
        
        // Add foundation
        if let geo = shop.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let depth = max.z - min.z
            let foundationHeight: Float = 0.08
            
            let foundationGeo = SCNBox(
                width: CGFloat(width * scale * 1.05),
                height: CGFloat(foundationHeight),
                length: CGFloat(depth * scale * 1.05),
                chamferRadius: 0.05
            )
            let foundationMat = SCNMaterial()
            foundationMat.lightingModel = .physicallyBased
            foundationMat.diffuse.contents = UIColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0)
            foundationMat.roughness.contents = NSNumber(value: 0.9)
            foundationMat.metalness.contents = NSNumber(value: 0.0)
            foundationGeo.materials = [foundationMat]
            
            let foundationNode = SCNNode(geometry: foundationGeo)
            foundationNode.position = SCNVector3(0, -foundationHeight / 2, 0)
            shop.addChildNode(foundationNode)
        }
        
        // Add a small sign or planter
        if Bool.random() {
            let planter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
            planter.position = SCNVector3(Float.random(in: -2...2), 0.05, Float.random(in: -2...2))
            planter.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            shop.addChildNode(planter)
        }
        
        return shop
    }
    
    func buildFactory() -> SCNNode {
        let modelName = factoryTypes[abs(Int.random(in: 0...1000)) % factoryTypes.count]
        let factory = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.2...1.5)
        factory.scale = SCNVector3(scale, scale, scale)
        
        // Add larger foundation for industrial feel
        if let geo = factory.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let depth = max.z - min.z
            let foundationHeight: Float = 0.12
            
            let foundationGeo = SCNBox(
                width: CGFloat(width * scale * 1.1),
                height: CGFloat(foundationHeight),
                length: CGFloat(depth * scale * 1.1),
                chamferRadius: 0.1
            )
            let foundationMat = SCNMaterial()
            foundationMat.lightingModel = .physicallyBased
            foundationMat.diffuse.contents = UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1.0)
            foundationMat.roughness.contents = NSNumber(value: 0.85)
            foundationMat.metalness.contents = NSNumber(value: 0.02)
            foundationGeo.materials = [foundationMat]
            
            let foundationNode = SCNNode(geometry: foundationGeo)
            foundationNode.position = SCNVector3(0, -foundationHeight / 2, 0)
            factory.addChildNode(foundationNode)
        }
        
        // Add fence around factory
        let fence = AssetManager.shared.getModel(named: "fence-2x3", folder: "suburban")
        fence.scale = SCNVector3(1.5, 1.0, 1.5)
        fence.position = SCNVector3(0, 0.05, 0)
        factory.addChildNode(fence)
        
        return factory
    }
    
    // New function for building specific house types with distinct character
    func buildSpecificHouse(type: HouseType, variant: Int) -> SCNNode {
        let models: [String]
        let scaleRange: ClosedRange<Float>
        
        switch type {
        case .cottage:
            models = cozyCottages
            scaleRange = 0.85...1.05
        case .familyHome:
            models = familyHomes
            scaleRange = 1.0...1.2
        case .shop:
            models = shopTypes
            scaleRange = 1.1...1.3
        case .factory:
            models = factoryTypes
            scaleRange = 1.2...1.5
        case .barn:
            models = barnTypes
            scaleRange = 1.4...1.7
        }
        
        let safeVariant = abs(variant) % models.count
        let modelName = models[safeVariant]
        let node = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: scaleRange)
        node.scale = SCNVector3(scale, scale, scale)
        
        return node
    }
}

enum HouseType {
    case cottage
    case familyHome
    case shop
    case factory
    case barn
}
