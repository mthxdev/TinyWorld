import SceneKit

public enum HouseType {
    case cottage
    case familyHome
    case shop
    case factory
    case barn
}

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
    private let lampTypes = ["lamp-post", "lamp-garden"]
    private let benchTypes = ["bench", "bench-back"]
    
    private func addFoundation(to node: SCNNode, scale: Float, height: Float, color: UIColor, roughness: Float) {
        if let geo = node.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let depth = max.z - min.z
            
            let foundationGeo = SCNBox(
                width: CGFloat(width * scale * 1.08),
                height: CGFloat(height),
                length: CGFloat(depth * scale * 1.08),
                chamferRadius: 0.06
            )
            let foundationMat = SCNMaterial()
            foundationMat.lightingModel = .physicallyBased
            foundationMat.diffuse.contents = color
            foundationMat.roughness.contents = NSNumber(value: roughness)
            foundationMat.metalness.contents = NSNumber(value: 0.0)
            foundationGeo.materials = [foundationMat]
            
            let foundationNode = SCNNode(geometry: foundationGeo)
            foundationNode.position = SCNVector3(0, -height / 2, 0)
            node.addChildNode(foundationNode)
        }
    }
    
    private func addChimney(to node: SCNNode, scale: Float) {
        let chimneyGeo = SCNBox(width: 0.28, height: 1.3, length: 0.28, chamferRadius: 0.03)
        let chimneyMat = SCNMaterial()
        chimneyMat.lightingModel = .physicallyBased
        chimneyMat.diffuse.contents = UIColor(red: 0.42, green: 0.33, blue: 0.28, alpha: 1.0)
        chimneyMat.roughness.contents = NSNumber(value: 0.88)
        chimneyMat.metalness.contents = NSNumber(value: 0.0)
        chimneyGeo.materials = [chimneyMat]
        
        let chimney = SCNNode(geometry: chimneyGeo)
        chimney.position = SCNVector3(Float.random(in: -1.2...1.2) * scale, 1.55 * scale, Float.random(in: -1.2...1.2) * scale)
        node.addChildNode(chimney)
        
        // Add chimney cap
        let capGeo = SCNBox(width: 0.4, height: 0.12, length: 0.4, chamferRadius: 0.02)
        let capMat = SCNMaterial()
        capMat.lightingModel = .physicallyBased
        capMat.diffuse.contents = UIColor(red: 0.3, green: 0.25, blue: 0.22, alpha: 1.0)
        capMat.roughness.contents = NSNumber(value: 0.9)
        capGeo.materials = [capMat]
        let cap = SCNNode(geometry: capGeo)
        cap.position = SCNVector3(0, 0.72, 0)
        chimney.addChildNode(cap)
    }
    
    private func addEaves(to node: SCNNode, scale: Float) {
        // Add decorative eaves/soffits under the roofline
        let eaveGeo = SCNBox(width: 0.12, height: 0.15, length: 0.12, chamferRadius: 0.01)
        let eaveMat = SCNMaterial()
        eaveMat.lightingModel = .physicallyBased
        eaveMat.diffuse.contents = UIColor(red: 0.85, green: 0.83, blue: 0.78, alpha: 1.0)
        eaveMat.roughness.contents = NSNumber(value: 0.75)
        eaveMat.metalness.contents = NSNumber(value: 0.0)
        eaveGeo.materials = [eaveMat]
        
        // Add eaves at 4 corners
        let offsets: [(Float, Float)] = [(-1, -1), (1, -1), (-1, 1), (1, 1)]
        for (ox, oz) in offsets {
            let eave = SCNNode(geometry: eaveGeo)
            eave.position = SCNVector3(ox * 0.9 * scale, 0.05 * scale, oz * 0.9 * scale)
            node.addChildNode(eave)
        }
    }
    
    private func addShutters(to node: SCNNode, scale: Float, side: Float) {
        let shutterGeo = SCNBox(width: 0.18, height: 0.9, length: 0.04, chamferRadius: 0.01)
        let shutterMat = SCNMaterial()
        shutterMat.lightingModel = .physicallyBased
        shutterMat.diffuse.contents = UIColor(red: 0.55, green: 0.2, blue: 0.18, alpha: 1.0)
        shutterMat.roughness.contents = NSNumber(value: 0.7)
        shutterMat.metalness.contents = NSNumber(value: 0.0)
        shutterGeo.materials = [shutterMat]
        
        for i in 0..<2 {
            let shutter = SCNNode(geometry: shutterGeo)
            shutter.position = SCNVector3(side * 1.3 * scale, 0.7 * scale + Float(i) * 0.45, 1.15 * scale)
            node.addChildNode(shutter)
        }
    }
    
    private func addDoor(to node: SCNNode, scale: Float, side: Float) {
        let doorGeo = SCNBox(width: 0.9, height: 1.8, length: 0.06, chamferRadius: 0.02)
        let doorMat = SCNMaterial()
        doorMat.lightingModel = .physicallyBased
        doorMat.diffuse.contents = UIColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1.0)
        doorMat.roughness.contents = NSNumber(value: 0.65)
        doorMat.metalness.contents = NSNumber(value: 0.0)
        doorGeo.materials = [doorMat]
        
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(side * 0.8 * scale, 0.9 * scale, 1.15 * scale)
        node.addChildNode(door)
        
        // Door handle
        let handleGeo = SCNSphere(radius: 0.03)
        let handleMat = SCNMaterial()
        handleMat.lightingModel = .physicallyBased
        handleMat.metalness.contents = NSNumber(value: 0.8)
        handleMat.roughness.contents = NSNumber(value: 0.3)
        handleGeo.materials = [handleMat]
        let handle = SCNNode(geometry: handleGeo)
        handle.position = SCNVector3(side * 1.15 * scale, 0.9 * scale, 1.2 * scale)
        node.addChildNode(handle)
    }
    
    private func addWindowBox(to node: SCNNode, scale: Float, side: Float) {
        let boxGeo = SCNBox(width: 1.2, height: 0.25, length: 0.2, chamferRadius: 0.02)
        let boxMat = SCNMaterial()
        boxMat.lightingModel = .physicallyBased
        boxMat.diffuse.contents = UIColor(red: 0.55, green: 0.4, blue: 0.3, alpha: 1.0)
        boxMat.roughness.contents = NSNumber(value: 0.8)
        boxMat.metalness.contents = NSNumber(value: 0.0)
        boxGeo.materials = [boxMat]
        
        let box = SCNNode(geometry: boxGeo)
        box.position = SCNVector3(side * 1.5 * scale, 0.8 * scale, 1.1 * scale)
        node.addChildNode(box)
        
        // Flowers in window box
        let flowerColors = [
            UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0),
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0),
            UIColor(red: 0.9, green: 0.5, blue: 0.8, alpha: 1.0)
        ]
        for i in 0..<3 {
            let flowerGeo = SCNSphere(radius: 0.06)
            let flowerMat = SCNMaterial()
            flowerMat.lightingModel = .constant
            flowerMat.emission.contents = flowerColors.randomElement()!
            flowerGeo.materials = [flowerMat]
            
            let flower = SCNNode(geometry: flowerGeo)
            flower.position = SCNVector3(side * 1.5 * scale + Float(i - 1) * 0.3, 1.0 * scale, 1.25 * scale)
            node.addChildNode(flower)
        }
    }
    
    private func addPorchLight(to node: SCNNode, scale: Float, side: Float) {
        let lightGeo = SCNSphere(radius: 0.08)
        let lightMat = SCNMaterial()
        lightMat.lightingModel = .constant
        lightMat.emission.contents = UIColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1.0)
        lightGeo.materials = [lightMat]
        
        let light = SCNNode(geometry: lightGeo)
        light.position = SCNVector3(side * 1.6 * scale, 1.4 * scale, 1.15 * scale)
        node.addChildNode(light)
        
        // Actual light source
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.color = UIColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1.0)
        spotLight.intensity = 80
        spotLight.spotInnerAngle = 30
        spotLight.spotOuterAngle = 60
        spotLight.attenuationStartDistance = 0.5
        spotLight.attenuationEndDistance = 3.0
        spotLight.castsShadow = false
        
        let lightNode = SCNNode()
        lightNode.light = spotLight
        lightNode.position = SCNVector3(side * 1.6 * scale, 1.4 * scale, 1.15 * scale)
        lightNode.eulerAngles.x = -Float.pi / 4
        lightNode.eulerAngles.y = side > 0 ? Float.pi / 2 : -Float.pi / 2
        node.addChildNode(lightNode)
    }
    
    func buildHouse(variant: Int) -> SCNNode {
        let allHouses = cozyCottages + familyHomes
        let safeVariant = abs(variant) % allHouses.count
        let modelName = allHouses[safeVariant]
        
        let node = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        
        // Add subtle variation to make each house unique
        let scaleVariation = Float.random(in: 0.92...1.08)
        node.scale = SCNVector3(scaleVariation, scaleVariation, scaleVariation)
        
        // Add foundation/platform for better ground integration
        addFoundation(to: node, scale: scaleVariation, height: 0.1, color: UIColor(red: 0.32, green: 0.28, blue: 0.24, alpha: 1.0), roughness: 0.92)
        
        // Add chimney (50% chance)
        if Bool.random() { addChimney(to: node, scale: scaleVariation) }
        
        // Add window boxes on front (70% chance)
        if Bool.random() { addWindowBox(to: node, scale: scaleVariation, side: 1) }
        if Bool.random() { addWindowBox(to: node, scale: scaleVariation, side: -1) }
        
        // Add porch light (40% chance)
        if Bool.random() { addPorchLight(to: node, scale: scaleVariation, side: 1) }
        
        return node
    }
    
    func buildFarm() -> SCNNode {
        let modelName = barnTypes[abs(Int.random(in: 0...1000)) % barnTypes.count]
        let barn = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.4...1.7)
        barn.scale = SCNVector3(scale, scale, scale)
        
        // Calculate bounding box for foundation and driveway
        var buildingWidth: Float = 4.0
        var buildingDepth: Float = 4.0
        if let geo = barn.geometry {
            let (min, max) = geo.boundingBox
            buildingWidth = max.x - min.x
            buildingDepth = max.z - min.z
        }
        
        // Add stone foundation
        addFoundation(to: barn, scale: scale, height: 0.15, color: UIColor(red: 0.28, green: 0.25, blue: 0.22, alpha: 1.0), roughness: 0.95)
        
        // Add planters around farm
        let planterCount = Int.random(in: 4...6)
        for i in 0..<planterCount {
            let planter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
            let angle = Float(i) / Float(planterCount) * 2 * Float.pi
            let radius: Float = 3.2 * scale
            planter.position = SCNVector3(sin(angle) * radius, 0.08, cos(angle) * radius)
            planter.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            let planterScale = Float.random(in: 0.9...1.2)
            planter.scale = SCNVector3(planterScale, planterScale, planterScale)
            barn.addChildNode(planter)
        }
        
        // Add varied fence around farm
        let fenceType = fenceTypes.randomElement()!
        let fence = AssetManager.shared.getModel(named: fenceType, folder: "suburban")
        let fenceScale = Float.random(in: 1.4...1.8)
        fence.scale = SCNVector3(fenceScale, 1.0, fenceScale)
        fence.position = SCNVector3(0, 0.08, 0)
        barn.addChildNode(fence)
        
        // Add a second fence layer for larger farms
        if scale > 1.55 {
            let fence2 = AssetManager.shared.getModel(named: fenceTypes.randomElement()!, folder: "suburban")
            let fenceScale2 = fenceScale * 1.3
            fence2.scale = SCNVector3(fenceScale2, 1.0, fenceScale2)
            fence2.position = SCNVector3(0, 0.08, 0)
            barn.addChildNode(fence2)
        }
        
        // Add driveway/path leading to barn
        let driveType = drivewayTypes.randomElement()!
        let driveway = AssetManager.shared.getModel(named: driveType, folder: "suburban")
        driveway.position = SCNVector3(0, 0.03, Float(buildingDepth * scale * 0.7))
        driveway.eulerAngles.y = Float.pi
        barn.addChildNode(driveway)
        
        // Add trees around the farm
        let treeCount = Int.random(in: 3...5)
        for _ in 0..<treeCount {
            let tree = AssetManager.shared.getModel(named: treeTypes.randomElement()!, folder: "suburban")
            let angle = Float.random(in: 0...(2 * Float.pi))
            let dist = Float.random(in: 5.0...8.0) * scale
            tree.position = SCNVector3(sin(angle) * dist, 0.05, cos(angle) * dist)
            tree.scale = SCNVector3(Float.random(in: 1.2...1.8), Float.random(in: 1.2...1.8), Float.random(in: 1.2...1.8))
            tree.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            barn.addChildNode(tree)
        }
        
        // Add a lamp post near entrance
        let lamp = AssetManager.shared.getModel(named: "lamp-post", folder: "suburban")
        lamp.position = SCNVector3(0, 0.1, Float(buildingDepth * scale * 0.8))
        lamp.scale = SCNVector3(1.2, 1.2, 1.2)
        barn.addChildNode(lamp)
        
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
            
            let baseGeo = SCNCylinder(radius: CGFloat(Swift.max(width, depth) * scale * 0.4), height: CGFloat(baseHeight))
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
        
        // Add foundation with slightly lighter color for commercial
        addFoundation(to: shop, scale: scale, height: 0.1, color: UIColor(red: 0.38, green: 0.33, blue: 0.28, alpha: 1.0), roughness: 0.88)
        
        // Add awning/porch area
        if let geo = shop.geometry {
            let (min, max) = geo.boundingBox
            let width = max.x - min.x
            let awningGeo = SCNBox(width: CGFloat(width * scale * 1.2), height: 0.15, length: CGFloat(width * scale * 0.5), chamferRadius: 0.02)
            let awningMat = SCNMaterial()
            awningMat.lightingModel = .physicallyBased
            awningMat.diffuse.contents = UIColor(red: 0.65, green: 0.25, blue: 0.2, alpha: 1.0) // Red striped awning
            awningMat.roughness.contents = NSNumber(value: 0.75)
            awningMat.metalness.contents = NSNumber(value: 0.0)
            awningGeo.materials = [awningMat]
            
            let awning = SCNNode(geometry: awningGeo)
            awning.position = SCNVector3(0, 1.8 * scale, (max.z - min.z) * scale * 0.7)
            shop.addChildNode(awning)
        }
        
        // Add planters by entrance
        let planterCount = Int.random(in: 2...4)
        for i in 0..<planterCount {
            let planter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
            let xPos = Float(i - planterCount / 2) * 1.5
            planter.position = SCNVector3(xPos, 0.08, 1.8 * scale)
            planter.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            let planterScale = Float.random(in: 0.9...1.2)
            planter.scale = SCNVector3(planterScale, planterScale, planterScale)
            shop.addChildNode(planter)
        }
        
        // Add bench near entrance (30% chance)
        if Bool.random() {
            let bench = AssetManager.shared.getModel(named: "bench-back", folder: "suburban")
            bench.position = SCNVector3(Float.random(in: -1.5...1.5), 0.05, 2.0 * scale)
            bench.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            bench.scale = SCNVector3(1.0, 1.0, 1.0)
            shop.addChildNode(bench)
        }
        
        return shop
    }
    
    func buildFactory() -> SCNNode {
        let modelName = factoryTypes[abs(Int.random(in: 0...1000)) % factoryTypes.count]
        let factory = AssetManager.shared.getModel(named: modelName, folder: "suburban")
        let scale = Float.random(in: 1.2...1.5)
        factory.scale = SCNVector3(scale, scale, scale)
        
        // Add larger foundation for industrial feel
        addFoundation(to: factory, scale: scale, height: 0.18, color: UIColor(red: 0.25, green: 0.25, blue: 0.26, alpha: 1.0), roughness: 0.85)
        
        // Add industrial fence around factory
        let fence = AssetManager.shared.getModel(named: "fence-2x3", folder: "suburban")
        fence.scale = SCNVector3(1.6 * scale, 1.2, 1.6 * scale)
        fence.position = SCNVector3(0, 0.1, 0)
        factory.addChildNode(fence)
        
        // Add second fence layer
        let fence2 = AssetManager.shared.getModel(named: "fence-3x3", folder: "suburban")
        fence2.scale = SCNVector3(2.0 * scale, 1.2, 2.0 * scale)
        fence2.position = SCNVector3(0, 0.1, 0)
        factory.addChildNode(fence2)
        
        // Add industrial chimney stacks
        for _ in 0..<2 {
            let chimneyGeo = SCNCylinder(radius: 0.18, height: CGFloat(2.5 * scale))
            let chimneyMat = SCNMaterial()
            chimneyMat.lightingModel = .physicallyBased
            chimneyMat.diffuse.contents = UIColor(red: 0.4, green: 0.35, blue: 0.35, alpha: 1.0)
            chimneyMat.roughness.contents = NSNumber(value: 0.8)
            chimneyMat.metalness.contents = NSNumber(value: 0.0)
            chimneyGeo.materials = [chimneyMat]
            
            let chimney = SCNNode(geometry: chimneyGeo)
            chimney.position = SCNVector3(Float.random(in: -1.5...1.5) * scale, 2.0 * scale, Float.random(in: -1.5...1.5) * scale)
            factory.addChildNode(chimney)
        }
        
        // Add loading area with driveway
        let driveType = drivewayTypes.randomElement()!
        let driveway = AssetManager.shared.getModel(named: driveType, folder: "suburban")
        driveway.position = SCNVector3(0, 0.05, -2.5 * scale)
        driveway.eulerAngles.y = 0
        factory.addChildNode(driveway)
        
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
        
        // Add foundation
        let (foundationColor, foundationRoughness): (UIColor, Float) = {
            switch type {
            case .cottage: return (UIColor(red: 0.32, green: 0.28, blue: 0.24, alpha: 1.0), 0.92)
            case .familyHome: return (UIColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0), 0.9)
            case .shop: return (UIColor(red: 0.38, green: 0.33, blue: 0.28, alpha: 1.0), 0.88)
            case .factory: return (UIColor(red: 0.25, green: 0.25, blue: 0.26, alpha: 1.0), 0.85)
            case .barn: return (UIColor(red: 0.28, green: 0.25, blue: 0.22, alpha: 1.0), 0.95)
            }
        }()
        
        addFoundation(to: node, scale: scale, height: 0.1, color: foundationColor, roughness: foundationRoughness)
        
        // Type-specific details
        switch type {
        case .cottage:
            if Bool.random() { addChimney(to: node, scale: scale) }
            if Bool.random() { addWindowBox(to: node, scale: scale, side: 1) }
            if Bool.random() { addPorchLight(to: node, scale: scale, side: 1) }
        case .familyHome:
            if Bool.random() { addChimney(to: node, scale: scale) }
            if Bool.random() { addWindowBox(to: node, scale: scale, side: 1) }
            if Bool.random() { addWindowBox(to: node, scale: scale, side: -1) }
            if Bool.random() { addPorchLight(to: node, scale: scale, side: 1) }
        case .shop:
            // Handled in buildShop
            break
        case .factory:
            // Handled in buildFactory
            break
        case .barn:
            // Handled in buildFarm
            break
        }
        
        return node
    }
}