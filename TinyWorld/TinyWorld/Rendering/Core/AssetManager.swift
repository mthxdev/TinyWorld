import SceneKit

class AssetManager {
    static let shared = AssetManager()
    
    private var cache: [String: SCNNode] = [:]
    
    var characterScene: SCNScene?
    
    init() {
        characterScene = SCNScene(named: "art.scnassets/character/elf.dae")
    }
    
    func getModel(named name: String, folder: String) -> SCNNode {
        let key = "\(folder)/\(name)"
        if let cached = cache[key] {
            return cached.clone()
        }
        
        guard let scene = SCNScene(named: "art.scnassets/\(key).obj") else {
            print("WARNING: Could not load \(key).obj")
            let fallback = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
            fallback.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            return fallback
        }
        
        let node = SCNNode()
        for child in scene.rootNode.childNodes {
            node.addChildNode(child.clone())
        }
        
        // Optimiser
        let flattened = node.flattenedClone()
        flattened.name = name
        flattened.castsShadow = true
        for child in flattened.childNodes {
            child.castsShadow = true
        }
        cache[key] = flattened
        return flattened.clone()
    }
    
    func getCharacter() -> SCNNode? {
        guard let scene = characterScene else { return nil }
        
        let wrapper = SCNNode()
        for child in scene.rootNode.childNodes {
            wrapper.addChildNode(child.clone())
        }
        return wrapper
    }
}
