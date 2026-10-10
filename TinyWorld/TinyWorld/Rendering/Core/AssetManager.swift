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
            // Upgrade materials to PBR for stylized realistic look
            node.enumerateChildNodes { (child, _) in
                if let geo = child.geometry {
                    for mat in geo.materials {
                        mat.lightingModel = .physicallyBased
                        
                        // Folder-specific material tuning
                        if folder == "nature" {
                            // Nature assets: vegetation, rocks, props
                            if mat.name?.lowercased().contains("leaf") == true ||
                               mat.name?.lowercased().contains("foliage") == true ||
                               mat.name?.lowercased().contains("tree") == true ||
                               mat.name?.lowercased().contains("pine") == true ||
                               mat.name?.lowercased().contains("bush") == true ||
                               mat.name?.lowercased().contains("plant") == true ||
                               mat.name?.lowercased().contains("grass") == true {
                                // Foliage: slightly transparent, rough, non-metallic
                                mat.roughness.contents = NSNumber(value: 0.9)
                                mat.metalness.contents = NSNumber(value: 0.0)
                                mat.transparency = 0.95
                                mat.transparencyMode = .aOne
                                mat.isDoubleSided = true
                            } else if mat.name?.lowercased().contains("rock") == true ||
                                      mat.name?.lowercased().contains("stone") == true ||
                                      mat.name?.lowercased().contains("boulder") == true {
                                // Rocks: rough, varied
                                mat.roughness.contents = NSNumber(value: 0.95)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            } else if mat.name?.lowercased().contains("trunk") == true ||
                                      mat.name?.lowercased().contains("bark") == true ||
                                      mat.name?.lowercased().contains("log") == true ||
                                      mat.name?.lowercased().contains("stump") == true ||
                                      mat.name?.lowercased().contains("branch") == true {
                                // Wood: rough, warm
                                mat.roughness.contents = NSNumber(value: 0.85)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            } else if mat.name?.lowercased().contains("flower") == true {
                                // Flowers: slightly glossy petals
                                mat.roughness.contents = NSNumber(value: 0.7)
                                mat.metalness.contents = NSNumber(value: 0.0)
                                mat.isDoubleSided = true
                            } else if mat.name?.lowercased().contains("mushroom") == true {
                                // Mushrooms: matte
                                mat.roughness.contents = NSNumber(value: 0.9)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            } else if mat.name?.lowercased().contains("water") == true ||
                                      mat.name?.lowercased().contains("river") == true ||
                                      mat.name?.lowercased().contains("lily") == true {
                                // Water plants: wet look
                                mat.roughness.contents = NSNumber(value: 0.3)
                                mat.metalness.contents = NSNumber(value: 0.1)
                            } else {
                                // Default nature props
                                mat.roughness.contents = NSNumber(value: 0.85)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            }
                        } else if folder == "suburban" {
                            // Buildings and suburban props: matte, slightly colorful
                            mat.roughness.contents = NSNumber(value: 0.78)
                            mat.metalness.contents = NSNumber(value: 0.02)
                            
                            // Boost color vibrancy slightly for stylized look
                            if let color = mat.diffuse.contents as? UIColor {
                                var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                                if color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
                                    mat.diffuse.contents = UIColor(hue: h, saturation: min(1.0, s * 1.12), brightness: min(1.0, b * 1.06), alpha: a)
                                }
                            }
                            
                            // Differentiate roof vs walls vs details by material name
                            let matName = mat.name?.lowercased() ?? ""
                            if matName.contains("roof") || matName.contains("tuile") || matName.contains("tile") {
                                // Roofs: slightly rougher, warmer terracotta tones
                                mat.roughness.contents = NSNumber(value: 0.85)
                                if let color = mat.diffuse.contents as? UIColor {
                                    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                                    if color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
                                        mat.diffuse.contents = UIColor(hue: 0.055, saturation: min(1.0, s * 1.25), brightness: min(1.0, b * 0.88), alpha: a)
                                    }
                                }
                            } else if matName.contains("wall") || matName.contains("facade") || matName.contains("exterior") || matName.contains("siding") {
                                // Walls: cleaner, slightly smoother
                                mat.roughness.contents = NSNumber(value: 0.72)
                            } else if matName.contains("window") || matName.contains("glass") || matName.contains("vitrage") || matName.contains("glazing") {
                                // Windows: reflective, smooth
                                mat.roughness.contents = NSNumber(value: 0.1)
                                mat.metalness.contents = NSNumber(value: 0.9)
                                mat.transparency = 0.25
                                mat.transparencyMode = .aOne
                            } else if matName.contains("door") || matName.contains("porte") {
                                // Doors: warm wood
                                mat.roughness.contents = NSNumber(value: 0.75)
                                if let color = mat.diffuse.contents as? UIColor {
                                    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                                    if color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
                                        mat.diffuse.contents = UIColor(hue: 0.075, saturation: min(1.0, s * 1.3), brightness: min(1.0, b * 0.85), alpha: a)
                                    }
                                }
                            } else if matName.contains("trim") || matName.contains("frame") || matName.contains("corner") || matName.contains("fascia") || matName.contains("soffit") {
                                // Trim/frames: slightly lighter
                                mat.roughness.contents = NSNumber(value: 0.8)
                                if let color = mat.diffuse.contents as? UIColor {
                                    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                                    if color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
                                        mat.diffuse.contents = UIColor(hue: h, saturation: max(0.0, s * 0.7), brightness: min(1.0, b * 1.15), alpha: a)
                                    }
                                }
                            } else if matName.contains("fence") {
                                // Fences: weathered wood
                                mat.roughness.contents = NSNumber(value: 0.9)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            } else if matName.contains("path") || matName.contains("stone") || matName.contains("driveway") {
                                // Paths: rough stone
                                mat.roughness.contents = NSNumber(value: 0.88)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            } else if matName.contains("planter") || matName.contains("pot") {
                                // Planters: terracotta/ceramic
                                mat.roughness.contents = NSNumber(value: 0.65)
                                mat.metalness.contents = NSNumber(value: 0.05)
                            } else if matName.contains("foundation") || matName.contains("base") {
                                // Foundation: dark rough concrete/stone
                                mat.roughness.contents = NSNumber(value: 0.92)
                                mat.metalness.contents = NSNumber(value: 0.0)
                            }
                        } else if folder == "character" {
                            // Character materials - handled separately in InhabitantNode
                            mat.roughness.contents = NSNumber(value: 0.7)
                            mat.metalness.contents = NSNumber(value: 0.05)
                        } else {
                            // Default PBR settings
                            mat.roughness.contents = NSNumber(value: 0.85)
                            mat.metalness.contents = NSNumber(value: 0.0)
                        }
                        
                        mat.roughness.intensity = 0.9
                    }
                }
            }
            
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
