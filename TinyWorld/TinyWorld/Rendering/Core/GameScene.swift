import UIKit
import SceneKit

class GameScene: SCNScene {
    let cameraController: CameraController
    private var environmentNode: EnvironmentNode!
    private var inhabitantNodes: [UUID: InhabitantNode] = [:]
    
    override init() {
        self.cameraController = CameraController(scene: SCNScene()) // sera reaffecte
        super.init()
        
        self.cameraController.pivotNode.removeFromParentNode()
        self.rootNode.addChildNode(cameraController.pivotNode)
        
        // Initialiser avec un EnvironmentNode vide (seulement sol et lumiere)
        self.environmentNode = EnvironmentNode()
        self.rootNode.addChildNode(environmentNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func sync(with worldData: WorldData) {
        environmentNode.sync(with: worldData)
        
        let time = worldData.timeOfDay
        var targetColor = UIColor.black
        
        if time >= 6 && time < 9 { // Aube -> Jour
            let t = CGFloat((time - 6) / 3)
            let dawn = UIColor(red: 0.8, green: 0.5, blue: 0.4, alpha: 1.0)
            let day = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
            targetColor = interpolateColor(from: dawn, to: day, progress: t)
        } else if time >= 9 && time < 16 { // Jour
            targetColor = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        } else if time >= 16 && time < 19 { // Jour -> Crepuscule
            let t = CGFloat((time - 16) / 3)
            let day = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
            let dusk = UIColor(red: 0.6, green: 0.3, blue: 0.5, alpha: 1.0)
            targetColor = interpolateColor(from: day, to: dusk, progress: t)
        } else if time >= 19 && time < 21 { // Crepuscule -> Nuit
            let t = CGFloat((time - 19) / 2)
            let dusk = UIColor(red: 0.6, green: 0.3, blue: 0.5, alpha: 1.0)
            let night = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
            targetColor = interpolateColor(from: dusk, to: night, progress: t)
        } else { // Nuit
            targetColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        }
        
        if let currentColor = self.background.contents as? UIColor {
            self.background.contents = interpolateColor(from: currentColor, to: targetColor, progress: 0.1)
        } else {
            self.background.contents = targetColor
        }
        
        // Synchroniser les habitants
        for inhabitantData in worldData.inhabitants {
            if let node = inhabitantNodes[inhabitantData.id] {
                node.sync(with: inhabitantData)
            } else {
                let newNode = InhabitantNode(id: inhabitantData.id)
                newNode.sync(with: inhabitantData)
                self.rootNode.addChildNode(newNode)
                inhabitantNodes[inhabitantData.id] = newNode
            }
        }
    }
    
    private func interpolateColor(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 + (r2 - r1) * progress,
            green: g1 + (g2 - g1) * progress,
            blue: b1 + (b2 - b1) * progress,
            alpha: 1.0
        )
    }
}
