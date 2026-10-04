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
        dirLight.intensity = 1500
        dirLight.castsShadow = true
        directionalLightNode = SCNNode()
        directionalLightNode.light = dirLight
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: Float.pi/4, z: 0)
        
        // Lumiere ambiante
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
            let zoneNode = SCNNode()
            zoneNode.position = SCNVector3(zone.centerX, 0, zone.centerZ)
            
            switch zone.type {
            case .home:
                // Maison : cube + toit pyramide
                let base = SCNBox(width: 2.0, height: 1.5, length: 2.0, chamferRadius: 0.1)
                base.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1.0)
                let baseNode = SCNNode(geometry: base)
                baseNode.position.y = 0.75
                zoneNode.addChildNode(baseNode)
                
                let roof = SCNPyramid(width: 2.2, height: 1.0, length: 2.2)
                roof.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
                let roofNode = SCNNode(geometry: roof)
                roofNode.position.y = 1.5
                zoneNode.addChildNode(roofNode)
                
            case .work:
                // Bureau/Usine : gros bloc rectangulaire
                let factory = SCNBox(width: 3.5, height: 2.0, length: 2.5, chamferRadius: 0.1)
                factory.firstMaterial?.diffuse.contents = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                let factoryNode = SCNNode(geometry: factory)
                factoryNode.position.y = 1.0
                zoneNode.addChildNode(factoryNode)
                
            case .food:
                // Stand de nourriture / Restaurant (cylindre ou box)
                let shop = SCNBox(width: 2.0, height: 1.2, length: 2.0, chamferRadius: 0.2)
                shop.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
                let shopNode = SCNNode(geometry: shop)
                shopNode.position.y = 0.6
                zoneNode.addChildNode(shopNode)
                
            case .park:
                // Parc avec arbres
                for _ in 0..<3 {
                    let treeNode = SCNNode()
                    let trunk = SCNCylinder(radius: 0.2, height: 1.0)
                    trunk.firstMaterial?.diffuse.contents = UIColor.brown
                    let trunkNode = SCNNode(geometry: trunk)
                    trunkNode.position.y = 0.5
                    
                    let leaves = SCNSphere(radius: 0.8)
                    leaves.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0)
                    let leavesNode = SCNNode(geometry: leaves)
                    leavesNode.position.y = 1.2
                    
                    treeNode.addChildNode(trunkNode)
                    treeNode.addChildNode(leavesNode)
                    treeNode.position = SCNVector3(Float.random(in: -1.5...1.5), 0, Float.random(in: -1.5...1.5))
                    zoneNode.addChildNode(treeNode)
                }
            }
            
            // Sol indicateur
            let basePlate = SCNCylinder(radius: CGFloat(zone.radius), height: 0.01)
            basePlate.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.1)
            let plateNode = SCNNode(geometry: basePlate)
            plateNode.position.y = 0.005
            zoneNode.addChildNode(plateNode)
            
            addChildNode(zoneNode)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTimeOfDay(_ time: Float) {
        let isDay = time > 6 && time < 18
        let targetIntensity: CGFloat = isDay ? 1500 : 200
        let currentIntensity = directionalLightNode.light?.intensity ?? 1500
        directionalLightNode.light?.intensity = currentIntensity + (targetIntensity - currentIntensity) * 0.05
    }
}
