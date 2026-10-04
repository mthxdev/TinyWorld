import SceneKit
import UIKit

class InhabitantNode: SCNNode {
    let inhabitantId: UUID
    private let bodyNode: SCNNode
    private let headNode: SCNNode
    private let leftArm: SCNNode
    private let rightArm: SCNNode
    
    // Pour l'animation
    private var isWalking = false
    
    init(id: UUID) {
        self.inhabitantId = id
        
        // Corps
        let bodyGeo = SCNBox(width: 0.4, height: 0.6, length: 0.3, chamferRadius: 0.1)
        bodyGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
        bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, 0.4, 0) // Surélevé pour les "jambes" imaginaires ou futures
        
        // Tête
        let headGeo = SCNSphere(radius: 0.25)
        headGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)
        headNode = SCNNode(geometry: headGeo)
        headNode.position = SCNVector3(0, 0.85, 0)
        
        // Bras gauche
        let armGeo = SCNCapsule(capRadius: 0.08, height: 0.4)
        armGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
        leftArm = SCNNode(geometry: armGeo)
        leftArm.position = SCNVector3(-0.3, 0.4, 0)
        
        // Bras droit
        rightArm = SCNNode(geometry: armGeo)
        rightArm.position = SCNVector3(0.3, 0.4, 0)
        
        super.init()
        
        addChildNode(bodyNode)
        addChildNode(headNode)
        addChildNode(leftArm)
        addChildNode(rightArm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func sync(with data: InhabitantData) {
        let targetPosition = SCNVector3(data.positionX, 0, data.positionZ)
        
        if self.position.x != targetPosition.x || self.position.z != targetPosition.z {
            let dx = targetPosition.x - self.position.x
            let dz = targetPosition.z - self.position.z
            let angle = atan2(dx, dz)
            
            // Rotation fluide
            let actionRotate = SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.1, shortestUnitArc: true)
            self.runAction(actionRotate)
            
            self.position = targetPosition
        }
        
        updateAnimation(isMoving: data.state == .moving, speed: data.speed)
    }
    
    private func updateAnimation(isMoving: Bool, speed: Float) {
        if isMoving && !isWalking {
            isWalking = true
            
            // Calculer la durée de l'animation en fonction de la vitesse (plus rapide = animation plus rapide)
            // ex: speed=0.5 -> duration = 0.2. speed=1.0 -> duration = 0.1
            let baseAnimDuration: TimeInterval = 0.3
            let duration = max(0.1, baseAnimDuration / TimeInterval(max(0.1, speed * 2.0)))
            
            let armSwing = CGFloat.pi / 4
            
            // Bras gauche
            let leftFwd = SCNAction.rotateTo(x: armSwing, y: 0, z: 0, duration: duration)
            let leftBack = SCNAction.rotateTo(x: -armSwing, y: 0, z: 0, duration: duration)
            let leftSeq = SCNAction.sequence([leftFwd, leftBack, leftBack, leftFwd])
            leftArm.runAction(SCNAction.repeatForever(leftSeq), forKey: "walk")
            
            // Bras droit (opposé)
            let rightFwd = SCNAction.rotateTo(x: armSwing, y: 0, z: 0, duration: duration)
            let rightBack = SCNAction.rotateTo(x: -armSwing, y: 0, z: 0, duration: duration)
            let rightSeq = SCNAction.sequence([rightBack, rightFwd, rightFwd, rightBack])
            rightArm.runAction(SCNAction.repeatForever(rightSeq), forKey: "walk")
            
            // Petit rebond du corps
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
            
            // Reset position/rotation
            leftArm.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2))
            rightArm.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2))
            bodyNode.runAction(SCNAction.moveTo(y: 0.4, duration: 0.2))
            headNode.runAction(SCNAction.moveTo(y: 0.85, duration: 0.2))
        }
    }
}
