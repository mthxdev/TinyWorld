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
        self.fogStartDistance = 65.0
        self.fogEndDistance = 110.0
        self.fogDensityExponent = 1.0
        
        // Enable HDR for better PBR rendering
        self.background.contents = UIColor(red: 0.5, green: 0.72, blue: 0.94, alpha: 1.0)
        
        // Environnement HDRI pour le rendu PBR (Reflets et lumière ambiante réalistes)
        self.lightingEnvironment.contents = "art.scnassets/textures/sky.exr"
        self.lightingEnvironment.intensity = 0.5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func sync(with worldData: WorldData) {
        environmentNode.sync(with: worldData)
        
        let time = worldData.timeOfDay
        var targetColor = UIColor.black
        
        if time >= 5 && time < 8 { // Pre-dawn to sunrise
            let t = CGFloat((time - 5) / 3)
            let preDawn = UIColor(red: 0.18, green: 0.22, blue: 0.4, alpha: 1.0)
            let sunrise = UIColor(red: 0.98, green: 0.75, blue: 0.5, alpha: 1.0)
            targetColor = interpolateColor(from: preDawn, to: sunrise, progress: t)
        } else if time >= 8 && time < 10 { // Morning golden hour
            let t = CGFloat((time - 8) / 2)
            let sunrise = UIColor(red: 0.98, green: 0.75, blue: 0.5, alpha: 1.0)
            let morning = UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1.0)
            targetColor = interpolateColor(from: sunrise, to: morning, progress: t)
        } else if time >= 10 && time < 15 { // Midday
            targetColor = UIColor(red: 0.5, green: 0.72, blue: 0.94, alpha: 1.0)
        } else if time >= 15 && time < 17 { // Late afternoon
            let t = CGFloat((time - 15) / 2)
            let afternoon = UIColor(red: 0.5, green: 0.72, blue: 0.94, alpha: 1.0)
            let goldenHour = UIColor(red: 0.9, green: 0.65, blue: 0.45, alpha: 1.0)
            targetColor = interpolateColor(from: afternoon, to: goldenHour, progress: t)
        } else if time >= 17 && time < 19.5 { // Golden hour to sunset
            let t = CGFloat((time - 17) / 2.5)
            let goldenHour = UIColor(red: 0.9, green: 0.65, blue: 0.45, alpha: 1.0)
            let sunset = UIColor(red: 0.92, green: 0.48, blue: 0.32, alpha: 1.0)
            targetColor = interpolateColor(from: goldenHour, to: sunset, progress: t)
        } else if time >= 19.5 && time < 21.5 { // Twilight to night
            let t = CGFloat((time - 19.5) / 2)
            let sunset = UIColor(red: 0.92, green: 0.48, blue: 0.32, alpha: 1.0)
            let night = UIColor(red: 0.06, green: 0.1, blue: 0.22, alpha: 1.0)
            targetColor = interpolateColor(from: sunset, to: night, progress: t)
        } else { // Night
            targetColor = UIColor(red: 0.06, green: 0.1, blue: 0.22, alpha: 1.0)
        }
        
        if let currentColor = self.background.contents as? UIColor {
            let newColor = interpolateColor(from: currentColor, to: targetColor, progress: 0.06)
            self.background.contents = newColor
            self.fogColor = newColor
        } else {
            self.background.contents = targetColor
            self.fogColor = targetColor
        }
        
        // Adjust HDRI intensity by time of day
        var envIntensity: CGFloat = 0.5
        if time >= 5 && time < 8 {
            envIntensity = 0.15 + 0.35 * CGFloat((time - 5) / 3)
        } else if time >= 8 && time < 10 {
            envIntensity = 0.5
        } else if time >= 10 && time < 15 {
            envIntensity = 0.55
        } else if time >= 15 && time < 17 {
            envIntensity = 0.55 - 0.15 * CGFloat((time - 15) / 2)
        } else if time >= 17 && time < 19.5 {
            envIntensity = 0.4 - 0.3 * CGFloat((time - 17) / 2.5)
        } else if time >= 19.5 && time < 21.5 {
            envIntensity = 0.1 - 0.05 * CGFloat((time - 19.5) / 2)
        } else {
            envIntensity = 0.05
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
