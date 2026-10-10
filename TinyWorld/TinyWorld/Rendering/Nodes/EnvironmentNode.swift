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
        dLight.shadowSampleCount = 12
        dLight.shadowRadius = 10.0 // Softer, more natural shadows
        dLight.shadowColor = UIColor.black.withAlphaComponent(0.22) // Natural shadow density
        dLight.orthographicScale = 48.0 // Couvre l'ensemble de l'île (32m) sans coupure d'ombre
        dLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        dLight.intensity = 420 // Balanced for good contrast without overexposure
        directionalLightNode.light = dLight
        directionalLightNode.position = SCNVector3(0, 15, 0)
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi / 3.5, y: Float.pi / 4, z: 0)
        addChildNode(directionalLightNode)
        
        // Lumière ambiante chaleureuse - soft fill
        ambientLightNode = SCNNode()
        let aLight = SCNLight()
        aLight.type = .ambient
        aLight.intensity = 140
        aLight.color = UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0) // Warm cream
        ambientLightNode.light = aLight
        addChildNode(ambientLightNode)
        
        // Fill light (Lumière de débouchage opposée au soleil) - cool blue tint
        fillLightNode = SCNNode()
        let fLight = SCNLight()
        fLight.type = .directional
        fLight.intensity = 80
        fLight.castsShadow = false
        fLight.color = UIColor(red: 0.82, green: 0.88, blue: 1.0, alpha: 1.0)
        fillLightNode.light = fLight
        fillLightNode.eulerAngles = SCNVector3(x: Float.pi / 3.5, y: -Float.pi * 0.7, z: 0)
        addChildNode(fillLightNode)
        
        // Subtle rim light for edge definition
        let rimLightNode = SCNNode()
        let rLight = SCNLight()
        rLight.type = .directional
        rLight.intensity = 35
        rLight.castsShadow = false
        rLight.color = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        rimLightNode.light = rLight
        rimLightNode.eulerAngles = SCNVector3(x: Float.pi / 2.5, y: Float.pi, z: 0)
        addChildNode(rimLightNode)
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
        let treeModels = ["tree_oak", "tree_pineDefaultA", "tree_default", "tree_fat", "tree_pineRoundA", "tree_pineRoundB", "tree_cone", "tree_plateau", "tree_thin", "tree_detailed", "tree_pineTallA", "tree_pineTallB", "tree_tall", "tree_simple"]
        let rockModels = ["rock_largeA", "rock_largeB", "rock_largeC", "rock_largeD", "rock_largeE", "rock_largeF", "rock_tallA", "rock_tallB", "rock_smallA", "rock_smallB", "rock_smallC", "rock_smallD", "rock_smallE", "rock_smallF", "stone_largeA", "stone_largeB", "stone_largeC", "stone_smallA", "stone_smallB", "stone_smallC"]
        let plantModels = ["plant_bushDetailed", "plant_bushLarge", "plant_bushSmall", "plant_bushTriangle", "plant_flatShort", "plant_flatTall", "flower_purpleA", "flower_redA", "flower_yellowA", "mushroom_red", "mushroom_tan", "grass_leafs", "plant_bushDetailed", "plant_bushLarge"]
        let propModels = ["log", "stump_old", "stump_round", "stump_roundDetailed", "stump_square", "stump_squareDetailed", "stump_oldTall"]
        
        // Helper to spawn items
        func spawnItem(models: [String], folder: String, x: Float, z: Float, sMin: Float, sMax: Float) {
            if hypot(x, z) > TerrainBuilder.islandRadius - 1.2 { return }
            if abs(x) < 4.5 && abs(z) < 4.5 { return } // Keep center clear for campfire and plaza
            let modelName = models.randomElement()!
            let node = AssetManager.shared.getModel(named: modelName, folder: folder)
            node.position = SCNVector3(x, TerrainBuilder.getHeight(at: x, z: z), z)
            node.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            let s = Float.random(in: sMin...sMax)
            node.scale = SCNVector3(s, s, s)
            terrainWrapper.addChildNode(node)
        }
        
        // Create biome zones for more natural distribution
        // Zone 1: Northwest - dense forest
        // Zone 2: Northeast - rocky hills with pines
        // Zone 3: South - open meadow with scattered trees
        // Zone 4: East - flowering slopes
        // Zone 5: West - rocky coast
        
        let biomeCenters: [(Float, Float, String)] = [
            (-9.0, -8.0, "forest"),      // Northwest forest
            (8.0, -7.0, "pine_hills"),   // Northeast pine hills
            (0.0, 10.0, "meadow"),       // South meadow
            (-6.0, 9.0, "flowering"),    // East flowering slopes
            (11.0, 4.0, "rocky_coast"),  // West rocky coast
            (-3.0, -11.0, "mixed"),      // Southwest mixed
            (5.0, -10.0, "coastal_pine"), // Southeast coastal pine
        ]
        
        for (cx, cz, biome) in biomeCenters {
            let radius: Float = Float.random(in: 4.0...6.5)
            let treeCount, rockCount, plantCount, propCount: Int
            let treeScale: ClosedRange<Float>
            let rockScale: ClosedRange<Float>
            let plantScale: ClosedRange<Float>
            
            switch biome {
            case "forest":
                treeCount = Int.random(in: 8...14)
                rockCount = Int.random(in: 3...6)
                plantCount = Int.random(in: 12...20)
                propCount = Int.random(in: 2...4)
                treeScale = 1.0...1.8
                rockScale = 0.6...1.4
                plantScale = 0.8...1.6
            case "pine_hills":
                treeCount = Int.random(in: 6...12)
                rockCount = Int.random(in: 6...10)
                plantCount = Int.random(in: 8...14)
                propCount = Int.random(in: 1...3)
                treeScale = 1.1...1.9
                rockScale = 0.7...1.5
                plantScale = 0.7...1.4
            case "meadow":
                treeCount = Int.random(in: 3...6)
                rockCount = Int.random(in: 2...5)
                plantCount = Int.random(in: 15...25)
                propCount = Int.random(in: 0...2)
                treeScale = 0.9...1.5
                rockScale = 0.5...1.2
                plantScale = 0.9...1.7
            case "flowering":
                treeCount = Int.random(in: 4...8)
                rockCount = Int.random(in: 2...4)
                plantCount = Int.random(in: 18...30)
                propCount = Int.random(in: 1...2)
                treeScale = 0.8...1.4
                rockScale = 0.5...1.1
                plantScale = 0.8...1.5
            case "rocky_coast":
                treeCount = Int.random(in: 2...5)
                rockCount = Int.random(in: 8...14)
                plantCount = Int.random(in: 6...12)
                propCount = Int.random(in: 2...4)
                treeScale = 0.7...1.3
                rockScale = 0.8...1.6
                plantScale = 0.6...1.3
            case "mixed":
                treeCount = Int.random(in: 5...9)
                rockCount = Int.random(in: 4...8)
                plantCount = Int.random(in: 10...18)
                propCount = Int.random(in: 1...3)
                treeScale = 0.9...1.6
                rockScale = 0.6...1.4
                plantScale = 0.7...1.5
            case "coastal_pine":
                treeCount = Int.random(in: 4...8)
                rockCount = Int.random(in: 5...9)
                plantCount = Int.random(in: 8...15)
                propCount = Int.random(in: 1...3)
                treeScale = 0.8...1.5
                rockScale = 0.7...1.4
                plantScale = 0.7...1.4
            default:
                treeCount = 6
                rockCount = 4
                plantCount = 12
                propCount = 2
                treeScale = 1.0...1.5
                rockScale = 0.6...1.3
                plantScale = 0.8...1.4
            }
            
            // Trees in this biome
            for _ in 0..<treeCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue } // Avoid center
                spawnItem(models: treeModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: treeScale.lowerBound, sMax: treeScale.upperBound)
            }
            // Rocks
            for _ in 0..<rockCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue }
                spawnItem(models: rockModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: rockScale.lowerBound, sMax: rockScale.upperBound)
            }
            // Plants and flowers
            for _ in 0..<plantCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue }
                spawnItem(models: plantModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: plantScale.lowerBound, sMax: plantScale.upperBound)
            }
            // Props (logs, stumps)
            for _ in 0..<propCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue }
                spawnItem(models: propModels, folder: "nature", x: cx + ox, z: cz + oz, sMin: 0.7, sMax: 1.3)
            }
        }
        
        // Light global scatter for isolated elements - fewer, more intentional
        for _ in 0...15 {
            let x = Float.random(in: -16...16)
            let z = Float.random(in: -16...16)
            if hypot(x, z) < 5.0 || hypot(x, z) > TerrainBuilder.islandRadius - 1.2 { continue }
            spawnItem(models: treeModels, folder: "nature", x: x, z: z, sMin: 0.7, sMax: 1.4)
            spawnItem(models: rockModels, folder: "nature", x: x, z: z, sMin: 0.4, sMax: 1.0)
            spawnItem(models: plantModels, folder: "nature", x: x, z: z, sMin: 0.6, sMax: 1.2)
        }
        
        // Cozy campfire in the center
        let campfire = AssetManager.shared.getModel(named: "campfire_stones", folder: "nature")
        campfire.position = SCNVector3(0, TerrainBuilder.getHeight(at: 0, z: 0) + 0.05, 0)
        terrainWrapper.addChildNode(campfire)
        
        // Point light for the campfire (orange warm ambient light) - subtle
        let campLight = SCNLight()
        campLight.type = .omni
        campLight.color = UIColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 1.0)
        campLight.intensity = 25 // Subtle glow, not overpowering
        campLight.attenuationStartDistance = 0.3
        campLight.attenuationEndDistance = 2.5 // Small radius
        campLight.castsShadow = false
        
        let campLightNode = SCNNode()
        campLightNode.light = campLight
        campLightNode.position = SCNVector3(0, 0.25, 0)
        campfire.addChildNode(campLightNode)
        
        // Add a few fireflies/particles around the campfire for ambient life
        for _ in 0..<8 {
            let angle = Float.random(in: 0...(2 * Float.pi))
            let radius = Float.random(in: 0.8...2.0)
            let fx = sin(angle) * radius
            let fz = cos(angle) * radius
            let fy = TerrainBuilder.getHeight(at: fx, z: fz) + Float.random(in: 0.3...1.2)
            let firefly = SCNNode(geometry: SCNSphere(radius: 0.02))
            firefly.position = SCNVector3(fx, fy, fz)
            let ffMat = SCNMaterial()
            ffMat.lightingModel = .constant
            ffMat.emission.contents = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
            firefly.geometry?.materials = [ffMat]
            terrainWrapper.addChildNode(firefly)
            
            // Gentle floating animation
            let floatUp = SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: Double.random(in: 2.0...4.0))
            floatUp.timingMode = .easeInEaseOut
            let floatDown = floatUp.reversed()
            firefly.runAction(SCNAction.repeatForever(SCNAction.sequence([floatUp, floatDown])))
        }
    }
    
    private func setupOcean() {
        // Ocean floor - extends beyond island to horizon
        let floorGeo = SCNPlane(width: 200.0, height: 200.0)
        let floorMat = SCNMaterial()
        floorMat.lightingModel = .physicallyBased
        floorMat.diffuse.contents = UIColor(red: 0.08, green: 0.12, blue: 0.16, alpha: 1.0)
        floorMat.roughness.contents = NSNumber(value: 0.9)
        floorMat.metalness.contents = NSNumber(value: 0.0)
        floorMat.diffuse.magnificationFilter = .linear
        floorMat.diffuse.minificationFilter = .linear
        floorGeo.materials = [floorMat]
        
        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.position = SCNVector3(0, -5.0, 0)
        floorNode.eulerAngles.x = -Float.pi / 2
        terrainWrapper.addChildNode(floorNode)
        
        // Surface d'océan plane : elle évite le mur vertical d'un cylindre tout en
        // restant assez large pour couvrir l'horizon de la caméra.
        let waterGeo = SCNPlane(width: 130.0, height: 130.0)
        let waterMat = SCNMaterial()
        waterMat.lightingModel = .physicallyBased
        // Base water color - deeper blue-green for stylized look
        waterMat.diffuse.contents = UIColor(red: 0.05, green: 0.25, blue: 0.42, alpha: 1.0)
        waterMat.roughness.contents = NSNumber(value: 0.08) // Very smooth for nice reflections
        waterMat.metalness.contents = NSNumber(value: 0.95) // High metalness for water-like reflection
        waterMat.specular.contents = UIColor(white: 0.85, alpha: 1.0)
        // Semi-transparent to see underwater floor slightly, but mostly reflective
        waterMat.transparency = 0.75
        waterMat.transparencyMode = .aOne
        waterMat.writesToDepthBuffer = true
        waterMat.readsFromDepthBuffer = true
        waterMat.isDoubleSided = true // Allow viewing from below
        waterMat.diffuse.magnificationFilter = .linear
        waterMat.diffuse.minificationFilter = .linear
        waterGeo.materials = [waterMat]

        let waterNode = SCNNode(geometry: waterGeo)
        waterNode.name = "ocean"
        waterNode.position = SCNVector3(0, -0.25, 0) // Slightly higher for better shoreline
        waterNode.eulerAngles.x = -Float.pi / 2
        terrainWrapper.addChildNode(waterNode)
        
        // Légère onde / respiration aquatique naturelle
        let moveUp = SCNAction.moveBy(x: 0, y: 0.025, z: 0, duration: 3.5)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        waterNode.runAction(SCNAction.repeatForever(SCNAction.sequence([moveUp, moveDown])))
        
        // Subtle foam line at shoreline - thin ring at water level
        let foamGeo = SCNTorus(ringRadius: CGFloat(TerrainBuilder.islandRadius + 0.3), pipeRadius: 0.15)
        let foamMat = SCNMaterial()
        foamMat.lightingModel = .physicallyBased
        foamMat.diffuse.contents = UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 0.6)
        foamMat.roughness.contents = NSNumber(value: 0.9)
        foamMat.metalness.contents = NSNumber(value: 0.0)
        foamMat.transparency = 0.6
        foamMat.transparencyMode = .aOne
        foamMat.isDoubleSided = true
        foamGeo.materials = [foamMat]
        
        let foamNode = SCNNode(geometry: foamGeo)
        foamNode.position = SCNVector3(0, -0.25, 0)
        foamNode.eulerAngles.x = Float.pi / 2
        terrainWrapper.addChildNode(foamNode)
        
        // Gentle foam pulse
        let foamPulse = SCNAction.scale(to: 1.05, duration: 4.0)
        foamPulse.timingMode = .easeInEaseOut
        let foamPulseBack = SCNAction.scale(to: 0.95, duration: 4.0)
        foamPulseBack.timingMode = .easeInEaseOut
        foamNode.runAction(SCNAction.repeatForever(SCNAction.sequence([foamPulse, foamPulseBack])))
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
        var intensity: CGFloat = 420
        var ambientIntensity: CGFloat = 140
        var lightColor = UIColor.white
        var ambientColor = UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0)
        
        if time >= 6 && time <= 9 {
            // Matin doré et chaleureux - sunrise
            let t = CGFloat((time - 6) / 3)
            intensity = 280 + (140 * t)
            ambientIntensity = 100 + (40 * t)
            lightColor = UIColor(red: 1.0, green: 0.85 + 0.12*t, blue: 0.65 + 0.25*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0, green: 0.93 + 0.04*t, blue: 0.85 + 0.07*t, alpha: 1.0)
        } else if time > 9 && time <= 16 {
            // Jour lumineux et clair - midday
            intensity = 420
            ambientIntensity = 140
            lightColor = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
            ambientColor = UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0)
        } else if time > 16 && time <= 19 {
            // Soir / Crépuscule chaleureux - golden hour
            let t = CGFloat((time - 16) / 3)
            intensity = 420 - (220 * t)
            ambientIntensity = 140 - (40 * t)
            lightColor = UIColor(red: 1.0, green: 0.85 - 0.20*t, blue: 0.65 - 0.20*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0 - 0.05*t, green: 0.95 - 0.12*t, blue: 0.90 - 0.15*t, alpha: 1.0)
        } else {
            // Nuit douce, lisible et bleutée
            intensity = 60
            ambientIntensity = 80
            lightColor = UIColor(red: 0.4, green: 0.5, blue: 0.85, alpha: 1.0)
            ambientColor = UIColor(red: 0.2, green: 0.25, blue: 0.45, alpha: 1.0)
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
