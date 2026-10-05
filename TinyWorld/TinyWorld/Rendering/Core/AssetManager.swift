import SceneKit
import UIKit

class AssetManager {
    static let shared = AssetManager()
    
    private var cache: [String: SCNNode] = [:]
    
    var characterScene: SCNScene?
    
    init() {
    }
    
    func getModel(named name: String, folder: String) -> SCNNode {
        let key = "\(folder)/\(name)"
        if let cached = cache[key] {
            return cached.clone()
        }
        
        let extensions = ["obj", "fbx", "scn", "dae"]
        var loadedScene: SCNScene? = nil
        var finalExt = ""
        
        for ext in extensions {
            if let scene = SCNScene(named: "art.scnassets/\(key).\(ext)") {
                loadedScene = scene
                finalExt = ext
                break
            }
        }
        
        guard let scene = loadedScene else {
            print("WARNING: Could not load \(key) with any known extension")
            let fallback = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
            fallback.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            return fallback
        }
        
        let node = SCNNode()
        for child in scene.rootNode.childNodes {
            node.addChildNode(child.clone())
        }
        
        // Copy animations if it's an FBX or DAE
        if finalExt == "fbx" || finalExt == "dae" || finalExt == "scn" {
            for animKey in scene.rootNode.animationKeys {
                if let player = scene.rootNode.animationPlayer(forKey: animKey) {
                    node.addAnimationPlayer(player, forKey: animKey)
                }
            }
        }
        
        // Only flatten OBJ files. FBX characters have skeletons and multiple nodes that MUST NOT be flattened!
        if finalExt == "obj" {
            let flattened = node.flattenedClone()
            flattened.name = name
            flattened.castsShadow = true
            cache[key] = flattened
            return flattened.clone()
        } else {
            node.name = name
            node.castsShadow = true
            // Cast shadows for all children
            node.enumerateChildNodes { (child, _) in
                child.castsShadow = true
            }
            cache[key] = node
            return node.clone()
        }
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
