import SceneKit

class InhabitantNode: SCNNode {
    let inhabitantId: UUID
    
    init(id: UUID) {
        self.inhabitantId = id
        super.init()
        
        // Corps (Capsule stylisée)
        let bodyGeo = SCNCapsule(capRadius: 0.3, height: 1.0)
        bodyGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, 0.5, 0) // Posé sur le sol
        
        // Tête (Sphère)
        let headGeo = SCNSphere(radius: 0.25)
        headGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)
        let headNode = SCNNode(geometry: headGeo)
        headNode.position = SCNVector3(0, 1.0, 0)
        
        addChildNode(bodyNode)
        addChildNode(headNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func sync(with data: InhabitantData) {
        // Mise à jour de la position 3D en fonction des coordonnées logiques
        // SceneKit interpolera doucement si on utilise une SCNAction ou si on set la position
        // Pour un effet fluide direct sans physique, on peut juste définir la position, 
        // ou utiliser une action move. Ici on utilise la position directe (si le tick de la simu
        // est rapide) ou un SCNAction.move si on veut une belle interpolation.
        
        let targetPosition = SCNVector3(data.positionX, 0, data.positionZ)
        
        if self.position.x != targetPosition.x || self.position.z != targetPosition.z {
            // Orientation vers la destination
            let dx = targetPosition.x - self.position.x
            let dz = targetPosition.z - self.position.z
            let angle = atan2(dx, dz)
            self.eulerAngles.y = angle
            
            self.position = targetPosition
        }
        
        // Animation "Bop" (petit saut) quand il bouge
        if data.state == .moving {
            if !self.hasActions {
                let up = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.1)
                let down = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 0.1)
                self.runAction(SCNAction.repeatForever(SCNAction.sequence([up, down])))
            }
        } else {
            self.removeAllActions()
            self.position.y = 0 // Réaligner au sol
        }
    }
}
