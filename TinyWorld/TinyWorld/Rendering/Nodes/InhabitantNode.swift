import SceneKit
import UIKit

class InhabitantNode: SCNNode {
    let inhabitantId: UUID
    
    private var isInitialized = false
    private var lastSyncPosition: SCNVector3?
    
    // Character setup
    private var characterNode: SCNNode?
    private var isWalking = false
    private var animTime: TimeInterval = 0
    
    init(id: UUID) {
        self.inhabitantId = id
        super.init()
        self.name = id.uuidString
        setupAnatomy()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAnatomy() {
        let models = ["villager_male", "villager_female", "villager_male2", "villager_female2"]
        let modelName = models[abs(inhabitantId.hashValue) % models.count]
        
        let char = AssetManager.shared.getModel(named: modelName, folder: "character")
        // FBX models often need scale adjustment. We'll adjust depending on visual size.
        char.scale = SCNVector3(0.012, 0.012, 0.012)
        
        // Add random variation to materials if possible (FBX materials are nested)
        let shirtColors: [UIColor] = [
            UIColor(red: 0.85, green: 0.3, blue: 0.25, alpha: 1.0),   // Red
            UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1.0),   // Blue
            UIColor(red: 0.3, green: 0.7, blue: 0.35, alpha: 1.0),     // Green
            UIColor(red: 0.95, green: 0.6, blue: 0.15, alpha: 1.0),    // Orange
            UIColor(red: 0.65, green: 0.35, blue: 0.8, alpha: 1.0),    // Purple
            UIColor(red: 0.2, green: 0.75, blue: 0.8, alpha: 1.0),     // Cyan
            UIColor(red: 0.85, green: 0.35, blue: 0.65, alpha: 1.0),   // Magenta
            UIColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1.0),     // Yellow
            UIColor(red: 0.4, green: 0.6, blue: 0.5, alpha: 1.0),      // Teal
            UIColor(red: 0.75, green: 0.5, blue: 0.35, alpha: 1.0),    // Brown
        ]
        let shirtColor = shirtColors[(abs(inhabitantId.hashValue) / 10) % shirtColors.count]
        
        let pantsColors: [UIColor] = [
            UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0),      // Dark blue
            UIColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1.0),   // Brown
            UIColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0),   // Charcoal
            UIColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0),    // Tan
            UIColor(red: 0.15, green: 0.25, blue: 0.2, alpha: 1.0),    // Dark green
        ]
        let pantsColor = pantsColors[(abs(inhabitantId.hashValue) / 7) % pantsColors.count]
        
        char.enumerateChildNodes { (node, _) in
            if let geo = node.geometry {
                for mat in geo.materials {
                    let matName = mat.name?.lowercased() ?? ""
                    if matName.contains("shirt") || matName.contains("top") || matName.contains("torso") || matName.contains("body") {
                        mat.diffuse.contents = shirtColor
                        mat.roughness.contents = NSNumber(value: 0.85)
                        mat.metalness.contents = NSNumber(value: 0.0)
                    } else if matName.contains("pant") || matName.contains("leg") || matName.contains("trouser") || matName.contains("jean") || matName.contains("short") {
                        mat.diffuse.contents = pantsColor
                        mat.roughness.contents = NSNumber(value: 0.8)
                        mat.metalness.contents = NSNumber(value: 0.0)
                    } else if matName.contains("shoe") || matName.contains("boot") || matName.contains("foot") {
                        mat.diffuse.contents = UIColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1.0)
                        mat.roughness.contents = NSNumber(value: 0.7)
                        mat.metalness.contents = NSNumber(value: 0.05)
                    } else if matName.contains("hair") {
                        let hairColors: [UIColor] = [
                            UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0),   // Dark brown
                            UIColor(red: 0.4, green: 0.28, blue: 0.18, alpha: 1.0),     // Brown
                            UIColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0),     // Light brown
                            UIColor(red: 0.75, green: 0.55, blue: 0.3, alpha: 1.0),     // Blonde
                            UIColor(red: 0.6, green: 0.25, blue: 0.15, alpha: 1.0),     // Auburn
                            UIColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1.0),     // Black
                        ]
                        let hairColor = hairColors[(abs(inhabitantId.hashValue) / 13) % hairColors.count]
                        mat.diffuse.contents = hairColor
                        mat.roughness.contents = NSNumber(value: 0.75)
                        mat.metalness.contents = NSNumber(value: 0.0)
                    } else if matName.contains("skin") || matName.contains("face") || matName.contains("head") || matName.contains("hand") || matName.contains("arm") {
                        let skinTones: [UIColor] = [
                            UIColor(red: 0.95, green: 0.8, blue: 0.68, alpha: 1.0),   // Light
                            UIColor(red: 0.88, green: 0.7, blue: 0.58, alpha: 1.0),   // Medium-light
                            UIColor(red: 0.78, green: 0.6, blue: 0.48, alpha: 1.0),   // Medium
                            UIColor(red: 0.65, green: 0.48, blue: 0.38, alpha: 1.0),  // Medium-dark
                            UIColor(red: 0.52, green: 0.38, blue: 0.28, alpha: 1.0),  // Dark
                        ]
                        let skinColor = skinTones[(abs(inhabitantId.hashValue) / 17) % skinTones.count]
                        mat.diffuse.contents = skinColor
                        mat.roughness.contents = NSNumber(value: 0.65)
                        mat.metalness.contents = NSNumber(value: 0.02)
                    }
                }
            }
        }
        
        self.characterNode = char
        self.addChildNode(char)
        
        // Setup animations
        playAnimation(name: "Idle")
    }
    
    private func updateAnimation(time: CGFloat) {
        // Not used manually anymore since we rely on FBX animations!
    }
    
    private func playAnimation(name: String) {
        guard let char = characterNode else { return }
        
        // Try to find the animation by name in the loaded Scene
        // SCNScene(named:) usually attaches animations to the root node.
        // If we want to switch between Idle and Walk, we need to load them or they might be bundled.
        // Since Quaternius bundles them, we'll try to find them by key.
        let keys = char.animationKeys
        var foundKey: String? = nil
        for key in keys {
            if key.lowercased().contains(name.lowercased()) {
                foundKey = key
                break
            }
        }
        
        if let key = foundKey {
            // SceneKit automatically plays them all sometimes, so we might need to stop others
            for k in keys {
                if k != key {
                    char.removeAnimation(forKey: k, blendOutDuration: 0.2)
                }
            }
            // Add it if it's not playing
            if char.animationPlayer(forKey: key) == nil {
                // We'd need to load the animation if we stripped it, but for now we rely on the default SceneKit playback
            }
        }
    }
    
    func sync(with data: InhabitantData) {
        if !isInitialized {
            isInitialized = true
        }
        
        let py = TerrainBuilder.getHeight(at: data.positionX, z: data.positionZ)
        
        let isSleeping = data.activity == .sleeping
        let targetY: Float = py + (isSleeping ? 0.2 : 0.0)
        let targetPosition = SCNVector3(data.positionX, targetY, data.positionZ)
        let currentPos = lastSyncPosition ?? self.position
        
        let dx = targetPosition.x - currentPos.x
        let dz = targetPosition.z - currentPos.z
        let distance = hypot(Float(dx), Float(dz))
        
        if distance > 0.001 {
            if !isSleeping {
                let angle = atan2(Double(dx), Double(dz))
                let actionRotate = SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.1)
                self.runAction(actionRotate)
            }
            
            let actionMove = SCNAction.move(to: targetPosition, duration: 0.1)
            self.runAction(actionMove, forKey: "smoothMove")
            self.lastSyncPosition = targetPosition
            
            if !isWalking {
                self.isWalking = true
                playAnimation(name: "Walk")
            }
        } else {
            if isWalking {
                self.isWalking = false
                playAnimation(name: "Idle")
            }
        }
        
        if data.activity == .sleeping {
            self.eulerAngles.x = -Float.pi / 2
            if isWalking {
                self.isWalking = false
            }
        } else {
            self.eulerAngles.x = 0
        }
    }
}