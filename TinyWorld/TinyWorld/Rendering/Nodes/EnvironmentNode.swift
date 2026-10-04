import SceneKit

class EnvironmentNode: SCNNode {
    private var directionalLightNode: SCNNode
    private var ambientLightNode: SCNNode
    private var zoneNodes: [Int: SCNNode] = [:]
    
    override init() {
        let groundNode = SCNNode()
        
        // Base plate
        let groundGeometry = SCNBox(width: 150, height: 4, length: 150, chamferRadius: 0.0)
        groundGeometry.firstMaterial?.diffuse.contents = TextureGenerator.shared.getGrassTexture()
        let mainGround = SCNNode(geometry: groundGeometry)
        mainGround.position.y = -2.0
        groundNode.addChildNode(mainGround)
        
        // Relief : ondulations
        for _ in 0..<30 {
            let hill = SCNSphere(radius: CGFloat.random(in: 10...25))
            hill.firstMaterial?.diffuse.contents = TextureGenerator.shared.getGrassTexture()
            let hillNode = SCNNode(geometry: hill)
            let angle = Float.random(in: 0...(2 * .pi))
            let distance = Float.random(in: 35...65)
            hillNode.position = SCNVector3(distance * cos(angle), -4.0, distance * sin(angle))
            hillNode.scale.y = 0.2 // Aplatir pour faire des collines douces
            groundNode.addChildNode(hillNode)
        }
        
        // Place de village centrale pavée
        let plazaGeo = SCNCylinder(radius: 6.0, height: 0.05)
        plazaGeo.firstMaterial?.diffuse.contents = TextureGenerator.shared.getStoneTexture()
        let plazaNode = SCNNode(geometry: plazaGeo)
        plazaNode.position.y = 0.02
        groundNode.addChildNode(plazaNode)
        
        // Fontaine centrale
        let fountainBasin = SCNCylinder(radius: 1.5, height: 0.4)
        fountainBasin.firstMaterial?.diffuse.contents = TextureGenerator.shared.getStoneTexture()
        let basinNode = SCNNode(geometry: fountainBasin)
        basinNode.position.y = 0.2
        let fountainWater = SCNCylinder(radius: 1.3, height: 0.42)
        fountainWater.firstMaterial?.diffuse.contents = TextureGenerator.shared.getWaterTexture()
        let waterNode = SCNNode(geometry: fountainWater)
        waterNode.position.y = 0.21
        groundNode.addChildNode(basinNode)
        groundNode.addChildNode(waterNode)
        
        // Soleil - Fix des ombres
        let dirLight = SCNLight()
        dirLight.type = .directional
        dirLight.intensity = 1200
        dirLight.castsShadow = true
        // Shadow mode .forward pour iOS donne des ombres nettes si on contraint la carte
        dirLight.shadowMode = .forward
        dirLight.shadowColor = UIColor.black.withAlphaComponent(0.45)
        dirLight.shadowRadius = 1.0
        dirLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        dirLight.orthographicScale = 30 // Limite la carte d'ombre au village
        
        directionalLightNode = SCNNode()
        directionalLightNode.light = dirLight
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi/3, y: Float.pi/4, z: 0)
        
        // Lumiere ambiante (Chaude)
        let ambLight = SCNLight()
        ambLight.type = .ambient
        ambLight.intensity = 400
        ambientLightNode = SCNNode()
        ambientLightNode.light = ambLight
        
        // Fill light (Lumière de remplissage sans ombre pour éclaircir la zone sombre)
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.intensity = 300
        fillLight.castsShadow = false
        let fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.eulerAngles = SCNVector3(x: Float.pi/4, y: -Float.pi/4, z: 0) // Oppose au soleil
        
        super.init()
        
        addChildNode(groundNode)
        addChildNode(directionalLightNode)
        addChildNode(ambientLightNode)
        addChildNode(fillLightNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func sync(with world: WorldData) {
        updateTimeOfDay(world.timeOfDay)
        
        for zone in world.zones {
            if zoneNodes[zone.id] == nil {
                let node = zone.isBuilt ? createBuiltZoneNode(zone: zone) : createUnbuiltZoneNode(zone: zone)
                addChildNode(node)
                zoneNodes[zone.id] = node
                
                if zone.isBuilt {
                    let pathNode = createPath(from: SCNVector3(zone.centerX, 0.01, zone.centerZ), to: SCNVector3(0, 0.01, 0))
                    addChildNode(pathNode)
                }
            } else {
                if zone.isBuilt, let existing = zoneNodes[zone.id], existing.name?.starts(with: "unbuilt") == true {
                    existing.removeFromParentNode()
                    let newNode = createBuiltZoneNode(zone: zone)
                    addChildNode(newNode)
                    zoneNodes[zone.id] = newNode
                    
                    let pathNode = createPath(from: SCNVector3(zone.centerX, 0.01, zone.centerZ), to: SCNVector3(0, 0.01, 0))
                    addChildNode(pathNode)
                }
            }
        }
    }
    
    private func createUnbuiltZoneNode(zone: Zone) -> SCNNode {
        let node = SCNNode()
        node.name = "unbuilt_zone_\(zone.id)"
        node.position = SCNVector3(zone.centerX, 0, zone.centerZ)
        
        let signPost = SCNCylinder(radius: 0.1, height: 1.0)
        signPost.firstMaterial?.diffuse.contents = TextureGenerator.shared.getWoodTexture()
        let postNode = SCNNode(geometry: signPost)
        postNode.position.y = 0.5
        
        let signBoard = SCNBox(width: 1.2, height: 0.8, length: 0.1, chamferRadius: 0.05)
        signBoard.firstMaterial?.diffuse.contents = TextureGenerator.shared.getWoodTexture()
        let boardNode = SCNNode(geometry: signBoard)
        boardNode.position = SCNVector3(0, 0.8, 0.1)
        
        let touchTarget = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0.0)
        touchTarget.firstMaterial?.diffuse.contents = UIColor.clear
        let touchNode = SCNNode(geometry: touchTarget)
        touchNode.position.y = 1.0
        touchNode.name = "zone_\(zone.id)"
        
        node.addChildNode(postNode)
        node.addChildNode(boardNode)
        node.addChildNode(touchNode)
        
        let basePlate = SCNCylinder(radius: CGFloat(zone.radius), height: 0.02)
        basePlate.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
        let plateNode = SCNNode(geometry: basePlate)
        plateNode.position.y = 0.01
        node.addChildNode(plateNode)
        
        return node
    }
    
    private func createPath(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let pathContainer = SCNNode()
        let dx = end.x - start.x
        let dz = end.z - start.z
        let distance = (dx*dx + dz*dz).squareRoot()
        let steps = Int(distance / 0.8)
        
        let stoneTex = TextureGenerator.shared.getStoneTexture()
        
        for i in 0..<steps {
            let ratio = Float(i) / Float(steps)
            let px = start.x + dx * ratio + Float.random(in: -0.3...0.3)
            let pz = start.z + dz * ratio + Float.random(in: -0.3...0.3)
            
            let stoneGeo = SCNBox(width: 0.8, height: 0.04, length: 0.8, chamferRadius: 0.1)
            stoneGeo.firstMaterial?.diffuse.contents = stoneTex
            let stone = SCNNode(geometry: stoneGeo)
            stone.position = SCNVector3(px, 0.02, pz)
            stone.eulerAngles.y = Float.random(in: 0...2 * .pi)
            pathContainer.addChildNode(stone)
        }
        return pathContainer.flattenedClone()
    }
    
    private func createBuiltZoneNode(zone: Zone) -> SCNNode {
        let zoneContainer = SCNNode()
        zoneContainer.name = "built_zone_\(zone.id)"
        zoneContainer.position = SCNVector3(zone.centerX, 0, zone.centerZ)
        
        let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
        let orient = -angleToCenter + Float.pi/2
        
        switch zone.type {
        case .home:
            let houseNode = BuildingBuilder.shared.buildHouse()
            houseNode.eulerAngles.y = orient
            zoneContainer.addChildNode(houseNode)
            
        case .work:
            // TODO Replace with more detailed Work building (use buildFarm structure as base)
            let factoryNode = SCNNode()
            let mainBGeo = SCNBox(width: 4.0, height: 2.2, length: 3.0, chamferRadius: 0.1)
            mainBGeo.firstMaterial?.diffuse.contents = TextureGenerator.shared.getStoneTexture()
            let mainB = SCNNode(geometry: mainBGeo)
            mainB.position.y = 1.1
            factoryNode.addChildNode(mainB)
            
            let roofBGeo = SCNBox(width: 4.2, height: 0.2, length: 3.2, chamferRadius: 0.0)
            roofBGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
            let roofB = SCNNode(geometry: roofBGeo)
            roofB.position.y = 2.3
            factoryNode.addChildNode(roofB)
            
            factoryNode.eulerAngles.y = orient
            zoneContainer.addChildNode(factoryNode.flattenedClone())
            
        case .food:
            let shopNode = SCNNode()
            let counterGeo = SCNBox(width: 2.5, height: 1.0, length: 1.5, chamferRadius: 0.1)
            counterGeo.firstMaterial?.diffuse.contents = TextureGenerator.shared.getWoodTexture()
            let counter = SCNNode(geometry: counterGeo)
            counter.position.y = 0.5
            shopNode.addChildNode(counter)
            
            let awningGeo = SCNBox(width: 2.8, height: 0.1, length: 2.2, chamferRadius: 0.0)
            awningGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0)
            let awning = SCNNode(geometry: awningGeo)
            awning.position = SCNVector3(0, 2.0, 0.2)
            awning.eulerAngles.x = Float.pi / 12
            shopNode.addChildNode(awning)
            
            shopNode.eulerAngles.y = orient
            zoneContainer.addChildNode(shopNode.flattenedClone())
            
        case .park, .forest:
            let parkNode = SCNNode()
            let treeCount = zone.type == .forest ? 15 : 6
            for _ in 0..<treeCount {
                let tree = BuildingBuilder.shared.buildTree(tall: zone.type == .forest)
                let r = Float.random(in: 0...(zone.radius - 1.0))
                let theta = Float.random(in: 0...2 * .pi)
                tree.position = SCNVector3(r * cos(theta), 0, r * sin(theta))
                parkNode.addChildNode(tree)
            }
            zoneContainer.addChildNode(parkNode.flattenedClone()) // Regrouping all trees in one call !
            
        case .farm:
            let farmNode = BuildingBuilder.shared.buildFarm()
            farmNode.eulerAngles.y = orient
            zoneContainer.addChildNode(farmNode)
        }
        
        castShadows(node: zoneContainer)
        return zoneContainer
    }
    
    private func castShadows(node: SCNNode) {
        node.castsShadow = true
        node.childNodes.forEach { castShadows(node: $0) }
    }
    
    private func updateTimeOfDay(_ time: Float) {
        var intensity: CGFloat = 200
        var color = UIColor.white
        var ambientIntensity: CGFloat = 400
        var ambientColor = UIColor.white
        
        if time >= 6 && time < 9 {
            let t = CGFloat((time - 6) / 3)
            intensity = 200 + (1000 * t)
            ambientIntensity = 300 + (300 * t)
            color = UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1.0)
        } else if time >= 9 && time < 16 {
            intensity = 1200
            ambientIntensity = 600
            color = UIColor.white
        } else if time >= 16 && time < 19 {
            let t = CGFloat((time - 16) / 3)
            intensity = 1200 - (1000 * t)
            ambientIntensity = 600 - (300 * t)
            color = UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)
            ambientColor = UIColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)
        } else {
            intensity = 0
            ambientIntensity = 300
            ambientColor = UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        }
        
        directionalLightNode.light?.intensity = intensity
        directionalLightNode.light?.color = color
        ambientLightNode.light?.intensity = ambientIntensity
        ambientLightNode.light?.color = ambientColor
        
        if time >= 6 && time <= 18 {
            let dayProgress = (time - 6) / 12.0
            let angleX = Float.pi - (Float.pi * dayProgress)
            directionalLightNode.eulerAngles = SCNVector3(x: -angleX, y: Float.pi/4, z: 0)
        }
    }
}
