import SceneKit
import Foundation

class TerrainBuilder {
    static func createTerrain(width: Float, depth: Float, subdivisions: Int) -> SCNNode {
        let root = SCNNode()
        root.name = "terrain_root"
        
        let gridSize = subdivisions
        let tileSize: Float = 1.0 // Kenney tiles are 1x1
        
        let offsetX = -Float(gridSize) * tileSize / 2.0
        let offsetZ = -Float(gridSize) * tileSize / 2.0
        
        // Create a gorgeous floating island diorama
        for z in 0..<gridSize {
            for x in 0..<gridSize {
                let px = offsetX + Float(x) * tileSize + tileSize / 2.0
                let pz = offsetZ + Float(z) * tileSize + tileSize / 2.0
                
                let distToCenter = hypot(px, pz)
                let maxRadius: Float = Float(gridSize) * tileSize / 2.0 - 2.0
                
                // Floating island shape: omit tiles outside maxRadius
                // Use a little noise for organic border
                let organicRadius = maxRadius - (sin(px * 1.5) * cos(pz * 1.5) * 1.5)
                if distToCenter > organicRadius {
                    continue
                }
                
                let modelName = "ground_grass"
                
                // Base grass tile
                let tile = AssetManager.shared.getModel(named: modelName, folder: "nature").flattenedClone()
                tile.position = SCNVector3(px, 0, pz)
                root.addChildNode(tile)
                
                // Add natural elevations using cliff blocks
                // Elevate borders slightly, or add hills
                if distToCenter > organicRadius - 3.0 && Float.random(in: 0...1) > 0.6 {
                    let cliff = AssetManager.shared.getModel(named: "cliff_block_stone", folder: "nature").flattenedClone()
                    cliff.position = SCNVector3(px, 0.5, pz)
                    root.addChildNode(cliff)
                    
                    let grassTop = AssetManager.shared.getModel(named: "ground_grass", folder: "nature").flattenedClone()
                    grassTop.position = SCNVector3(px, 1.0, pz)
                    root.addChildNode(grassTop)
                    
                    // Sometimes add a second level
                    if Float.random(in: 0...1) > 0.8 {
                        let cliff2 = AssetManager.shared.getModel(named: "cliff_block_stone", folder: "nature").flattenedClone()
                        cliff2.position = SCNVector3(px, 1.5, pz)
                        root.addChildNode(cliff2)
                        
                        let grassTop2 = AssetManager.shared.getModel(named: "ground_grass", folder: "nature").flattenedClone()
                        grassTop2.position = SCNVector3(px, 2.0, pz)
                        root.addChildNode(grassTop2)
                    }
                }
            }
        }
        
        // Add a nice thick dirt base to the island to give it volume (like a diorama block)
        let baseGeo = SCNBox(width: CGFloat(gridSize), height: 4.0, length: CGFloat(gridSize), chamferRadius: 1.0)
        baseGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        let baseNode = SCNNode(geometry: baseGeo)
        baseNode.position = SCNVector3(0, -2.01, 0)
        // root.addChildNode(baseNode) // Optional: a smooth base
        
        // Flatten for performance
        let flattened = root.flattenedClone()
        return flattened
    }
    
    static func getHeight(at px: Float, z pz: Float) -> Float {
        // Tile map is flat at Y=0 for gameplay area, elevated at borders
        // For gameplay, inhabitants just walk at Y=0
        return 0.0
    }
}

