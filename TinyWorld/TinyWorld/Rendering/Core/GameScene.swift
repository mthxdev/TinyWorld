import SceneKit

class GameScene: SCNScene {
    let cameraController: CameraController
    private var environmentNode: EnvironmentNode!
    private var inhabitantNodes: [UUID: InhabitantNode] = [:]
    
    override init() {
        self.cameraController = CameraController(scene: SCNScene()) // sera reaffecte ci-dessous
        super.init()
        
        // Initialisation de la caméra et du monde visuel
        self.cameraController.pivotNode.removeFromParentNode()
        self.rootNode.addChildNode(cameraController.pivotNode)
        
        self.environmentNode = EnvironmentNode(worldSize: 20.0)
        self.rootNode.addChildNode(environmentNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Méthode appelée par SwiftUI (ou un Timer de la Vue) pour synchroniser la scène avec l'état de la simulation.
    /// Note: GameScene ne connait pas "SimulationEngine", juste les datas, pour respecter l'architecture pure.
    func sync(with worldData: WorldData) {
        // 1. Mettre à jour le cycle jour/nuit
        environmentNode.updateTimeOfDay(worldData.timeOfDay)
        
        // 2. Mettre à jour (ou créer) les noeuds habitants
        for inhabitantData in worldData.inhabitants {
            if let node = inhabitantNodes[inhabitantData.id] {
                // Existe déjà, on met à jour
                node.sync(with: inhabitantData)
            } else {
                // Nouveau
                let newNode = InhabitantNode(id: inhabitantData.id)
                newNode.sync(with: inhabitantData)
                self.rootNode.addChildNode(newNode)
                inhabitantNodes[inhabitantData.id] = newNode
            }
        }
    }
}
