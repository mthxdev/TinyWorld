import SceneKit
import UIKit

class InhabitantNode: SCNNode {
    let inhabitantId: UUID
    private let bodyNode: SCNNode
    private let headNode: SCNNode
    private let leftArm: SCNNode
    private let rightArm: SCNNode
    private var hatNode: SCNNode?
    
    // Pour l'animation
    private var isWalking = false
    private var lastSyncPosition: SCNVector3?
    private var isInitialized = false
    
    init(id: UUID) {
        self.inhabitantId = id
        
        // Corps
        let bodyGeo = SCNBox(width: 0.4, height: 0.6, length: 0.3, chamferRadius: 0.1)
        bodyGeo.firstMaterial?.diffuse.contents = UIColor.gray
        bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, 0.4, 0)
        
        // Tete
        let headGeo = SCNSphere(radius: 0.25)
        headGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)
        headNode = SCNNode(geometry: headGeo)
        headNode.position = SCNVector3(0, 0.85, 0)
        
        // Bras gauche
        let armGeo = SCNCapsule(capRadius: 0.08, height: 0.4)
        armGeo.firstMaterial?.diffuse.contents = UIColor.gray
        leftArm = SCNNode(geometry: armGeo)
        leftArm.position = SCNVector3(-0.3, 0.4, 0)
        
        // Bras droit
        rightArm = SCNNode(geometry: armGeo)
        rightArm.position = SCNVector3(0.3, 0.4, 0)
        
        super.init()
        self.name = id.uuidString
        
        addChildNode(bodyNode)
        addChildNode(headNode)
        addChildNode(leftArm)
        addChildNode(rightArm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func applyAppearance(from data: InhabitantData) {
        let color = UIColor(red: CGFloat(data.colorR), green: CGFloat(data.colorG), blue: CGFloat(data.colorB), alpha: 1.0)
        bodyNode.geometry?.firstMaterial?.diffuse.contents = color
        leftArm.geometry?.firstMaterial?.diffuse.contents = color
        rightArm.geometry?.firstMaterial?.diffuse.contents = color
        
        if data.hasHat && hatNode == nil {
            let hatGeo = SCNCone(topRadius: 0, bottomRadius: 0.3, height: 0.3)
            hatGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
            let hat = SCNNode(geometry: hatGeo)
            hat.position = SCNVector3(0, 0.25, 0)
            headNode.addChildNode(hat)
            self.hatNode = hat
        }
    }
    
    func sync(with data: InhabitantData) {
        if !isInitialized {
            applyAppearance(from: data)
            isInitialized = true
        }
        
        let isSleeping = data.activity == .sleeping
        let targetY: Float = isSleeping ? 0.2 : 0.0
        let targetPosition = SCNVector3(data.positionX, targetY, data.positionZ)
        let currentPos = lastSyncPosition ?? self.position
        
        let dx = targetPosition.x - currentPos.x
        let dz = targetPosition.z - currentPos.z
        let distance = (dx*dx + dz*dz).squareRoot()
        
        if distance > 0.001 {
            if !isSleeping {
                let angle = atan2(Double(dx), Double(dz))
                let actionRotate = SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.1)
                self.runAction(actionRotate)
            }
            
            let actionMove = SCNAction.move(to: targetPosition, duration: 0.1)
            self.runAction(actionMove, forKey: "smoothMove")
            self.lastSyncPosition = targetPosition
        }
        
        updateAnimation(isMoving: data.isMoving, speed: data.speed)
        updateActivityState(activity: data.activity)
    }
    
    private func updateAnimation(isMoving: Bool, speed: Float) {
        if isMoving && !isWalking {
            isWalking = true
            
            let baseAnimDuration: TimeInterval = 0.3
            let duration = max(0.1, baseAnimDuration / TimeInterval(max(0.1, speed * 2.0)))
            let armSwing = CGFloat.pi / 4
            
            let leftFwd = SCNAction.rotateTo(x: armSwing, y: 0, z: 0, duration: duration)
            let leftBack = SCNAction.rotateTo(x: -armSwing, y: 0, z: 0, duration: duration)
            let leftSeq = SCNAction.sequence([leftFwd, leftBack, leftBack, leftFwd])
            leftArm.runAction(SCNAction.repeatForever(leftSeq), forKey: "walk")
            
            let rightFwd = SCNAction.rotateTo(x: armSwing, y: 0, z: 0, duration: duration)
            let rightBack = SCNAction.rotateTo(x: -armSwing, y: 0, z: 0, duration: duration)
            let rightSeq = SCNAction.sequence([rightBack, rightFwd, rightFwd, rightBack])
            rightArm.runAction(SCNAction.repeatForever(rightSeq), forKey: "walk")
            
            let up = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: duration)
            let down = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: duration)
            let bopSeq = SCNAction.sequence([up, down])
            bodyNode.runAction(SCNAction.repeatForever(bopSeq), forKey: "bop")
            headNode.runAction(SCNAction.repeatForever(bopSeq), forKey: "bop")
            
        } else if !isMoving && isWalking {
            isWalking = false
            leftArm.removeAction(forKey: "walk")
            rightArm.removeAction(forKey: "walk")
            bodyNode.removeAction(forKey: "bop")
            headNode.removeAction(forKey: "bop")
            
            leftArm.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2))
            rightArm.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2))
            bodyNode.runAction(SCNAction.move(to: SCNVector3(0, 0.4, 0), duration: 0.2))
            headNode.runAction(SCNAction.move(to: SCNVector3(0, 0.85, 0), duration: 0.2))
        }
    }
    
    func updateActivityState(activity: Activity) {
        if activity == .sleeping {
            self.eulerAngles.x = -Float.pi / 2
        } else {
            self.eulerAngles.x = 0
        }
    }
}
