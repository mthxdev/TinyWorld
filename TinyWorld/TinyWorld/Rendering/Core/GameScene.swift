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
        
        // Configuration de la brume lointaine (horizon uniquement, ne décolore JAMAIS l'île!)
        self.fogStartDistance = 55.0
        self.fogEndDistance = 95.0
        self.fogDensityExponent = 1.1
        
        // Enable HDR for better PBR rendering
        self.background.contents = UIColor(red: 0.45, green: 0.7, blue: 0.92, alpha: 1.0)
        
        // Environnement HDRI pour le rendu PBR (Reflets et lumière ambiante réalistes)
        self.lightingEnvironment.contents = "art.scnassets/textures/sky.exr"
        // L'HDRI reste utile aux reflets PBR, mais ne doit pas blanchir le centre
        // lorsqu'il se cumule avec les lumières de l'environnement.
        self.lightingEnvironment.intensity = 0.45
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func sync(with worldData: WorldData) {
        environmentNode.sync(with: worldData)
        
        let time = worldData.timeOfDay
        var targetColor = UIColor.black
        
        if time >= 6 && time < 9 { // Aube -> Jour (Chaud et doré, pas beige terne)
            let t = CGFloat((time - 6) / 3)
            let dawn = UIColor(red: 0.98, green: 0.82, blue: 0.58, alpha: 1.0)
            let day = UIColor(red: 0.45, green: 0.7, blue: 0.92, alpha: 1.0)
            targetColor = interpolateColor(from: dawn, to: day, progress: t)
        } else if time >= 9 && time < 16 { // Jour (Ciel d'azur stylisé limpide)
            targetColor = UIColor(red: 0.45, green: 0.7, blue: 0.92, alpha: 1.0)
        } else if time >= 16 && time < 19 { // Jour -> Crepuscule
            let t = CGFloat((time - 16) / 3)
            let day = UIColor(red: 0.45, green: 0.7, blue: 0.92, alpha: 1.0)
            let dusk = UIColor(red: 0.92, green: 0.55, blue: 0.38, alpha: 1.0)
            targetColor = interpolateColor(from: day, to: dusk, progress: t)
        } else if time >= 19 && time < 21 { // Crepuscule -> Nuit
            let t = CGFloat((time - 19) / 2)
            let dusk = UIColor(red: 0.92, green: 0.55, blue: 0.38, alpha: 1.0)
            let night = UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1.0)
            targetColor = interpolateColor(from: dusk, to: night, progress: t)
        } else { // Nuit (Bleu nuit profond et doux)
            targetColor = UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1.0)
        }
        
        if let currentColor = self.background.contents as? UIColor {
            let newColor = interpolateColor(from: currentColor, to: targetColor, progress: 0.08)
            self.background.contents = newColor
            self.fogColor = newColor
        } else {
            self.background.contents = targetColor
            self.fogColor = targetColor
        }
        
        // Ajuster l'intensité de l'HDRI selon l'heure
        var envIntensity: CGFloat = 0.45
        if time >= 6 && time < 9 {
            envIntensity = 0.2 + 0.25 * CGFloat((time - 6) / 3)
        } else if time >= 9 && time < 16 {
            envIntensity = 0.45
        } else if time >= 16 && time < 19 {
            envIntensity = 0.45 - 0.3 * CGFloat((time - 16) / 3)
        } else {
            envIntensity = 0.08 // Nuit très douce
        }
        self.lightingEnvironment.intensity = envIntensity
        
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
