import SceneKit
import UIKit

class EnvironmentNode: SCNNode {
    private var directionalLightNode: SCNNode!
    private var ambientLightNode: SCNNode!
    private var fillLightNode: SCNNode!
    
    // Nœud conteneur pour le terrain afin d'éviter qu'il reçoive les taps destinés aux bâtiments
    private let terrainWrapper = SCNNode()
    
    override init() {
        super.init()
        setupLighting()
        setupTerrain()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLighting() {
        // Soleil (Directional Light en mode Forward pour des ombres douces et précises)
        directionalLightNode = SCNNode()
        let dLight = SCNLight()
        dLight.type = .directional
        dLight.castsShadow = true
        dLight.shadowMode = .forward
        dLight.shadowSampleCount = 8
        dLight.shadowRadius = 8.0 // Softer, more natural shadows
        dLight.shadowColor = UIColor.black.withAlphaComponent(0.25) // Slightly stronger but natural
        dLight.orthographicScale = 45.0 // Couvre l'ensemble de l'île (32m) sans coupure d'ombre
        dLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        dLight.intensity = 380 // Reduced from 520 to prevent overexposure
        directionalLightNode.light = dLight
        directionalLightNode.position = SCNVector3(0, 15, 0)
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi / 3.5, y: Float.pi / 4, z: 0)
        addChildNode(directionalLightNode)
        
        // Lumière ambiante chaleureuse - reduced intensity
        ambientLightNode = SCNNode()
        let aLight = SCNLight()
        aLight.type = .ambient
        aLight.intensity = 180 // Reduced from 300
        aLight.color = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0) // Warmer
        ambientLightNode.light = aLight
        addChildNode(ambientLightNode)
        
        // Fill light (Lumière de débouchage opposée au soleil) - reduced
        fillLightNode = SCNNode()
        let fLight = SCNLight()
        fLight.type = .directional
        fLight.intensity = 60 // Reduced from 120
        fLight.castsShadow = false
        fLight.color = UIColor(red: 0.85, green: 0.90, blue: 1.0, alpha: 1.0)
        fillLightNode.light = fLight
        fillLightNode.eulerAngles = SCNVector3(x: Float.pi / 4, y: -Float.pi * 0.75, z: 0)
        addChildNode(fillLightNode)
    }
    
    private func setupTerrain() {
        self.addChildNode(terrainWrapper)
        
        // Custom Hilly Terrain
        let terrain = TerrainBuilder.createTerrain(width: 40.0, depth: 40.0, subdivisions: 40)
        terrain.name = "ground"
        terrainWrapper.addChildNode(terrain)
        
        setupOcean()
        
        // Composition and Vegetation Spawning (Clustered/Organic)
        // Using more varied tree models from the nature pack
        let treeModels = ["tree_oak", "tree_pineDefaultA", "tree_default", "tree_fat", "tree_pineRoundA", "tree_pineRoundB", "tree_cone", "tree_plateau", "tree_thin", "tree_detailed"]
        let rockModels = ["rock_largeA", "rock_largeB", "rock_largeC", "rock_largeD", "rock_largeE", "rock_largeF", "rock_tallA", "rock_tallB", "rock_smallA", "rock_smallB", "rock_smallC", "rock_smallD", "rock_smallE", "rock_smallF", "stone_largeA", "stone_largeB", "stone_largeC", "stone_smallA", "stone_smallB"]
        let plantModels = ["plant_bushDetailed", "plant_bushLarge", "plant_bushSmall", "plant_bushTriangle", "plant_flatShort", "plant_flatTall", "flower_purpleA", "flower_redA", "flower_yellowA", "mushroom_red", "mushroom_tan", "grass_leafs"]
        let propModels = ["log", "stump_old", "stump_round", "stump_roundDetailed", "stump_square", "stump_squareDetailed"]
        
        // Helper to spawn items
        func spawnItem(models: [String], folder: String, x: Float, z: Float, sMin: Float, sMax: Float) {
            if hypot(x, z) > TerrainBuilder.islandRadius - 1.0 { return }
            if abs(x) < 5 && abs(z) < 5 { return } // Keep center clear
            let modelName = models.randomElement()!
            let node = AssetManager.shared.getModel(named: modelName, folder: folder)
            node.position = SCNVector3(x, TerrainBuilder.getHeight(at: x, z: z), z)
            node.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            let s = Float.random(in: sMin...sMax)
            node.scale = SCNVector3(s, s, s)
            terrainWrapper.addChildNode(node)
        }
        
        // Create 6-10 "Groves" or clumps of nature - more for richer environment
        let numGroves = Int.random(in: 6...10)
        for _ in 0..<numGroves {
            let cx = Float.random(in: -14...14)
            let cz = Float.random(in: -14...14)
            if hypot(cx, cz) < 6.0 { continue } // Avoid center plaza
            
            // Trees in this grove - varied sizes and types
            let treeCount = Int.random(in: 4...9)
            for _ in 0..<treeCount {
                let ox = Float.random(in: -3.5...3.5)
                let oz = Float.random(in: -3.5...3.5)
                spawnItem(models: treeModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: 0.9, sMax: 1.7)
            }
            // Rocks around the grove - more variety
            let rockCount = Int.random(in: 2...6)
            for _ in 0..<rockCount {
                let ox = Float.random(in: -2.5...2.5)
                let oz = Float.random(in: -2.5...2.5)
                spawnItem(models: rockModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: 0.5, sMax: 1.3)
            }
            // Plants and flowers - denser
            let plantCount = Int.random(in: 8...18)
            for _ in 0..<plantCount {
                let ox = Float.random(in: -4.5...4.5)
                let oz = Float.random(in: -4.5...4.5)
                spawnItem(models: plantModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: 0.7, sMax: 1.5)
            }
            // Props (logs, stumps) - more frequent
            if Float.random(in: 0...1) > 0.4 {
                let propCount = Int.random(in: 1...3)
                for _ in 0..<propCount {
                    let ox = Float.random(in: -2...2)
                    let oz = Float.random(in: -2...2)
                    spawnItem(models: propModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: 0.7, sMax: 1.3)
                }
            }
        }
        
        // Light global scatter for isolated elements - more for natural feel
        for _ in 0...25 {
            spawnItem(models: treeModels, folder: "nature", x: Float.random(in: -16...16), z: Float.random(in: -16...16), sMin: 0.7, sMax: 1.5)
            spawnItem(models: rockModels, folder: "nature", x: Float.random(in: -16...16), z: Float.random(in: -16...16), sMin: 0.4, sMax: 1.1)
            spawnItem(models: plantModels, folder: "nature", x: Float.random(in: -16...16), z: Float.random(in: -16...16), sMin: 0.6, sMax: 1.3)
        }
        
        // Cozy campfire in the center
        let campfire = AssetManager.shared.getModel(named: "campfire_stones", folder: "nature")
        campfire.position = SCNVector3(0, TerrainBuilder.getHeight(at: 0, z: 0) + 0.05, 0)
        terrainWrapper.addChildNode(campfire)
        
        // Point light for the campfire (orange warm ambient light)
        let campLight = SCNLight()
        campLight.type = .omni
        campLight.color = UIColor(red: 1.0, green: 0.65, blue: 0.3, alpha: 1.0)
        campLight.intensity = 40 // Reduced from 70 to match new lighting balance
        campLight.attenuationStartDistance = 0.5
        campLight.attenuationEndDistance = 3.2 // Rayon doux
        campLight.castsShadow = false
        
        let campLightNode = SCNNode()
        campLightNode.light = campLight
        campLightNode.position = SCNVector3(0, 0.3, 0)
        campfire.addChildNode(campLightNode)
    }
    
    private func setupOcean() {
        // Surface d'océan plane : elle évite le mur vertical d'un cylindre tout en
        // restant assez large pour couvrir l'horizon de la caméra.
        let waterGeo = SCNPlane(width: 130.0, height: 130.0)
        let waterMat = SCNMaterial()
        waterMat.lightingModel = .physicallyBased
        // Base water color - deeper blue-green for stylized look
        waterMat.diffuse.contents = UIColor(red: 0.08, green: 0.35, blue: 0.55, alpha: 1.0)
        waterMat.roughness.contents = NSNumber(value: 0.1) // Very smooth for nice reflections
        waterMat.metalness.contents = NSNumber(value: 0.98) // High metalness for water-like reflection
        waterMat.specular.contents = UIColor(white: 0.9, alpha: 1.0)
        // Semi-transparent to see underwater base slightly, but mostly reflective
        waterMat.transparency = 0.85
        waterMat.transparencyMode = .aOne
        waterMat.writesToDepthBuffer = true
        waterMat.readsFromDepthBuffer = true
        waterMat.isDoubleSided = true // Allow viewing from below
        waterMat.diffuse.magnificationFilter = .linear
        waterMat.diffuse.minificationFilter = .linear
        waterGeo.materials = [waterMat]

        let waterNode = SCNNode(geometry: waterGeo)
        waterNode.name = "ocean"
        waterNode.position = SCNVector3(0, -0.32, 0)
        waterNode.eulerAngles.x = -Float.pi / 2
        terrainWrapper.addChildNode(waterNode)
        
        // Légère onde / respiration aquatique naturelle
        let moveUp = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 3.0)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        waterNode.runAction(SCNAction.repeatForever(SCNAction.sequence([moveUp, moveDown])))
    }
    
    func sync(with worldData: WorldData) {
        for zone in worldData.zones {
            let zoneName = "zone_\(zone.id)"
            if self.childNode(withName: zoneName, recursively: false) == nil {
                let node = createZoneNode(for: zone)
                node.name = zoneName
                self.addChildNode(node)
                
                // Si la zone vient d'etre construite, on pourrait jouer un effet de particules
            } else if let existingNode = self.childNode(withName: zoneName, recursively: false) {
                // Verifier si le statut a change
                let isBuilt = existingNode.childNode(withName: "built_wrapper", recursively: false) != nil
                if zone.isBuilt && !isBuilt {
                    // La zone est desormais construite !
                    existingNode.removeFromParentNode()
                    let newNode = createZoneNode(for: zone)
                    newNode.name = zoneName
                    self.addChildNode(newNode)
                    
                    // Apparition animee !
                    newNode.scale = SCNVector3(0.01, 0.01, 0.01)
                    newNode.runAction(SCNAction.scale(to: 1.0, duration: 0.6).timingMode(.easeOut))
                }
            }
        }
        updateLightingTime(time: worldData.timeOfDay)
    }
    
    private func createZoneNode(for zone: Zone) -> SCNNode {
        if zone.isBuilt {
            return createBuiltZoneNode(zone: zone)
        } else {
            return createUnbuiltZoneNode(zone: zone)
        }
    }
    
    private func createBuiltZoneNode(zone: Zone) -> SCNNode {
        let wrapper = SCNNode()
        wrapper.name = "built_wrapper"
        let py = TerrainBuilder.getHeight(at: zone.centerX, z: zone.centerZ)
        wrapper.position = SCNVector3(zone.centerX, py, zone.centerZ)
        
        // Base de la parcelle (supprimée pour ne pas avoir de primitives)
        
        // Clotures autour de la parcelle
        if zone.type == .home || zone.type == .farm {
            let r = Float(zone.radius) - 0.2
            let fenceSteps = Int(r * 2.0 / 0.8) // approx 0.8 width per fence
            if fenceSteps > 1 {
                for i in 0...fenceSteps {
                    let offset = -r + (Float(i) / Float(fenceSteps)) * (r * 2.0)
                    // Front and Back
                    let fenceF = AssetManager.shared.getModel(named: "fence_simple", folder: "nature")
                    fenceF.position = SCNVector3(offset, 0.1, r)
                    wrapper.addChildNode(fenceF)
                    
                    if i != fenceSteps / 2 { // leave a gap in the back
                        let fenceB = AssetManager.shared.getModel(named: "fence_simple", folder: "nature")
                        fenceB.position = SCNVector3(offset, 0.1, -r)
                        wrapper.addChildNode(fenceB)
                    }
                    
                    // Left and Right
                    let fenceL = AssetManager.shared.getModel(named: "fence_simple", folder: "nature")
                    fenceL.position = SCNVector3(-r, 0.1, offset)
                    fenceL.eulerAngles.y = Float.pi / 2
                    wrapper.addChildNode(fenceL)
                    
                    let fenceR = AssetManager.shared.getModel(named: "fence_simple", folder: "nature")
                    fenceR.position = SCNVector3(r, 0.1, offset)
                    fenceR.eulerAngles.y = Float.pi / 2
                    wrapper.addChildNode(fenceR)
                }
            }
        }

        
        var building: SCNNode?
        
        switch zone.type {
        case .home:
            building = BuildingBuilder.shared.buildHouse(variant: zone.id.hashValue)
        case .work:
            building = BuildingBuilder.shared.buildFactory()
        case .food:
            building = BuildingBuilder.shared.buildShop()
        case .farm:
            building = BuildingBuilder.shared.buildFarm()
        case .forest:
            for _ in 0..<5 {
                let tree = BuildingBuilder.shared.buildTree(tall: true)
                tree.position = SCNVector3(
                    Float.random(in: -zone.radius/1.5...zone.radius/1.5),
                    0,
                    Float.random(in: -zone.radius/1.5...zone.radius/1.5)
                )
                wrapper.addChildNode(tree)
            }
        default:
            building = BuildingBuilder.shared.buildHouse(variant: zone.id.hashValue)
        }
        
        if let b = building {
            b.position.y = 0.1
            wrapper.addChildNode(b)
        }
        
        // Creer le chemin vers le centre du village (origine) avec des pierres (path-stones-short.obj)
        let start = SCNVector3(zone.centerX, py + 0.05, zone.centerZ)
        let end = SCNVector3(0, TerrainBuilder.getHeight(at: 0, z: 0) + 0.05, 0)
        let dx = end.x - start.x
        let dz = end.z - start.z
        let distance = hypot(Float(dx), Float(dz))
        let steps = Int(distance / 1.5)
        
        if steps > 1 {
            for i in 1..<steps {
                let ratio = Float(i) / Float(steps)
                let meander = sin(ratio * Float.pi * 3.0) * 0.4
                let segmentLength = max(distance, 0.001)
                let perpX = -dz / segmentLength
                let perpZ = dx / segmentLength
                let px = start.x + Float(dx) * ratio + meander * perpX
                let pz = start.z + Float(dz) * ratio + meander * perpZ
                let pathStone = AssetManager.shared.getModel(named: "path-stones-short", folder: "suburban")
                pathStone.position = SCNVector3(px, TerrainBuilder.getHeight(at: px, z: pz) + 0.02, pz)
                pathStone.eulerAngles.y = Float.random(in: 0...Float.pi)
                // We add to self instead of wrapper to position paths in world space
                self.addChildNode(pathStone)
            }
        }
        
        return wrapper
    }
    
    private func createUnbuiltZoneNode(zone: Zone) -> SCNNode {
        let wrapper = SCNNode()
        let py = TerrainBuilder.getHeight(at: zone.centerX, z: zone.centerZ)
        wrapper.position = SCNVector3(zone.centerX, py, zone.centerZ)
        
        // Un panneau de construction
        let sign = AssetManager.shared.getModel(named: "sign", folder: "nature")
        sign.position = SCNVector3(0, 0, 0)
        wrapper.addChildNode(sign)
        
        // Zone de clic invisible mais large
        let touchTarget = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0.0)
        touchTarget.firstMaterial?.diffuse.contents = UIColor.clear
        let touchNode = SCNNode(geometry: touchTarget)
        touchNode.position.y = 1.0
        touchNode.name = "unbuilt_zone_\(zone.id)"
        wrapper.addChildNode(touchNode)
        
        return wrapper
    }
    
    private func updateLightingTime(time: Float) {
        var intensity: CGFloat = 380
        var ambientIntensity: CGFloat = 180
        var lightColor = UIColor.white
        var ambientColor = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
        
        if time >= 6 && time <= 9 {
            // Matin doré et chaleureux
            let t = CGFloat((time - 6) / 3)
            intensity = 250 + (130 * t)
            ambientIntensity = 140 + (40 * t)
            lightColor = UIColor(red: 1.0, green: 0.90 + 0.08*t, blue: 0.78 + 0.20*t, alpha: 1.0)
            ambientColor = UIColor(red: 0.98, green: 0.93, blue: 0.88, alpha: 1.0)
        } else if time > 9 && time <= 16 {
            // Jour lumineux et clair
            intensity = 380
            ambientIntensity = 180
            lightColor = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
            ambientColor = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
        } else if time > 16 && time <= 19 {
            // Soir / Crépuscule chaleureux
            let t = CGFloat((time - 16) / 3)
            intensity = 380 - (190 * t)
            ambientIntensity = 180 - (50 * t)
            lightColor = UIColor(red: 1.0, green: 0.82 - 0.20*t, blue: 0.65 - 0.25*t, alpha: 1.0)
            ambientColor = UIColor(red: 0.98 - 0.15*t, green: 0.90 - 0.25*t, blue: 0.85 - 0.10*t, alpha: 1.0)
        } else {
            // Nuit douce, lisible et bleutée
            intensity = 80
            ambientIntensity = 120
            lightColor = UIColor(red: 0.45, green: 0.55, blue: 0.90, alpha: 1.0)
            ambientColor = UIColor(red: 0.25, green: 0.32, blue: 0.52, alpha: 1.0)
        }
        
        directionalLightNode.light?.intensity = intensity
        directionalLightNode.light?.color = lightColor
        ambientLightNode.light?.intensity = ambientIntensity
        ambientLightNode.light?.color = ambientColor
        
        if time >= 6 && time <= 19 {
            let dayProgress = (time - 6) / Float(13.0)
            // Arc solaire naturel et flatteur (32° à 65° au-dessus de l'horizon)
            let elevation = Float.pi / 5.2 + sin(dayProgress * Float.pi) * (Float.pi / 2.8)
            let azimuth = Float.pi / 4.0 + (dayProgress - 0.5) * (Float.pi / 3.0)
            directionalLightNode.eulerAngles = SCNVector3(x: -elevation, y: azimuth, z: 0)
        }
    }
}

// Helper extension for animation
extension SCNAction {
    func timingMode(_ mode: SCNActionTimingMode) -> SCNAction {
        self.timingMode = mode
        return self
    }
}
