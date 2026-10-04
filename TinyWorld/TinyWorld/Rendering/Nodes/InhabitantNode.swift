import SceneKit
import UIKit

class InhabitantNode: SCNNode {
    let inhabitantId: UUID
    
    // Articulation joints (pivots)
    private let pelvis = SCNNode()
    private let leftShoulder = SCNNode()
    private let rightShoulder = SCNNode()
    private let leftHip = SCNNode()
    private let rightHip = SCNNode()
    private let headJoint = SCNNode()
    
    // Geometries nodes
    private let bodyNode = SCNNode()
    private let headNode = SCNNode()
    private let hairNode = SCNNode()
    
    // Animation state
    private var isWalking = false
    private var isInitialized = false
    private var lastSyncPosition: SCNVector3?
    
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
        // Pelvis is the center of the character (hips level), around y = 0.5
        pelvis.position = SCNVector3(0, 0.45, 0)
        addChildNode(pelvis)
        
        // Torso
        let torsoGeo = SCNBox(width: 0.35, height: 0.4, length: 0.25, chamferRadius: 0.05)
        bodyNode.geometry = torsoGeo
        bodyNode.position = SCNVector3(0, 0.2, 0) // Shifted up from pelvis
        pelvis.addChildNode(bodyNode)
        
        // Head Joint
        headJoint.position = SCNVector3(0, 0.45, 0)
        pelvis.addChildNode(headJoint)
        
        let headGeo = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0.08)
        headNode.geometry = headGeo
        headNode.position = SCNVector3(0, 0.15, 0)
        headJoint.addChildNode(headNode)
        
        // Hair / Hat
        let hairGeo = SCNBox(width: 0.32, height: 0.1, length: 0.32, chamferRadius: 0.02)
        hairNode.geometry = hairGeo
        hairNode.position = SCNVector3(0, 0.35, 0)
        headJoint.addChildNode(hairNode)
        
        // Arms
        leftShoulder.position = SCNVector3(-0.25, 0.35, 0)
        rightShoulder.position = SCNVector3(0.25, 0.35, 0)
        pelvis.addChildNode(leftShoulder)
        pelvis.addChildNode(rightShoulder)
        
        let armGeo = SCNBox(width: 0.12, height: 0.35, length: 0.12, chamferRadius: 0.04)
        let lArm = SCNNode(geometry: armGeo)
        lArm.position = SCNVector3(0, -0.15, 0) // Grow downwards
        leftShoulder.addChildNode(lArm)
        
        let rArm = SCNNode(geometry: armGeo)
        rArm.position = SCNVector3(0, -0.15, 0)
        rightShoulder.addChildNode(rArm)
        
        // Legs
        leftHip.position = SCNVector3(-0.1, 0.0, 0)
        rightHip.position = SCNVector3(0.1, 0.0, 0)
        pelvis.addChildNode(leftHip)
        pelvis.addChildNode(rightHip)
        
        let legGeo = SCNBox(width: 0.14, height: 0.4, length: 0.14, chamferRadius: 0.02)
        let lLeg = SCNNode(geometry: legGeo)
        lLeg.position = SCNVector3(0, -0.2, 0)
        leftHip.addChildNode(lLeg)
        
        let rLeg = SCNNode(geometry: legGeo)
        rLeg.position = SCNVector3(0, -0.2, 0)
        rightHip.addChildNode(rLeg)
        
        // Setup default materials to avoid nil crashes
        let defaultMat = SCNMaterial()
        defaultMat.diffuse.contents = UIColor.gray
        
        [torsoGeo, headGeo, hairGeo, armGeo, legGeo].forEach { geo in
            geo.firstMaterial = defaultMat.copy() as? SCNMaterial
        }
        
        // Ombres
        self.childNodes.forEach { castShadowsRecursively(node: $0) }
    }
    
    private func castShadowsRecursively(node: SCNNode) {
        node.castsShadow = true
        node.childNodes.forEach { castShadowsRecursively(node: $0) }
    }
    
    private func applyAppearance(from data: InhabitantData) {
        // Generer des couleurs deterministes basees sur l'UUID pour la peau et les pantalons
        var hash = data.id.hashValue
        let skinTones: [UIColor] = [
            UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0),
            UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0),
            UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0)
        ]
        let skinColor = skinTones[abs(hash) % skinTones.count]
        
        hash = hash / 10
        let pantsColors: [UIColor] = [
            UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0), // Blue jeans
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), // Dark grey
            UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0), // Brown
            UIColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1.0)  // Beige
        ]
        let pantsColor = pantsColors[abs(hash) % pantsColors.count]
        
        hash = hash / 10
        let hairColors: [UIColor] = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0), // Black
            UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0), // Brown
            UIColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1.0), // Blonde
            UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), // Grey
            UIColor(red: 0.7, green: 0.3, blue: 0.2, alpha: 1.0)  // Redhead
        ]
        let hairColor = hairColors[abs(hash) % hairColors.count]
        
        let shirtColor = UIColor(red: CGFloat(data.colorR), green: CGFloat(data.colorG), blue: CGFloat(data.colorB), alpha: 1.0)
        
        // Appliquer les couleurs
        headNode.geometry?.firstMaterial?.diffuse.contents = skinColor
        
        // Torso et bras = T-shirt
        bodyNode.geometry?.firstMaterial?.diffuse.contents = shirtColor
        leftShoulder.childNodes.first?.geometry?.firstMaterial?.diffuse.contents = skinColor // Bras nus ou manches ? Disons peau pour les bras.
        rightShoulder.childNodes.first?.geometry?.firstMaterial?.diffuse.contents = skinColor
        
        // Pantalon
        leftHip.childNodes.first?.geometry?.firstMaterial?.diffuse.contents = pantsColor
        rightHip.childNodes.first?.geometry?.firstMaterial?.diffuse.contents = pantsColor
        
        // Cheveux / Chapeau
        if data.hasHat {
            hairNode.geometry = SCNCylinder(radius: 0.2, height: 0.15)
            hairNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
            hairNode.position = SCNVector3(0, 0.35, 0)
        } else {
            hairNode.geometry?.firstMaterial?.diffuse.contents = hairColor
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
                // On oriente tout le node vers la direction
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
            
            let duration = max(0.15, 0.3 / TimeInterval(max(0.1, speed * 2.0)))
            let swing = CGFloat.pi / 4.5
            
            // Animation Bras (Opposes aux jambes)
            let armFwd = SCNAction.rotateTo(x: swing, y: 0, z: 0, duration: duration)
            let armBack = SCNAction.rotateTo(x: -swing, y: 0, z: 0, duration: duration)
            armFwd.timingMode = .easeInEaseOut
            armBack.timingMode = .easeInEaseOut
            
            let lArmSeq = SCNAction.sequence([armFwd, armBack, armBack, armFwd])
            leftShoulder.runAction(SCNAction.repeatForever(lArmSeq), forKey: "walk")
            
            let rArmSeq = SCNAction.sequence([armBack, armFwd, armFwd, armBack])
            rightShoulder.runAction(SCNAction.repeatForever(rArmSeq), forKey: "walk")
            
            // Animation Jambes
            let legFwd = SCNAction.rotateTo(x: swing, y: 0, z: 0, duration: duration)
            let legBack = SCNAction.rotateTo(x: -swing, y: 0, z: 0, duration: duration)
            legFwd.timingMode = .easeInEaseOut
            legBack.timingMode = .easeInEaseOut
            
            let lLegSeq = SCNAction.sequence([legBack, legFwd, legFwd, legBack])
            leftHip.runAction(SCNAction.repeatForever(lLegSeq), forKey: "walk")
            
            let rLegSeq = SCNAction.sequence([legFwd, legBack, legBack, legFwd])
            rightHip.runAction(SCNAction.repeatForever(rLegSeq), forKey: "walk")
            
            // Bobbing du corps
            let up = SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: duration)
            let down = SCNAction.moveBy(x: 0, y: -0.08, z: 0, duration: duration)
            up.timingMode = .easeOut
            down.timingMode = .easeIn
            pelvis.runAction(SCNAction.repeatForever(SCNAction.sequence([up, down])), forKey: "bop")
            
        } else if !isMoving && isWalking {
            isWalking = false
            leftShoulder.removeAction(forKey: "walk")
            rightShoulder.removeAction(forKey: "walk")
            leftHip.removeAction(forKey: "walk")
            rightHip.removeAction(forKey: "walk")
            pelvis.removeAction(forKey: "bop")
            
            let resetDur = 0.2
            leftShoulder.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: resetDur))
            rightShoulder.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: resetDur))
            leftHip.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: resetDur))
            rightHip.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: resetDur))
            pelvis.runAction(SCNAction.move(to: SCNVector3(0, 0.45, 0), duration: resetDur))
        }
    }
    
    func updateActivityState(activity: Activity) {
        if activity == .sleeping {
            // S'allonge pour dormir
            self.eulerAngles.x = -Float.pi / 2
            self.position.y = 0.1 // Legerement sureleve pour eviter le z-fighting avec le sol
        } else {
            self.eulerAngles.x = 0
            self.position.y = 0.0
        }
    }
}
