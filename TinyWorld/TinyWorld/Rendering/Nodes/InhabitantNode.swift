import SceneKit
import UIKit

class InhabitantNode: SCNNode {
    let inhabitantId: UUID
    
    private var isInitialized = false
    private var lastSyncPosition: SCNVector3?
    
    // Character setup
    private var characterNode: SCNNode?
    
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
        if let char = AssetManager.shared.getCharacter() {
            // L'elfe est parfois tres grand selon l'export (souvent 100x plus grand ou 100x plus petit)
            // Adapter l'echelle pour qu'il fasse environ 0.8 unites de haut
            char.scale = SCNVector3(0.015, 0.015, 0.015) 
            char.position = SCNVector3(0, 0, 0)
            
            // Appliquer une rotation pour le mettre face a Z positif si necessaire
            char.eulerAngles.y = Float.pi // Ajuster selon l'orientation de base de l'elfe
            
            self.characterNode = char
            self.addChildNode(char)
            
            self.childNodes.forEach { castShadowsRecursively(node: $0) }
        }
    }
    
    private func castShadowsRecursively(node: SCNNode) {
        node.castsShadow = true
        node.childNodes.forEach { castShadowsRecursively(node: $0) }
    }
    
    private func applyAppearance(from data: InhabitantData) {
        guard let char = characterNode else { return }
        // Personnalisation des materiaux de l'elfe
        var hash = data.id.hashValue
        let skinTones: [UIColor] = [
            UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0),
            UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0),
            UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        ]
        let skinColor = skinTones[abs(hash) % skinTones.count]
        
        let shirtColor = UIColor(red: CGFloat(data.colorR), green: CGFloat(data.colorG), blue: CGFloat(data.colorB), alpha: 1.0)
        
        // Trouver les meshes pour les teinter (tres simple avec SceneKit material.multiply)
        char.enumerateChildNodes { (node, _) in
            if let geo = node.geometry {
                if geo.name?.lowercased().contains("face") == true || geo.name?.lowercased().contains("body") == true {
                    geo.firstMaterial?.multiply.contents = skinColor
                } else if geo.name?.lowercased().contains("hair") == true {
                    geo.firstMaterial?.multiply.contents = shirtColor
                } else {
                    geo.firstMaterial?.multiply.contents = shirtColor
                }
            }
        }
    }
    
    func sync(with data: InhabitantData) {
        if !isInitialized {
            applyAppearance(from: data)
            // Lancer l'animation Idle par defaut
            playAnimation(name: "idle")
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
        
        // Gestion des etats d'animation
        if data.activity == .sleeping {
            self.eulerAngles.x = -Float.pi / 2
            self.position.y = 0.1
        } else {
            self.eulerAngles.x = 0
            self.position.y = 0.0
        }
    }
    
    // L'elfe est importe avec ses animations DAE par defaut (qui s'executent souvent en boucle)
    private func playAnimation(name: String) {
        // Optionnel : si le fichier DAE possede plusieurs animations nommees
    }
}
