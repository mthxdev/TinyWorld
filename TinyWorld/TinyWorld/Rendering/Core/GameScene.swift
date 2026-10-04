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
        // Synchroniser le temps et les batiments (evolution)
        environmentNode.sync(with: worldData)
        
        let isDay = worldData.timeOfDay > 6 && worldData.timeOfDay < 18
        let targetColor = isDay ? UIColor(red: 0.5, green: 0.8, blue: 0.9, alpha: 1.0) : UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 1.0)
        
        if let currentColor = self.background.contents as? UIColor {
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            currentColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            targetColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            let blended = UIColor(
                red: r1 + (r2 - r1) * 0.05,
                green: g1 + (g2 - g1) * 0.05,
                blue: b1 + (b2 - b1) * 0.05,
                alpha: 1.0
            )
            self.background.contents = blended
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
}
