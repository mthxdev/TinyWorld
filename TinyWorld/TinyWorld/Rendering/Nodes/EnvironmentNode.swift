import SceneKit

class EnvironmentNode: SCNNode {
    private var directionalLightNode: SCNNode
    private var ambientLightNode: SCNNode
    private var zoneNodes: [Int: SCNNode] = [:]
    
    override init() {
        let groundNode = SCNNode()
        let groundGeometry = SCNBox(width: 120, height: 2, length: 120, chamferRadius: 0.0)
        groundGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.45, green: 0.65, blue: 0.35, alpha: 1.0)
        let mainGround = SCNNode(geometry: groundGeometry)
        mainGround.position.y = -1.0
        groundNode.addChildNode(mainGround)
        
        for _ in 0..<20 {
            let hill = SCNSphere(radius: CGFloat.random(in: 4...15))
            hill.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0)
            let hillNode = SCNNode(geometry: hill)
            let angle = Float.random(in: 0...(2 * .pi))
            let distance = Float.random(in: 40...55)
            hillNode.position = SCNVector3(distance * cos(angle), -2.0, distance * sin(angle))
            hillNode.scale.y = 0.5
            groundNode.addChildNode(hillNode)
        }
        
        let plazaGeo = SCNCylinder(radius: 6.0, height: 0.05)
        plazaGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0)
        let plazaNode = SCNNode(geometry: plazaGeo)
        plazaNode.position.y = 0.02
        groundNode.addChildNode(plazaNode)
        
        let fountainBasin = SCNCylinder(radius: 1.5, height: 0.4)
        fountainBasin.firstMaterial?.diffuse.contents = UIColor.gray
        let basinNode = SCNNode(geometry: fountainBasin)
        basinNode.position.y = 0.2
        let fountainWater = SCNCylinder(radius: 1.3, height: 0.42)
        fountainWater.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.8)
        let waterNode = SCNNode(geometry: fountainWater)
        waterNode.position.y = 0.21
        groundNode.addChildNode(basinNode)
        groundNode.addChildNode(waterNode)
        
        let dirLight = SCNLight()
        dirLight.type = .directional
        dirLight.intensity = 1500
        dirLight.castsShadow = true
        dirLight.shadowMode = .deferred
        dirLight.shadowSampleCount = 4
        dirLight.shadowRadius = 3.0
        directionalLightNode = SCNNode()
        directionalLightNode.light = dirLight
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi/3, y: Float.pi/4, z: 0)
        
        let ambLight = SCNLight()
        ambLight.type = .ambient
        ambLight.intensity = 300
        ambientLightNode = SCNNode()
        ambientLightNode.light = ambLight
        
        super.init()
        
        addChildNode(groundNode)
        addChildNode(directionalLightNode)
        addChildNode(ambientLightNode)
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
                // If it was unbuilt and is now built, replace it
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
        
        // Panneau de construction
        let signPost = SCNCylinder(radius: 0.1, height: 1.0)
        signPost.firstMaterial?.diffuse.contents = UIColor.brown
        let postNode = SCNNode(geometry: signPost)
        postNode.position.y = 0.5
        
        let signBoard = SCNBox(width: 1.2, height: 0.8, length: 0.1, chamferRadius: 0.05)
        signBoard.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)
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
        
        // Plaque au sol translucide
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
        
        for i in 0..<steps {
            let ratio = Float(i) / Float(steps)
            let px = start.x + dx * ratio + Float.random(in: -0.3...0.3)
            let pz = start.z + dz * ratio + Float.random(in: -0.3...0.3)
            
            let stoneGeo = SCNBox(width: 0.8, height: 0.02, length: 0.8, chamferRadius: 0.1)
            stoneGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.7, green: 0.65, blue: 0.6, alpha: 1.0)
            let stone = SCNNode(geometry: stoneGeo)
            stone.position = SCNVector3(px, 0.01, pz)
            stone.eulerAngles.y = Float.random(in: 0...2 * .pi)
            pathContainer.addChildNode(stone)
        }
        return pathContainer.flattenedClone()
    }
    
    private func createBuiltZoneNode(zone: Zone) -> SCNNode {
        let zoneContainer = SCNNode()
        zoneContainer.name = "built_zone_\(zone.id)"
        zoneContainer.position = SCNVector3(zone.centerX, 0, zone.centerZ)
        
        switch zone.type {
        case .home:
            let houseNode = SCNNode()
            let wallsGeo = SCNBox(width: 2.2, height: 1.8, length: 2.2, chamferRadius: 0.05)
            wallsGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.9, blue: 0.85, alpha: 1.0)
            let walls = SCNNode(geometry: wallsGeo)
            walls.position.y = 0.9
            houseNode.addChildNode(walls)
            
            let roofGeo = SCNPyramid(width: 2.6, height: 1.4, length: 2.6)
            roofGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.35, blue: 0.3, alpha: 1.0)
            let roof = SCNNode(geometry: roofGeo)
            roof.position.y = 1.8
            houseNode.addChildNode(roof)
            
            let chimneyGeo = SCNBox(width: 0.4, height: 1.0, length: 0.4, chamferRadius: 0.0)
            chimneyGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.5, green: 0.4, blue: 0.4, alpha: 1.0)
            let chimney = SCNNode(geometry: chimneyGeo)
            chimney.position = SCNVector3(0.6, 2.2, -0.4)
            houseNode.addChildNode(chimney)
            
            let doorGeo = SCNBox(width: 0.6, height: 1.0, length: 0.1, chamferRadius: 0.02)
            doorGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
            let door = SCNNode(geometry: doorGeo)
            let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
            houseNode.eulerAngles.y = -angleToCenter + Float.pi/2
            door.position = SCNVector3(0, 0.5, 1.15)
            houseNode.addChildNode(door)
            
            for _ in 0..<3 {
                let bushGeo = SCNSphere(radius: CGFloat.random(in: 0.3...0.5))
                bushGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
                let bush = SCNNode(geometry: bushGeo)
                bush.position = SCNVector3(Float.random(in: -1.5...1.5), 0.3, Float.random(in: 1.2...1.8))
                houseNode.addChildNode(bush)
            }
            zoneContainer.addChildNode(houseNode.flattenedClone())
            
        case .work:
            let factoryNode = SCNNode()
            let mainBGeo = SCNBox(width: 4.0, height: 2.2, length: 3.0, chamferRadius: 0.1)
            mainBGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.65, green: 0.65, blue: 0.7, alpha: 1.0)
            let mainB = SCNNode(geometry: mainBGeo)
            mainB.position.y = 1.1
            factoryNode.addChildNode(mainB)
            
            let roofBGeo = SCNBox(width: 4.2, height: 0.2, length: 3.2, chamferRadius: 0.0)
            roofBGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
            let roofB = SCNNode(geometry: roofBGeo)
            roofB.position.y = 2.3
            factoryNode.addChildNode(roofB)
            
            for i in -1...1 {
                let pipeGeo = SCNCylinder(radius: 0.3, height: 1.5)
                pipeGeo.firstMaterial?.diffuse.contents = UIColor.gray
                let pipe = SCNNode(geometry: pipeGeo)
                pipe.position = SCNVector3(Float(i) * 1.0, 3.0, -0.5)
                factoryNode.addChildNode(pipe)
            }
            let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
            factoryNode.eulerAngles.y = -angleToCenter + Float.pi/2
            zoneContainer.addChildNode(factoryNode.flattenedClone())
            
        case .food:
            let shopNode = SCNNode()
            let counterGeo = SCNBox(width: 2.5, height: 1.0, length: 1.5, chamferRadius: 0.1)
            counterGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)
            let counter = SCNNode(geometry: counterGeo)
            counter.position.y = 0.5
            shopNode.addChildNode(counter)
            
            let postGeo = SCNCylinder(radius: 0.1, height: 2.0)
            postGeo.firstMaterial?.diffuse.contents = UIColor.brown
            for x in [-1.1, 1.1] {
                for z in [-0.6, 0.6] {
                    let post = SCNNode(geometry: postGeo)
                    post.position = SCNVector3(x, 1.0, z)
                    shopNode.addChildNode(post)
                }
            }
            
            let awningGeo = SCNBox(width: 2.8, height: 0.1, length: 2.2, chamferRadius: 0.0)
            awningGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0)
            let awning = SCNNode(geometry: awningGeo)
            awning.position = SCNVector3(0, 2.0, 0.2)
            awning.eulerAngles.x = Float.pi / 12
            shopNode.addChildNode(awning)
            
            let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
            shopNode.eulerAngles.y = -angleToCenter + Float.pi/2
            zoneContainer.addChildNode(shopNode.flattenedClone())
            
        case .park, .forest:
            let parkNode = SCNNode()
            let grassGeo = SCNCylinder(radius: CGFloat(zone.radius), height: 0.1)
            grassGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.35, green: 0.65, blue: 0.25, alpha: 1.0)
            let grass = SCNNode(geometry: grassGeo)
            grass.position.y = 0.05
            parkNode.addChildNode(grass)
            
            let treeCount = zone.type == .forest ? 15 : 6
            for _ in 0..<treeCount {
                let tree = SCNNode()
                let trunkH = Float.random(in: 1.0...1.8)
                let trunkGeo = SCNCylinder(radius: 0.2, height: CGFloat(trunkH))
                trunkGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
                let trunk = SCNNode(geometry: trunkGeo)
                trunk.position.y = trunkH / 2
                tree.addChildNode(trunk)
                
                let leavesR = Float.random(in: 0.8...1.5)
                let leavesGeo = SCNSphere(radius: CGFloat(leavesR))
                leavesGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
                let leaves = SCNNode(geometry: leavesGeo)
                leaves.position.y = trunkH + (leavesR * 0.4)
                tree.addChildNode(leaves)
                
                let r = Float.random(in: 0...(zone.radius - 1.0))
                let theta = Float.random(in: 0...2 * .pi)
                tree.position = SCNVector3(r * cos(theta), 0, r * sin(theta))
                parkNode.addChildNode(tree)
            }
            zoneContainer.addChildNode(parkNode.flattenedClone())
            
        case .farm:
            let farmNode = SCNNode()
            // Grange
            let barnGeo = SCNBox(width: 3.5, height: 2.0, length: 2.5, chamferRadius: 0.05)
            barnGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
            let barn = SCNNode(geometry: barnGeo)
            barn.position.y = 1.0
            farmNode.addChildNode(barn)
            let bRoofGeo = SCNPyramid(width: 4.0, height: 1.5, length: 3.0)
            bRoofGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
            let bRoof = SCNNode(geometry: bRoofGeo)
            bRoof.position.y = 2.0
            farmNode.addChildNode(bRoof)
            
            // Enclos / Champs
            let fieldGeo = SCNBox(width: 4.0, height: 0.1, length: 4.0, chamferRadius: 0)
            fieldGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
            let field = SCNNode(geometry: fieldGeo)
            field.position = SCNVector3(3.0, 0.05, 0)
            farmNode.addChildNode(field)
            
            let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
            farmNode.eulerAngles.y = -angleToCenter + Float.pi/2
            zoneContainer.addChildNode(farmNode.flattenedClone())
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
        var ambientIntensity: CGFloat = 300
        var ambientColor = UIColor.white
        
        if time >= 6 && time < 9 {
            let t = CGFloat((time - 6) / 3)
            intensity = 200 + (1000 * t)
            ambientIntensity = 300 + (400 * t)
            color = UIColor(red: 1.0, green: 0.8 + 0.2*t, blue: 0.6 + 0.4*t, alpha: 1.0)
        } else if time >= 9 && time < 16 {
            intensity = 1200
            ambientIntensity = 700
            color = UIColor(white: 1.0, alpha: 1.0)
        } else if time >= 16 && time < 19 {
            let t = CGFloat((time - 16) / 3)
            intensity = 1200 - (1000 * t)
            ambientIntensity = 700 - (400 * t)
            color = UIColor(red: 1.0, green: 1.0 - 0.4*t, blue: 1.0 - 0.6*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0 - 0.3*t, green: 1.0 - 0.5*t, blue: 1.0 - 0.2*t, alpha: 1.0)
        } else {
            intensity = 0
            ambientIntensity = 200
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
