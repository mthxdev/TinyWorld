import SceneKit

class EnvironmentNode: SCNNode {
    private var directionalLightNode: SCNNode
    private var ambientLightNode: SCNNode
    private var builtZoneNodes: [Int: SCNNode] = [:]
    
    override init() {
        // Sol texturise avec plusieurs nuances
        let groundNode = SCNNode()
        let groundGeometry = SCNBox(width: 100, height: 2, length: 100, chamferRadius: 0.0)
        groundGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.45, green: 0.65, blue: 0.35, alpha: 1.0)
        let mainGround = SCNNode(geometry: groundGeometry)
        mainGround.position.y = -1.0
        groundNode.addChildNode(mainGround)
        
        // Collines d'arriere plan
        for _ in 0..<15 {
            let hill = SCNSphere(radius: CGFloat.random(in: 4...12))
            hill.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0)
            let hillNode = SCNNode(geometry: hill)
            let angle = Float.random(in: 0...(2 * .pi))
            let distance = Float.random(in: 30...45)
            hillNode.position = SCNVector3(distance * cos(angle), -2.0, distance * sin(angle))
            hillNode.scale.y = 0.5
            groundNode.addChildNode(hillNode)
        }
        
        // Place de village centrale pavée
        let plazaGeo = SCNCylinder(radius: 6.0, height: 0.05)
        plazaGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0)
        let plazaNode = SCNNode(geometry: plazaGeo)
        plazaNode.position.y = 0.02
        groundNode.addChildNode(plazaNode)
        
        // Fontaine centrale
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
        
        // Soleil (Directional light) - Ombres douces
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
        
        // Lumiere ambiante
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
        
        for zone in world.zones where zone.isBuilt {
            if builtZoneNodes[zone.id] == nil {
                let node = createZoneNode(zone: zone)
                addChildNode(node)
                builtZoneNodes[zone.id] = node
                
                // Dessiner un chemin en terre vers la place centrale
                let pathNode = createPath(from: SCNVector3(zone.centerX, 0.01, zone.centerZ), to: SCNVector3(0, 0.01, 0))
                addChildNode(pathNode)
            }
        }
    }
    
    private func createPath(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let pathContainer = SCNNode()
        let dx = end.x - start.x
        let dz = end.z - start.z
        let distance = (dx*dx + dz*dz).squareRoot()
        let steps = Int(distance / 0.8)
        
        for i in 0..<steps {
            let ratio = Float(i) / Float(steps)
            let px = start.x + dx * ratio + Float.random(in: -0.2...0.2)
            let pz = start.z + dz * ratio + Float.random(in: -0.2...0.2)
            
            let stoneGeo = SCNBox(width: 0.6, height: 0.02, length: 0.6, chamferRadius: 0.1)
            stoneGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.7, green: 0.65, blue: 0.6, alpha: 1.0)
            let stone = SCNNode(geometry: stoneGeo)
            stone.position = SCNVector3(px, 0.01, pz)
            stone.eulerAngles.y = Float.random(in: 0...2 * .pi)
            pathContainer.addChildNode(stone)
        }
        
        return pathContainer.flattenedClone()
    }
    
    private func createZoneNode(zone: Zone) -> SCNNode {
        let zoneContainer = SCNNode()
        zoneContainer.position = SCNVector3(zone.centerX, 0, zone.centerZ)
        
        switch zone.type {
        case .home:
            // Maison detaillee
            let houseNode = SCNNode()
            
            // Murs
            let wallsGeo = SCNBox(width: 2.2, height: 1.8, length: 2.2, chamferRadius: 0.05)
            wallsGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.9, blue: 0.85, alpha: 1.0)
            let walls = SCNNode(geometry: wallsGeo)
            walls.position.y = 0.9
            houseNode.addChildNode(walls)
            
            // Toit
            let roofGeo = SCNPyramid(width: 2.6, height: 1.4, length: 2.6)
            roofGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.35, blue: 0.3, alpha: 1.0)
            let roof = SCNNode(geometry: roofGeo)
            roof.position.y = 1.8
            houseNode.addChildNode(roof)
            
            // Cheminee
            let chimneyGeo = SCNBox(width: 0.4, height: 1.0, length: 0.4, chamferRadius: 0.0)
            chimneyGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.5, green: 0.4, blue: 0.4, alpha: 1.0)
            let chimney = SCNNode(geometry: chimneyGeo)
            chimney.position = SCNVector3(0.6, 2.2, -0.4)
            houseNode.addChildNode(chimney)
            
            // Porte
            let doorGeo = SCNBox(width: 0.6, height: 1.0, length: 0.1, chamferRadius: 0.02)
            doorGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
            let door = SCNNode(geometry: doorGeo)
            let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
            
            // Orienter la maison grossierement vers le centre (0,0)
            houseNode.eulerAngles.y = -angleToCenter + Float.pi/2
            door.position = SCNVector3(0, 0.5, 1.1)
            houseNode.addChildNode(door)
            
            // Petits buissons
            for _ in 0..<3 {
                let bushGeo = SCNSphere(radius: CGFloat.random(in: 0.3...0.5))
                bushGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
                let bush = SCNNode(geometry: bushGeo)
                bush.position = SCNVector3(Float.random(in: -1.5...1.5), 0.3, Float.random(in: 1.2...1.8))
                houseNode.addChildNode(bush)
            }
            
            zoneContainer.addChildNode(houseNode.flattenedClone())
            
        case .work:
            // Usine / Bureau stylise
            let factoryNode = SCNNode()
            let mainBGeo = SCNBox(width: 4.0, height: 2.2, length: 3.0, chamferRadius: 0.1)
            mainBGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.65, green: 0.65, blue: 0.7, alpha: 1.0)
            let mainB = SCNNode(geometry: mainBGeo)
            mainB.position.y = 1.1
            factoryNode.addChildNode(mainB)
            
            // Toit plat avec bordure
            let roofBGeo = SCNBox(width: 4.2, height: 0.2, length: 3.2, chamferRadius: 0.0)
            roofBGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
            let roofB = SCNNode(geometry: roofBGeo)
            roofB.position.y = 2.3
            factoryNode.addChildNode(roofB)
            
            // Cheminees industrielles
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
            // Restaurant / Kiosque
            let shopNode = SCNNode()
            let counterGeo = SCNBox(width: 2.5, height: 1.0, length: 1.5, chamferRadius: 0.1)
            counterGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)
            let counter = SCNNode(geometry: counterGeo)
            counter.position.y = 0.5
            shopNode.addChildNode(counter)
            
            // Poteaux
            let postGeo = SCNCylinder(radius: 0.1, height: 2.0)
            postGeo.firstMaterial?.diffuse.contents = UIColor.brown
            for x in [-1.1, 1.1] {
                for z in [-0.6, 0.6] {
                    let post = SCNNode(geometry: postGeo)
                    post.position = SCNVector3(x, 1.0, z)
                    shopNode.addChildNode(post)
                }
            }
            
            // Auvent (Awning) incline
            let awningGeo = SCNBox(width: 2.8, height: 0.1, length: 2.2, chamferRadius: 0.0)
            awningGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0) // Orange
            let awning = SCNNode(geometry: awningGeo)
            awning.position = SCNVector3(0, 2.0, 0.2)
            awning.eulerAngles.x = Float.pi / 12
            shopNode.addChildNode(awning)
            
            let angleToCenter = atan2(0 - zone.centerZ, 0 - zone.centerX)
            shopNode.eulerAngles.y = -angleToCenter + Float.pi/2
            
            zoneContainer.addChildNode(shopNode.flattenedClone())
            
        case .park:
            // Grand parc verdoyant
            let parkNode = SCNNode()
            
            // Pelouse surelevee
            let grassGeo = SCNCylinder(radius: CGFloat(zone.radius), height: 0.1)
            grassGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.7, blue: 0.3, alpha: 1.0)
            let grass = SCNNode(geometry: grassGeo)
            grass.position.y = 0.05
            parkNode.addChildNode(grass)
            
            // Arbres detailles
            for _ in 0..<6 {
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
        }
        
        // Tout faire projeter des ombres
        castShadows(node: zoneContainer)
        
        return zoneContainer
    }
    
    private func castShadows(node: SCNNode) {
        node.castsShadow = true
        node.childNodes.forEach { castShadows(node: $0) }
    }
    
    private func updateTimeOfDay(_ time: Float) {
        // Interpolation complexe du soleil
        // 6h: lever du soleil (faible, orange), 12h: Zenith (fort, blanc), 18h: Coucher (faible, orange), Nuit: off
        var intensity: CGFloat = 200
        var color = UIColor.white
        var ambientIntensity: CGFloat = 300
        var ambientColor = UIColor.white
        
        if time >= 6 && time < 9 { // Matin
            let t = CGFloat((time - 6) / 3)
            intensity = 200 + (1000 * t)
            ambientIntensity = 300 + (400 * t)
            color = UIColor(red: 1.0, green: 0.8 + 0.2*t, blue: 0.6 + 0.4*t, alpha: 1.0)
        } else if time >= 9 && time < 16 { // Jour
            intensity = 1200
            ambientIntensity = 700
            color = UIColor(white: 1.0, alpha: 1.0)
        } else if time >= 16 && time < 19 { // Soir
            let t = CGFloat((time - 16) / 3)
            intensity = 1200 - (1000 * t)
            ambientIntensity = 700 - (400 * t)
            color = UIColor(red: 1.0, green: 1.0 - 0.4*t, blue: 1.0 - 0.6*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0 - 0.3*t, green: 1.0 - 0.5*t, blue: 1.0 - 0.2*t, alpha: 1.0)
        } else { // Nuit
            intensity = 0 // Pas de soleil
            ambientIntensity = 200
            ambientColor = UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        }
        
        directionalLightNode.light?.intensity = intensity
        directionalLightNode.light?.color = color
        
        ambientLightNode.light?.intensity = ambientIntensity
        ambientLightNode.light?.color = ambientColor
        
        // Rotation du soleil
        // A 6h, soleil a l'est (x negatif). A 12h, soleil au zenith. A 18h, ouest (x positif).
        if time >= 6 && time <= 18 {
            let dayProgress = (time - 6) / 12.0
            let angleX = Float.pi - (Float.pi * dayProgress) // de PI a 0
            directionalLightNode.eulerAngles = SCNVector3(x: -angleX, y: Float.pi/4, z: 0)
        }
    }
}
