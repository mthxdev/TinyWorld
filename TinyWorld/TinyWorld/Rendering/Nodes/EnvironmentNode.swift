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
        dLight.shadowRadius = 4.0
        dLight.shadowColor = UIColor.black.withAlphaComponent(0.45)
        dLight.orthographicScale = 25.0 // Concentré sur le village
        dLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        dLight.intensity = 1000
        directionalLightNode.light = dLight
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi / 3, y: Float.pi / 4, z: 0)
        addChildNode(directionalLightNode)
        
        // Lumière ambiante
        ambientLightNode = SCNNode()
        let aLight = SCNLight()
        aLight.type = .ambient
        aLight.intensity = 300
        aLight.color = UIColor(white: 0.9, alpha: 1.0)
        ambientLightNode.light = aLight
        addChildNode(ambientLightNode)
        
        // Fill light (Lumière de débouchage opposée au soleil, sans ombre)
        fillLightNode = SCNNode()
        let fLight = SCNLight()
        fLight.type = .directional
        fLight.intensity = 300
        fLight.castsShadow = false
        fLight.color = UIColor(red: 0.8, green: 0.85, blue: 1.0, alpha: 1.0) // Teinte bleutée
        fillLightNode.light = fLight
        fillLightNode.eulerAngles = SCNVector3(x: Float.pi / 4, y: -Float.pi * 0.75, z: 0)
        addChildNode(fillLightNode)
    }
    
    private func setupTerrain() {
        self.addChildNode(terrainWrapper)
        
        // Sol de base stylise avec bruit (les textures procedurables ont ete supprimees, utilisons une couleur unie vibrante)
        let groundGeo = SCNBox(width: 30, height: 1.0, length: 30, chamferRadius: 0.5)
        let groundMat = SCNMaterial()
        groundMat.diffuse.contents = UIColor(red: 0.35, green: 0.65, blue: 0.25, alpha: 1.0)
        groundGeo.firstMaterial = groundMat
        let ground = SCNNode(geometry: groundGeo)
        ground.position = SCNVector3(0, -0.5, 0)
        ground.name = "ground"
        ground.castsShadow = false
        terrainWrapper.addChildNode(ground)
        
        // Ajouter du vrai decor Kenney Nature Kit
        for _ in 0...15 {
            let tree = AssetManager.shared.getModel(named: "tree_oak", folder: "nature")
            let x = Float.random(in: -14...14)
            let z = Float.random(in: -14...14)
            // Eviter le centre
            if abs(x) < 4 && abs(z) < 4 { continue }
            tree.position = SCNVector3(x, 0, z)
            tree.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            tree.scale = SCNVector3(1.5, 1.5, 1.5)
            terrainWrapper.addChildNode(tree)
        }
        
        for _ in 0...10 {
            let rock = AssetManager.shared.getModel(named: "rock", folder: "nature")
            let x = Float.random(in: -12...12)
            let z = Float.random(in: -12...12)
            if abs(x) < 4 && abs(z) < 4 { continue }
            rock.position = SCNVector3(x, 0, z)
            rock.eulerAngles.y = Float.random(in: 0...(2 * Float.pi))
            terrainWrapper.addChildNode(rock)
        }
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
        wrapper.position = SCNVector3(zone.centerX, 0, zone.centerZ)
        
        // Base de la parcelle
        let plotGeo = SCNBox(width: CGFloat(zone.radius * 2.0), height: 0.1, length: CGFloat(zone.radius * 2.0), chamferRadius: 0.2)
        plotGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.7, green: 0.65, blue: 0.5, alpha: 1.0)
        let plot = SCNNode(geometry: plotGeo)
        plot.position.y = 0.05
        wrapper.addChildNode(plot)
        
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
        let start = SCNVector3(zone.centerX, 0.05, zone.centerZ)
        let end = SCNVector3(0, 0.05, 0)
        let dx = end.x - start.x
        let dz = end.z - start.z
        let distance = hypot(Float(dx), Float(dz))
        let steps = Int(distance / 1.5)
        
        if steps > 1 {
            for i in 1..<steps {
                let ratio = Float(i) / Float(steps)
                let pathStone = AssetManager.shared.getModel(named: "path-stones-short", folder: "suburban")
                pathStone.position = SCNVector3(start.x + Float(dx) * ratio, 0.06, start.z + Float(dz) * ratio)
                pathStone.eulerAngles.y = Float.random(in: 0...Float.pi)
                wrapper.addChildNode(pathStone)
            }
        }
        
        return wrapper
    }
    
    private func createUnbuiltZoneNode(zone: Zone) -> SCNNode {
        let wrapper = SCNNode()
        wrapper.position = SCNVector3(zone.centerX, 0, zone.centerZ)
        
        // Un panneau de construction
        let sign = AssetManager.shared.getModel(named: "fence", folder: "suburban")
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
        var intensity: CGFloat = 1000
        var ambientIntensity: CGFloat = 300
        var lightColor = UIColor.white
        var ambientColor = UIColor(white: 0.9, alpha: 1.0)
        
        if time >= 6 && time <= 9 {
            // Matin
            let t = CGFloat((time - 6) / 3)
            intensity = 200 + (800 * t)
            ambientIntensity = 100 + (200 * t)
            lightColor = UIColor(red: 1.0, green: 0.8 + 0.2*t, blue: 0.6 + 0.4*t, alpha: 1.0)
        } else if time > 9 && time <= 16 {
            // Jour
            intensity = 1000
            ambientIntensity = 300
        } else if time > 16 && time <= 19 {
            // Soir
            let t = CGFloat((time - 16) / 3)
            intensity = 1000 - (800 * t)
            ambientIntensity = 300 - (200 * t)
            lightColor = UIColor(red: 1.0, green: 0.9 - 0.3*t, blue: 1.0 - 0.6*t, alpha: 1.0)
        } else {
            // Nuit
            intensity = 200
            ambientIntensity = 100
            lightColor = UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 1.0)
            ambientColor = UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        }
        
        directionalLightNode.light?.intensity = intensity
        directionalLightNode.light?.color = lightColor
        ambientLightNode.light?.intensity = ambientIntensity
        ambientLightNode.light?.color = ambientColor
        
        if time >= 6 && time <= 19 {
            let dayProgress = (time - 6) / Float(13.0)
            let angleX = Float.pi - (Float.pi * dayProgress)
            directionalLightNode.eulerAngles = SCNVector3(x: -angleX, y: Float.pi/4, z: 0)
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
