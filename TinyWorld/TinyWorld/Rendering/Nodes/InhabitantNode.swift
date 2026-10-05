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
        let char = CharacterBuilder.createHumanoid(hash: inhabitantId.hashValue)
        self.characterNode = char
        self.addChildNode(char)
        
        let action = SCNAction.customAction(duration: .greatestFiniteMagnitude) { [weak self] node, time in
            self?.updateAnimation(time: time)
        }
        self.runAction(action)
    }
    
    private func updateAnimation(time: CGFloat) {
        guard let hips = characterNode?.childNode(withName: "hips", recursively: true),
              let torso = characterNode?.childNode(withName: "torso", recursively: true),
              let shoulderL = characterNode?.childNode(withName: "shoulderL", recursively: true),
              let shoulderR = characterNode?.childNode(withName: "shoulderR", recursively: true),
              let hipL = characterNode?.childNode(withName: "hipL", recursively: true),
              let hipR = characterNode?.childNode(withName: "hipR", recursively: true) else { return }
        
        if isWalking {
            animTime += 0.15
            let speed: Float = 1.0
            
            // Walk cycle
            hipL.eulerAngles.x = sin(Float(animTime) * speed) * 0.8
            hipR.eulerAngles.x = -sin(Float(animTime) * speed) * 0.8
            
            shoulderL.eulerAngles.x = -sin(Float(animTime) * speed) * 0.6
            shoulderR.eulerAngles.x = sin(Float(animTime) * speed) * 0.6
            
            hips.position.y = 0.45 + abs(sin(Float(animTime) * speed)) * 0.05
            torso.eulerAngles.y = sin(Float(animTime) * speed) * 0.1
            
        } else {
            animTime += 0.05
            // Idle cycle (breathing)
            hipL.eulerAngles.x = 0
            hipR.eulerAngles.x = 0
            shoulderL.eulerAngles.x = 0
            shoulderR.eulerAngles.x = 0
            
            hips.position.y = 0.45
            torso.position.y = 0.2 + sin(Float(animTime)) * 0.015
            torso.eulerAngles.y = 0
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
            self.isWalking = true
        } else {
            self.isWalking = false
        }
        
        if data.activity == .sleeping {
            self.eulerAngles.x = -Float.pi / 2
            self.isWalking = false
        } else {
            self.eulerAngles.x = 0
        }
    }
}
