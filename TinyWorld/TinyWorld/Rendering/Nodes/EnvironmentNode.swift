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
        dLight.shadowSampleCount = 16
        dLight.shadowRadius = 12.0 // Softer, more natural shadows
        dLight.shadowColor = UIColor.black.withAlphaComponent(0.18) // Natural shadow density
        dLight.orthographicScale = 50.0 // Couvre l'ensemble de l'île sans coupure d'ombre
        dLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        dLight.intensity = 450 // Slightly higher for better contrast
        directionalLightNode.light = dLight
        directionalLightNode.position = SCNVector3(0, 18, 0)
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi / 3.2, y: Float.pi / 4, z: 0)
        addChildNode(directionalLightNode)
        
        // Lumière ambiante chaleureuse - soft fill
        ambientLightNode = SCNNode()
        let aLight = SCNLight()
        aLight.type = .ambient
        aLight.intensity = 160
        aLight.color = UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1.0) // Warm cream
        ambientLightNode.light = aLight
        addChildNode(ambientLightNode)
        
        // Fill light (Lumière de débouchage opposée au soleil) - cool blue tint
        fillLightNode = SCNNode()
        let fLight = SCNLight()
        fLight.type = .directional
        fLight.intensity = 90
        fLight.castsShadow = false
        fLight.color = UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
        fillLightNode.light = fLight
        fillLightNode.eulerAngles = SCNVector3(x: Float.pi / 3.5, y: -Float.pi * 0.7, z: 0)
        addChildNode(fillLightNode)
        
        // Subtle rim light for edge definition
        let rimLightNode = SCNNode()
        let rLight = SCNLight()
        rLight.type = .directional
        rLight.intensity = 40
        rLight.castsShadow = false
        rLight.color = UIColor(red: 1.0, green: 0.94, blue: 0.82, alpha: 1.0)
        rimLightNode.light = rLight
        rimLightNode.eulerAngles = SCNVector3(x: Float.pi / 2.5, y: Float.pi, z: 0)
        addChildNode(rimLightNode)
        
        // Additional bounce light from below (subtle ground reflection)
        let bounceLightNode = SCNNode()
        let bLight = SCNLight()
        bLight.type = .directional
        bLight.intensity = 25
        bLight.castsShadow = false
        bLight.color = UIColor(red: 0.6, green: 0.7, blue: 0.55, alpha: 1.0) // Grass bounce
        bounceLightNode.light = bLight
        bounceLightNode.eulerAngles = SCNVector3(x: Float.pi / 1.8, y: 0, z: 0)
        addChildNode(bounceLightNode)
    }
    
    private func setupTerrain() {
        self.addChildNode(terrainWrapper)
        
        // Custom Hilly Terrain
        let terrain = TerrainBuilder.createTerrain(width: 40.0, depth: 40.0, subdivisions: 40)
        terrain.name = "ground"
        terrainWrapper.addChildNode(terrain)
        
        setupOcean()
        
        // Expanded model arrays using all available Kenney Nature Kit assets
        let treeModels = [
            "tree_oak", "tree_oak_dark", "tree_pineDefaultA", "tree_pineDefaultB",
            "tree_default", "tree_default_dark", "tree_fat", "tree_fat_darkh",
            "tree_pineRoundA", "tree_pineRoundB", "tree_pineRoundC", "tree_pineRoundD",
            "tree_cone", "tree_cone_dark", "tree_plateau", "tree_plateau_dark",
            "tree_thin", "tree_thin_dark", "tree_detailed", "tree_detailed_dark",
            "tree_pineTallA", "tree_pineTallB", "tree_pineTallC", "tree_pineTallD",
            "tree_tall", "tree_tall_dark", "tree_simple", "tree_simple_dark",
            "tree_palm", "tree_palmShort", "tree_palmTall", "tree_palmBend",
            "tree_pineSmallA", "tree_pineSmallB", "tree_pineSmallC", "tree_pineSmallD",
            "tree_pineGroundA", "tree_pineGroundB", "tree_small", "tree_small_dark"
        ]
        let rockModels = [
            "rock_largeA", "rock_largeB", "rock_largeC", "rock_largeD", "rock_largeE", "rock_largeF",
            "rock_tallA", "rock_tallB", "rock_tallC", "rock_tallD", "rock_tallE", "rock_tallF",
            "rock_tallG", "rock_tallH", "rock_tallI", "rock_tallJ",
            "rock_smallA", "rock_smallB", "rock_smallC", "rock_smallD", "rock_smallE", "rock_smallF",
            "rock_smallG", "rock_smallH", "rock_smallI",
            "rock_smallFlatA", "rock_smallFlatB", "rock_smallFlatC",
            "rock_smallTopA", "rock_smallTopB",
            "stone_largeA", "stone_largeB", "stone_largeC", "stone_largeD", "stone_largeE", "stone_largeF",
            "stone_smallA", "stone_smallB", "stone_smallC", "stone_smallD", "stone_smallE", "stone_smallF",
            "stone_smallFlatA", "stone_smallFlatB", "stone_smallFlatC",
            "stone_smallTopA", "stone_smallTopB",
            "stone_tallA", "stone_tallB", "stone_tallC", "stone_tallD", "stone_tallE", "stone_tallF",
            "stone_tallG", "stone_tallH", "stone_tallI", "stone_tallJ"
        ]
        let plantModels = [
            "plant_bushDetailed", "plant_bushLarge", "plant_bushSmall", "plant_bushTriangle",
            "plant_bushLargeTriangle", "plant_flatShort", "plant_flatTall",
            "flower_purpleA", "flower_purpleB", "flower_purpleC",
            "flower_redA", "flower_redB", "flower_redC",
            "flower_yellowA", "flower_yellowB", "flower_yellowC",
            "mushroom_red", "mushroom_redGroup", "mushroom_redTall",
            "mushroom_tan", "mushroom_tanGroup", "mushroom_tanTall",
            "grass_leafs", "grass_leafsLarge", "grass", "grass_large",
            "lily_large", "lily_small", "hanging_moss",
            "plant_bush", "plant_bushDetailed", "plant_bushLarge"
        ]
        let propModels = [
            "log", "log_large", "log_stack", "log_stackLarge",
            "stump_old", "stump_oldTall", "stump_round", "stump_roundDetailed",
            "stump_square", "stump_squareDetailed", "stump_squareDetailedWide",
            "sign", "statue_block", "statue_column", "statue_columnDamaged",
            "statue_head", "statue_obelisk", "statue_ring",
            "pot_small", "pot_large", "bridge_center_wood", "bridge_center_woodRound",
            "bridge_center_stone", "bridge_center_stoneRound",
            "bridge_side_wood", "bridge_side_woodRound",
            "bridge_side_stone", "bridge_side_stoneRound"
        ]
        
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
        // Zone 1: Northwest - dense forest (oak, detailed trees, bushes)
        // Zone 2: Northeast - rocky hills with pines (pine variants, tall pines, rocks)
        // Zone 3: South - open meadow with scattered trees (simple trees, flowers, grass)
        // Zone 4: East - flowering slopes (flowering plants, meadow trees, small rocks)
        // Zone 5: West - rocky coast (large rocks, coastal pines, hardy plants)
        // Zone 6: Southwest - mixed forest/rocks
        // Zone 7: Southeast - coastal pines with palms
        
        // Biome-specific model subsets for intentional variety
        let forestTrees = ["tree_oak", "tree_oak_dark", "tree_detailed", "tree_detailed_dark", "tree_default", "tree_default_dark", "tree_fat", "tree_fat_darkh"]
        let forestRocks = ["stone_largeA", "stone_largeB", "stone_largeC", "stone_smallA", "stone_smallB", "stone_smallC", "rock_smallA", "rock_smallB"]
        let forestPlants = ["plant_bushDetailed", "plant_bushLarge", "plant_bushTriangle", "mushroom_red", "mushroom_tan", "grass_leafs", "grass_leafsLarge", "hanging_moss"]
        let forestProps = ["log", "log_large", "stump_old", "stump_roundDetailed", "stump_squareDetailed"]
        
        let pineHillsTrees = ["tree_pineDefaultA", "tree_pineDefaultB", "tree_pineRoundA", "tree_pineRoundB", "tree_pineRoundC", "tree_pineRoundD", "tree_pineTallA", "tree_pineTallB", "tree_pineTallC", "tree_pineTallD", "tree_cone", "tree_cone_dark", "tree_plateau", "tree_plateau_dark"]
        let pineHillsRocks = ["rock_largeA", "rock_largeB", "rock_largeC", "rock_largeD", "rock_largeE", "rock_tallA", "rock_tallB", "rock_tallC", "rock_tallD", "stone_largeD", "stone_largeE", "stone_largeF"]
        let pineHillsPlants = ["plant_bushSmall", "plant_bushTriangle", "plant_flatShort", "plant_flatTall", "mushroom_red", "mushroom_tan", "grass", "grass_large"]
        let pineHillsProps = ["log", "log_large", "log_stack", "stump_oldTall", "stump_round", "rock_smallFlatA", "rock_smallFlatB"]
        
        let meadowTrees = ["tree_simple", "tree_simple_dark", "tree_small", "tree_small_dark", "tree_default", "tree_fat"]
        let meadowRocks = ["stone_smallA", "stone_smallB", "stone_smallC", "stone_smallD", "rock_smallA", "rock_smallB", "rock_smallC", "rock_smallFlatA"]
        let meadowPlants = ["flower_purpleA", "flower_purpleB", "flower_purpleC", "flower_redA", "flower_redB", "flower_redC", "flower_yellowA", "flower_yellowB", "flower_yellowC", "grass_leafs", "grass_leafsLarge", "grass", "grass_large", "plant_bushSmall", "plant_bush"]
        let meadowProps = ["stump_round", "stump_square", "sign"]
        
        let floweringTrees = ["tree_default", "tree_default_dark", "tree_fat", "tree_fat_darkh", "tree_small", "tree_simple"]
        let floweringRocks = ["stone_smallA", "stone_smallB", "stone_smallC", "rock_smallA", "rock_smallB", "rock_smallC"]
        let floweringPlants = ["flower_purpleA", "flower_purpleB", "flower_purpleC", "flower_redA", "flower_redB", "flower_redC", "flower_yellowA", "flower_yellowB", "flower_yellowC", "plant_bushDetailed", "plant_bushLarge", "plant_bushTriangle", "plant_bushLargeTriangle", "grass_leafs", "lily_large", "lily_small"]
        let floweringProps = ["stump_roundDetailed", "pot_small", "pot_large"]
        
        let rockyCoastTrees = ["tree_pineTallA", "tree_pineTallB", "tree_pineTallC", "tree_pineTallD", "tree_pineGroundA", "tree_pineGroundB", "tree_cone", "tree_pineRoundA", "tree_pineRoundB"]
        let rockyCoastRocks = ["rock_largeA", "rock_largeB", "rock_largeC", "rock_largeD", "rock_largeE", "rock_largeF", "rock_tallA", "rock_tallB", "rock_tallC", "rock_tallD", "rock_tallE", "rock_tallF", "rock_tallG", "rock_tallH", "rock_tallI", "rock_tallJ", "stone_largeA", "stone_largeB", "stone_largeC", "stone_largeD", "stone_largeE", "stone_largeF"]
        let rockyCoastPlants = ["plant_flatShort", "plant_flatTall", "plant_bushSmall", "plant_bush", "grass", "grass_large", "mushroom_tan", "mushroom_tanTall"]
        let rockyCoastProps = ["log", "log_large", "log_stack", "log_stackLarge", "stump_old", "stump_oldTall", "rock_smallFlatA", "rock_smallFlatB", "rock_smallFlatC", "rock_smallTopA", "rock_smallTopB"]
        
        let mixedTrees = ["tree_oak", "tree_default", "tree_pineDefaultA", "tree_fat", "tree_plateau", "tree_thin", "tree_simple"]
        let mixedRocks = ["rock_largeA", "rock_largeB", "rock_largeC", "stone_largeA", "stone_largeB", "stone_largeC", "rock_smallA", "rock_smallB", "rock_smallC", "rock_smallD"]
        let mixedPlants = ["plant_bushDetailed", "plant_bushLarge", "plant_bushSmall", "plant_bushTriangle", "flower_purpleA", "flower_yellowA", "mushroom_red", "mushroom_tan", "grass_leafs", "grass"]
        let mixedProps = ["log", "stump_old", "stump_round", "stump_square", "statue_block"]
        
        let coastalPineTrees = ["tree_pineTallA", "tree_pineTallB", "tree_pineTallC", "tree_pineTallD", "tree_palm", "tree_palmShort", "tree_palmTall", "tree_palmBend", "tree_pineRoundA", "tree_pineRoundB", "tree_pineRoundC"]
        let coastalPineRocks = ["rock_largeA", "rock_largeB", "rock_largeC", "rock_tallA", "rock_tallB", "rock_tallC", "stone_largeD", "stone_largeE", "stone_largeF", "rock_smallA", "rock_smallB", "rock_smallC"]
        let coastalPinePlants = ["plant_bushSmall", "plant_bush", "plant_flatShort", "grass", "grass_large", "lily_large", "lily_small", "mushroom_tan"]
        let coastalPineProps = ["log", "log_large", "stump_old", "stump_round", "bridge_center_wood", "bridge_center_stone"]
        
        let biomeCenters: [(Float, Float, String, [String], [String], [String], [String])] = [
            (-9.0, -8.0, "forest", forestTrees, forestRocks, forestPlants, forestProps),
            (8.0, -7.0, "pine_hills", pineHillsTrees, pineHillsRocks, pineHillsPlants, pineHillsProps),
            (0.0, 10.0, "meadow", meadowTrees, meadowRocks, meadowPlants, meadowProps),
            (-6.0, 9.0, "flowering", floweringTrees, floweringRocks, floweringPlants, floweringProps),
            (11.0, 4.0, "rocky_coast", rockyCoastTrees, rockyCoastRocks, rockyCoastPlants, rockyCoastProps),
            (-3.0, -11.0, "mixed", mixedTrees, mixedRocks, mixedPlants, mixedProps),
            (5.0, -10.0, "coastal_pine", coastalPineTrees, coastalPineRocks, coastalPinePlants, coastalPineProps),
        ]
        
        for (cx, cz, biome, bTrees, bRocks, bPlants, bProps) in biomeCenters {
            let radius: Float = Float.random(in: 4.5...7.0)
            let treeCount, rockCount, plantCount, propCount: Int
            let treeScale: ClosedRange<Float>
            let rockScale: ClosedRange<Float>
            let plantScale: ClosedRange<Float>
            
            switch biome {
            case "forest":
                treeCount = Int.random(in: 10...16)
                rockCount = Int.random(in: 4...8)
                plantCount = Int.random(in: 15...25)
                propCount = Int.random(in: 3...5)
                treeScale = 1.1...2.0
                rockScale = 0.7...1.5
                plantScale = 0.9...1.7
            case "pine_hills":
                treeCount = Int.random(in: 8...14)
                rockCount = Int.random(in: 8...14)
                plantCount = Int.random(in: 10...18)
                propCount = Int.random(in: 2...4)
                treeScale = 1.2...2.1
                rockScale = 0.8...1.7
                plantScale = 0.8...1.5
            case "meadow":
                treeCount = Int.random(in: 4...8)
                rockCount = Int.random(in: 3...7)
                plantCount = Int.random(in: 20...35)
                propCount = Int.random(in: 0...3)
                treeScale = 1.0...1.7
                rockScale = 0.5...1.3
                plantScale = 1.0...1.8
            case "flowering":
                treeCount = Int.random(in: 5...10)
                rockCount = Int.random(in: 3...6)
                plantCount = Int.random(in: 25...40)
                propCount = Int.random(in: 1...3)
                treeScale = 0.9...1.6
                rockScale = 0.5...1.2
                plantScale = 0.9...1.6
            case "rocky_coast":
                treeCount = Int.random(in: 3...7)
                rockCount = Int.random(in: 12...20)
                plantCount = Int.random(in: 10...18)
                propCount = Int.random(in: 3...6)
                treeScale = 0.8...1.5
                rockScale = 0.9...1.8
                plantScale = 0.7...1.4
            case "mixed":
                treeCount = Int.random(in: 6...12)
                rockCount = Int.random(in: 5...10)
                plantCount = Int.random(in: 15...25)
                propCount = Int.random(in: 2...4)
                treeScale = 1.0...1.8
                rockScale = 0.7...1.5
                plantScale = 0.8...1.6
            case "coastal_pine":
                treeCount = Int.random(in: 5...10)
                rockCount = Int.random(in: 6...12)
                plantCount = Int.random(in: 12...20)
                propCount = Int.random(in: 1...3)
                treeScale = 0.9...1.7
                rockScale = 0.7...1.5
                plantScale = 0.8...1.5
            default:
                treeCount = 8
                rockCount = 5
                plantCount = 15
                propCount = 2
                treeScale = 1.0...1.6
                rockScale = 0.6...1.4
                plantScale = 0.8...1.5
            }
            
            // Trees in this biome
            for _ in 0..<treeCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue } // Avoid center
                spawnItem(models: bTrees, folder: "nature", x: cx + ox, z: cz + oz, sMin: treeScale.lowerBound, sMax: treeScale.upperBound)
            }
            // Rocks
            for _ in 0..<rockCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue }
                spawnItem(models: bRocks, folder: "nature", x: cx + ox, z: cz + oz, sMin: rockScale.lowerBound, sMax: rockScale.upperBound)
            }
            // Plants and flowers
            for _ in 0..<plantCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue }
                spawnItem(models: bPlants, folder: "nature", x: cx + ox, z: cz + oz, sMin: plantScale.lowerBound, sMax: plantScale.upperBound)
            }
            // Props (logs, stumps, statues)
            for _ in 0..<propCount {
                let ox = Float.random(in: -radius...radius)
                let oz = Float.random(in: -radius...radius)
                if hypot(cx + ox, cz + oz) < 5.0 { continue }
                spawnItem(models: bProps, folder: "nature", x: cx + ox, z: cz + oz, sMin: 0.7, sMax: 1.3)
            }
        }
        
        // Light global scatter for isolated elements - fewer, more intentional
        for _ in 0...12 {
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
        floorMat.diffuse.contents = UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1.0)
        floorMat.roughness.contents = NSNumber(value: 0.95)
        floorMat.metalness.contents = NSNumber(value: 0.0)
        floorMat.diffuse.magnificationFilter = .linear
        floorMat.diffuse.minificationFilter = .linear
        floorGeo.materials = [floorMat]
        
        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.position = SCNVector3(0, -5.0, 0)
        floorNode.eulerAngles.x = -Float.pi / 2
        terrainWrapper.addChildNode(floorNode)
        
        // Water surface - stylized PBR water with proper color
        let waterGeo = SCNPlane(width: 140.0, height: 140.0)
        let waterMat = SCNMaterial()
        waterMat.lightingModel = .physicallyBased
        // Base water color - stylized blue-green, not brown
        waterMat.diffuse.contents = UIColor(red: 0.08, green: 0.35, blue: 0.55, alpha: 1.0)
        waterMat.roughness.contents = NSNumber(value: 0.12) // Smooth but not mirror
        waterMat.metalness.contents = NSNumber(value: 0.3) // Lower metalness to avoid brown reflections
        waterMat.specular.contents = UIColor(white: 0.6, alpha: 1.0)
        // Subtle normal map for water surface detail would be ideal, but using geometry for now
        waterMat.transparency = 0.65
        waterMat.transparencyMode = .aOne
        waterMat.writesToDepthBuffer = true
        waterMat.readsFromDepthBuffer = true
        waterMat.isDoubleSided = true
        waterMat.diffuse.magnificationFilter = .linear
        waterMat.diffuse.minificationFilter = .linear
        waterGeo.materials = [waterMat]
        
        let waterNode = SCNNode(geometry: waterGeo)
        waterNode.name = "ocean"
        waterNode.position = SCNVector3(0, -0.2, 0) // Slightly higher for cleaner shoreline
        waterNode.eulerAngles.x = -Float.pi / 2
        terrainWrapper.addChildNode(waterNode)
        
        // Gentle breathing animation
        let moveUp = SCNAction.moveBy(x: 0, y: 0.02, z: 0, duration: 4.0)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        waterNode.runAction(SCNAction.repeatForever(SCNAction.sequence([moveUp, moveDown])))
        
        // Shoreline foam ring - more natural, less geometric
        let foamGeo = SCNTorus(ringRadius: CGFloat(TerrainBuilder.islandRadius + 0.4), pipeRadius: 0.12)
        let foamMat = SCNMaterial()
        foamMat.lightingModel = .physicallyBased
        foamMat.diffuse.contents = UIColor(red: 0.98, green: 0.98, blue: 0.92, alpha: 0.55)
        foamMat.roughness.contents = NSNumber(value: 0.85)
        foamMat.metalness.contents = NSNumber(value: 0.0)
        foamMat.transparency = 0.55
        foamMat.transparencyMode = .aOne
        foamMat.isDoubleSided = true
        foamGeo.materials = [foamMat]
        
        let foamNode = SCNNode(geometry: foamGeo)
        foamNode.position = SCNVector3(0, -0.18, 0)
        foamNode.eulerAngles.x = Float.pi / 2
        terrainWrapper.addChildNode(foamNode)
        
        // Gentle foam pulse
        let foamPulse = SCNAction.scale(to: 1.03, duration: 5.0)
        foamPulse.timingMode = .easeInEaseOut
        let foamPulseBack = SCNAction.scale(to: 0.97, duration: 5.0)
        foamPulseBack.timingMode = .easeInEaseOut
        foamNode.runAction(SCNAction.repeatForever(SCNAction.sequence([foamPulse, foamPulseBack])))
        
        // Secondary inner foam for wave break effect
        let innerFoamGeo = SCNTorus(ringRadius: CGFloat(TerrainBuilder.islandRadius - 0.8), pipeRadius: 0.06)
        let innerFoamMat = SCNMaterial()
        innerFoamMat.lightingModel = .physicallyBased
        innerFoamMat.diffuse.contents = UIColor(red: 0.95, green: 0.95, blue: 0.88, alpha: 0.35)
        innerFoamMat.roughness.contents = NSNumber(value: 0.9)
        innerFoamMat.metalness.contents = NSNumber(value: 0.0)
        innerFoamMat.transparency = 0.35
        innerFoamMat.transparencyMode = .aOne
        innerFoamMat.isDoubleSided = true
        innerFoamGeo.materials = [innerFoamMat]
        
        let innerFoamNode = SCNNode(geometry: innerFoamGeo)
        innerFoamNode.position = SCNVector3(0, -0.15, 0)
        innerFoamNode.eulerAngles.x = Float.pi / 2
        terrainWrapper.addChildNode(innerFoamNode)
        
        let innerFoamPulse = SCNAction.scale(to: 1.05, duration: 3.5)
        innerFoamPulse.timingMode = .easeInEaseOut
        let innerFoamPulseBack = SCNAction.scale(to: 0.95, duration: 3.5)
        innerFoamPulseBack.timingMode = .easeInEaseOut
        innerFoamNode.runAction(SCNAction.repeatForever(SCNAction.sequence([innerFoamPulse, innerFoamPulseBack])))
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
        
        // Plot boundary with varied fencing
        if zone.type == .home || zone.type == .farm {
            let r = Float(zone.radius) - 0.2
            let fenceSteps = Int(r * 2.0 / 0.8)
            if fenceSteps > 1 {
                let fenceModels = ["fence", "fence-1x2", "fence-1x3", "fence-low"]
                for i in 0...fenceSteps {
                    let offset = -r + (Float(i) / Float(fenceSteps)) * (r * 2.0)
                    let fenceModel = fenceModels.randomElement()!
                    
                    // Front and Back
                    let fenceF = AssetManager.shared.getModel(named: fenceModel, folder: "suburban")
                    fenceF.position = SCNVector3(offset, 0.08, r)
                    wrapper.addChildNode(fenceF)
                    
                    if i != fenceSteps / 2 { // leave a gap in the back
                        let fenceB = AssetManager.shared.getModel(named: fenceModel, folder: "suburban")
                        fenceB.position = SCNVector3(offset, 0.08, -r)
                        wrapper.addChildNode(fenceB)
                    }
                    
                    // Left and Right
                    let fenceL = AssetManager.shared.getModel(named: fenceModel, folder: "suburban")
                    fenceL.position = SCNVector3(-r, 0.08, offset)
                    fenceL.eulerAngles.y = Float.pi / 2
                    wrapper.addChildNode(fenceL)
                    
                    let fenceR = AssetManager.shared.getModel(named: fenceModel, folder: "suburban")
                    fenceR.position = SCNVector3(r, 0.08, offset)
                    fenceR.eulerAngles.y = Float.pi / 2
                    wrapper.addChildNode(fenceR)
                }
            }
        }
        
        var building: SCNNode?
        
        // Use zone ID and type for deterministic but varied building selection
        let typeHash = zone.type == .home ? 0 : zone.type == .work ? 1 : zone.type == .food ? 2 : zone.type == .farm ? 3 : zone.type == .forest ? 4 : 5
        let variantSeed = zone.id * 1000 + typeHash * 100
        
        switch zone.type {
        case .home:
            // Mix of cottages and family homes
            let houseType: BuildingBuilder.HouseType = (zone.id % 3 == 0) ? .familyHome : .cottage
            building = BuildingBuilder.shared.buildSpecificHouse(type: houseType, variant: variantSeed)
        case .work:
            building = BuildingBuilder.shared.buildFactory()
        case .food:
            building = BuildingBuilder.shared.buildShop()
        case .farm:
            building = BuildingBuilder.shared.buildFarm()
        case .forest:
            for _ in 0..<7 {
                let tree = BuildingBuilder.shared.buildTree(tall: true)
                tree.position = SCNVector3(
                    Float.random(in: -zone.radius/1.5...zone.radius/1.5),
                    0.05,
                    Float.random(in: -zone.radius/1.5...zone.radius/1.5)
                )
                tree.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
                wrapper.addChildNode(tree)
            }
            // Add some understory plants
            for _ in 0..<5 {
                let plant = AssetManager.shared.getModel(named: ["plant_bushSmall", "plant_bush", "plant_flatShort", "grass", "grass_large"].randomElement()!, folder: "nature")
                plant.position = SCNVector3(
                    Float.random(in: -zone.radius/1.5...zone.radius/1.5),
                    0.02,
                    Float.random(in: -zone.radius/1.5...zone.radius/1.5)
                )
                plant.scale = SCNVector3(Float.random(in: 0.7...1.2), Float.random(in: 0.7...1.2), Float.random(in: 0.7...1.2))
                plant.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
                wrapper.addChildNode(plant)
            }
        default:
            building = BuildingBuilder.shared.buildSpecificHouse(type: .cottage, variant: variantSeed)
        }
        
        if let b = building {
            b.position.y = 0.05 // Foundation handles the height
            wrapper.addChildNode(b)
        }
        
        // Create meandering path to village center with varied stone types
        let start = SCNVector3(zone.centerX, py + 0.05, zone.centerZ)
        let end = SCNVector3(0, TerrainBuilder.getHeight(at: 0, z: 0) + 0.05, 0)
        let dx = end.x - start.x
        let dz = end.z - start.z
        let distance = hypot(Float(dx), Float(dz))
        let steps = Int(distance / 1.3) // Slightly denser path stones
        
        let pathModels = ["path-stones-short", "path-stones-long", "path-stones-messy", "path-short"]
        
        if steps > 1 {
            for i in 1..<steps {
                let ratio = Float(i) / Float(steps)
                let meander = sin(ratio * Float.pi * 3.0) * 0.5
                let segmentLength = max(distance, 0.001)
                let perpX = -dz / segmentLength
                let perpZ = dx / segmentLength
                let px = start.x + Float(dx) * ratio + meander * perpX
                let pz = start.z + Float(dz) * ratio + meander * perpZ
                let pathModel = pathModels.randomElement()!
                let pathStone = AssetManager.shared.getModel(named: pathModel, folder: "suburban")
                pathStone.position = SCNVector3(px, TerrainBuilder.getHeight(at: px, z: pz) + 0.02, pz)
                pathStone.eulerAngles.y = Float.random(in: 0...Float.pi)
                // Add slight scale variation
                let pathScale = Float.random(in: 0.9...1.1)
                pathStone.scale = SCNVector3(pathScale, pathScale, pathScale)
                self.addChildNode(pathStone)
            }
        }
        
        // Add a small entrance feature (planter or decorative element)
        if zone.type == .home || zone.type == .food {
            let entrancePlanter = AssetManager.shared.getModel(named: "planter", folder: "suburban")
            let entranceOffset: Float = 1.8
            let angleToCenter = atan2(-zone.centerX, -zone.centerZ)
            entrancePlanter.position = SCNVector3(
                sin(angleToCenter) * entranceOffset,
                0.05,
                cos(angleToCenter) * entranceOffset
            )
            entrancePlanter.eulerAngles.y = angleToCenter + Float.pi
            wrapper.addChildNode(entrancePlanter)
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
        var intensity: CGFloat = 450
        var ambientIntensity: CGFloat = 160
        var fillIntensity: CGFloat = 90
        var rimIntensity: CGFloat = 40
        var bounceIntensity: CGFloat = 25
        var lightColor = UIColor.white
        var ambientColor = UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1.0)
        var fillColor = UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
        var rimColor = UIColor(red: 1.0, green: 0.94, blue: 0.82, alpha: 1.0)
        
        if time >= 5 && time <= 8 {
            // Pre-dawn to sunrise - deep blue to warm gold
            let t = CGFloat((time - 5) / 3)
            intensity = 80 + (370 * t)
            ambientIntensity = 60 + (100 * t)
            fillIntensity = 40 + (50 * t)
            rimIntensity = 10 + (30 * t)
            bounceIntensity = 5 + (20 * t)
            lightColor = UIColor(red: 0.3 + 0.7*t, green: 0.35 + 0.6*t, blue: 0.65 + 0.3*t, alpha: 1.0)
            ambientColor = UIColor(red: 0.15 + 0.85*t, green: 0.18 + 0.78*t, blue: 0.35 + 0.55*t, alpha: 1.0)
            fillColor = UIColor(red: 0.5 + 0.3*t, green: 0.55 + 0.31*t, blue: 0.9, alpha: 1.0)
            rimColor = UIColor(red: 0.6 + 0.4*t, green: 0.5 + 0.44*t, blue: 0.4 + 0.42*t, alpha: 1.0)
        } else if time > 8 && time <= 10 {
            // Morning golden hour
            let t = CGFloat((time - 8) / 2)
            intensity = 450
            ambientIntensity = 160
            fillIntensity = 90
            rimIntensity = 40 + (10 * t)
            bounceIntensity = 25 + (10 * t)
            lightColor = UIColor(red: 1.0, green: 0.95 - 0.05*t, blue: 0.85 - 0.1*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0, green: 0.96, blue: 0.90 - 0.05*t, alpha: 1.0)
            fillColor = UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
            rimColor = UIColor(red: 1.0, green: 0.94, blue: 0.82 + 0.05*t, alpha: 1.0)
        } else if time > 10 && time <= 15 {
            // Midday - bright, clear, slightly warm
            intensity = 450
            ambientIntensity = 160
            fillIntensity = 90
            rimIntensity = 50
            bounceIntensity = 35
            lightColor = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
            ambientColor = UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1.0)
            fillColor = UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
            rimColor = UIColor(red: 1.0, green: 0.94, blue: 0.87, alpha: 1.0)
        } else if time > 15 && time <= 17 {
            // Late afternoon - warming up
            let t = CGFloat((time - 15) / 2)
            intensity = 450
            ambientIntensity = 160
            fillIntensity = 90 - (15 * t)
            rimIntensity = 50 + (15 * t)
            bounceIntensity = 35 + (10 * t)
            lightColor = UIColor(red: 1.0, green: 0.98 - 0.08*t, blue: 0.95 - 0.2*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0, green: 0.96 - 0.04*t, blue: 0.90 - 0.1*t, alpha: 1.0)
            fillColor = UIColor(red: 0.80 - 0.1*t, green: 0.86 - 0.1*t, blue: 1.0 - 0.1*t, alpha: 1.0)
            rimColor = UIColor(red: 1.0, green: 0.94 - 0.1*t, blue: 0.87 + 0.05*t, alpha: 1.0)
        } else if time > 17 && time <= 19.5 {
            // Golden hour to sunset
            let t = CGFloat((time - 17) / 2.5)
            intensity = 450 - (320 * t)
            ambientIntensity = 160 - (60 * t)
            fillIntensity = 75 - (40 * t)
            rimIntensity = 65
            bounceIntensity = 45
            lightColor = UIColor(red: 1.0, green: 0.90 - 0.4*t, blue: 0.75 - 0.45*t, alpha: 1.0)
            ambientColor = UIColor(red: 1.0 - 0.05*t, green: 0.92 - 0.5*t, blue: 0.80 - 0.45*t, alpha: 1.0)
            fillColor = UIColor(red: 0.7, green: 0.76, blue: 0.9, alpha: 1.0)
            rimColor = UIColor(red: 1.0, green: 0.84 + 0.1*t, blue: 0.92 - 0.05*t, alpha: 1.0)
        } else if time > 19.5 && time <= 21.5 {
            // Twilight to night
            let t = CGFloat((time - 19.5) / 2)
            intensity = 130 - (110 * t)
            ambientIntensity = 100 - (30 * t)
            fillIntensity = 35 - (25 * t)
            rimIntensity = 65 - (55 * t)
            bounceIntensity = 45 - (40 * t)
            lightColor = UIColor(red: 1.0 - 0.6*t, green: 0.74 - 0.54*t, blue: 0.55 - 0.3*t, alpha: 1.0)
            ambientColor = UIColor(red: 0.95 - 0.75*t, green: 0.65 - 0.5*t, blue: 0.60 - 0.4*t, alpha: 1.0)
            fillColor = UIColor(red: 0.7, green: 0.76, blue: 0.9, alpha: 1.0)
            rimColor = UIColor(red: 1.0, green: 0.94, blue: 0.87, alpha: 1.0)
        } else {
            // Night (21.5-24 and 0-5)
            intensity = 20
            ambientIntensity = 70
            fillIntensity = 10
            rimIntensity = 10
            bounceIntensity = 5
            lightColor = UIColor(red: 0.35, green: 0.42, blue: 0.7, alpha: 1.0)
            ambientColor = UIColor(red: 0.18, green: 0.22, blue: 0.4, alpha: 1.0)
            fillColor = UIColor(red: 0.5, green: 0.55, blue: 0.8, alpha: 1.0)
            rimColor = UIColor(red: 0.5, green: 0.55, blue: 0.75, alpha: 1.0)
        }
        
        directionalLightNode.light?.intensity = intensity
        directionalLightNode.light?.color = lightColor
        ambientLightNode.light?.intensity = ambientIntensity
        ambientLightNode.light?.color = ambientColor
        fillLightNode.light?.intensity = fillIntensity
        fillLightNode.light?.color = fillColor
        if let rimLight = self.childNodes.first(where: { $0.light?.color == rimColor || $0.light?.intensity == 40 }) {
            rimLight.light?.intensity = rimIntensity
            rimLight.light?.color = rimColor
        }
        if let bounceLight = self.childNodes.first(where: { $0.light?.color == UIColor(red: 0.6, green: 0.7, blue: 0.55, alpha: 1.0) }) {
            bounceLight.light?.intensity = bounceIntensity
        }
        
        if time >= 5 && time <= 21.5 {
            let dayProgress: Float
            if time <= 13.0 {
                dayProgress = (time - 5) / 8.0 // 5-13
            } else {
                dayProgress = 1.0 - (time - 13) / 8.5 // 13-21.5
            }
            // Natural solar arc (28° to 62° elevation)
            let elevation = Float.pi / 6.5 + sin(dayProgress * Float.pi) * (Float.pi / 2.6)
            let azimuth = Float.pi / 4.0 + (dayProgress - 0.5) * (Float.pi / 2.5)
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
