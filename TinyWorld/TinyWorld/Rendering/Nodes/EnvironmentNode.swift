import SceneKit

class EnvironmentNode: SCNNode {
    private var directionalLightNode: SCNNode
    private var ambientLightNode: SCNNode
    
    init(worldSize: Float) {
        // Sol
        let groundGeometry = SCNPlane(width: CGFloat(worldSize), height: CGFloat(worldSize))
        groundGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.eulerAngles.x = -Float.pi / 2
        
        // Soleil
        let dirLight = SCNLight()
        dirLight.type = .directional
        dirLight.intensity = 1000
        dirLight.castsShadow = true
        directionalLightNode = SCNNode()
        directionalLightNode.light = dirLight
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: Float.pi/4, z: 0)
        
        // Lumière ambiante
        let ambLight = SCNLight()
        ambLight.type = .ambient
        ambLight.intensity = 200
        ambientLightNode = SCNNode()
        ambientLightNode.light = ambLight
        
        super.init()
        
        addChildNode(groundNode)
        addChildNode(directionalLightNode)
        addChildNode(ambientLightNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTimeOfDay(_ time: Float) {
        // timeOfDay de 0 à 24
        // A midi (12), intensité max. A minuit (0/24), intensité min.
        let isDay = time > 6 && time < 18
        
        let targetIntensity: CGFloat = isDay ? 1000 : 100
        let currentIntensity = directionalLightNode.light?.intensity ?? 1000
        
        // Interpolation simple (visuelle pure)
        directionalLightNode.light?.intensity = currentIntensity + (targetIntensity - currentIntensity) * 0.05
    }
}
