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
        let colors: [UIColor] = [.red, .blue, .green, .orange, .purple, .cyan, .magenta]
        let shirtColor = colors[(abs(inhabitantId.hashValue) / 10) % colors.count]
        
        char.enumerateChildNodes { (node, _) in
            if let geo = node.geometry {
                // If it's a casual character, they usually have "Shirt" or similar in material names
                for mat in geo.materials {
                    if mat.name?.lowercased().contains("shirt") == true || mat.name?.lowercased().contains("top") == true {
                        mat.diffuse.contents = shirtColor
                    }
                }
            }
        }
        
        self.characterNode = char
        self.addChildNode(char)
        
        // Setup animations
        // In Quaternius FBX files, the animations are attached to the root node or children.
        // We will just let the default animation play for now, or extract "Walk" and "Idle"
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
