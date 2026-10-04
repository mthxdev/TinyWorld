import SceneKit

class EnvironmentNode: SCNNode {
    private var directionalLightNode: SCNNode
    private var ambientLightNode: SCNNode
    
    init(world: WorldData) {
        // Sol
        let groundGeometry = SCNPlane(width: CGFloat(world.size), height: CGFloat(world.size))
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
        
        // Affichage des zones
        for zone in world.zones {
            let zoneGeo = SCNCylinder(radius: CGFloat(zone.radius), height: 0.01)
            let color: UIColor
            switch zone.type {
            case .home: color = UIColor.blue.withAlphaComponent(0.3)
            case .work: color = UIColor.orange.withAlphaComponent(0.3)
            case .food: color = UIColor.red.withAlphaComponent(0.3)
            case .park: color = UIColor.green.withAlphaComponent(0.3)
            }
            zoneGeo.firstMaterial?.diffuse.contents = color
            let zoneNode = SCNNode(geometry: zoneGeo)
            zoneNode.position = SCNVector3(zone.centerX, 0.01, zone.centerZ)
            addChildNode(zoneNode)
        }
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
