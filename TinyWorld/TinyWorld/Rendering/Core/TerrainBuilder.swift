import SceneKit
import UIKit

class TerrainBuilder {
    static let islandRadius: Float = 16.0
    
    static func getHeight(at px: Float, z pz: Float) -> Float {
        // Organic rolling hills
        let h1 = sin(px * 0.2 + 1.5) * cos(pz * 0.25) * 0.75
        let h2 = sin(px * 0.4) * sin(pz * 0.3 + 2.0) * 0.25
        let h3 = cos(px * 0.8) * cos(pz * 0.7) * 0.08
        
        var height = h1 + h2 + h3
        
        let dist = hypot(px, pz)
        // Center plaza is kept relatively flat and welcoming for village life
        if dist < 5.0 {
            height *= max(0.25, (dist / 5.0))
        }
        
        // Gentle descent towards the shoreline and the sea
        if dist > 12.5 {
            let drop = (dist - 12.5) * 0.38
            height -= drop
        }
        
        // Underwater slope at the outer perimeter
        if dist > islandRadius - 0.5 {
            let edgeDrop = (dist - (islandRadius - 0.5)) * 1.2
            height -= edgeDrop * edgeDrop
        }
        
        return height
    }

    static func createTerrain(width: Float, depth: Float, subdivisions: Int) -> SCNNode {
        let root = SCNNode()
        root.name = "terrain_root"
        
        let actualSubdivisions = max(subdivisions, 100)
        let size: Float = 32.0
        let dx = size / Float(actualSubdivisions)
        
        let offsetX = -size / 2.0
        let offsetZ = -size / 2.0
        
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []
        var indices: [Int32] = []
        
        for z in 0...actualSubdivisions {
            for x in 0...actualSubdivisions {
                let px = offsetX + Float(x) * dx
                let pz = offsetZ + Float(z) * dx
                
                let dist = hypot(px, pz)
                if dist > islandRadius + 0.6 {
                    // Outer points drop safely underwater
                    vertices.append(SCNVector3(px, -2.5, pz))
                    let u = CGFloat((px - offsetX) / size)
                    let v = CGFloat((pz - offsetZ) / size)
                    uvs.append(CGPoint(x: u, y: v))
                    normals.append(SCNVector3(0, 1, 0))
                    continue
                }
                
                let py = getHeight(at: px, z: pz)
                vertices.append(SCNVector3(px, py, pz))
                
                // UVs map directly 1:1 onto our rich 2048x2048 island PBR texture
                let u = CGFloat((px - offsetX) / size)
                let v = CGFloat((pz - offsetZ) / size)
                uvs.append(CGPoint(x: u, y: v))
                
                // Normal calculation via finite differences
                let eps: Float = 0.15
                let hR = getHeight(at: px + eps, z: pz)
                let hL = getHeight(at: px - eps, z: pz)
                let hU = getHeight(at: px, z: pz + eps)
                let hD = getHeight(at: px, z: pz - eps)
                
                let nx = (hL - hR)
                let ny = 2.0 * eps
                let nz = (hD - hU)
                let len = sqrt(nx*nx + ny*ny + nz*nz)
                
                normals.append(SCNVector3(nx/len, ny/len, nz/len))
            }
        }
        
        for z in 0..<actualSubdivisions {
            for x in 0..<actualSubdivisions {
                let topLeft = Int32(z * (actualSubdivisions + 1) + x)
                let topRight = topLeft + 1
                let bottomLeft = Int32((z + 1) * (actualSubdivisions + 1) + x)
                let bottomRight = bottomLeft + 1
                
                let px = offsetX + Float(x) * dx
                let pz = offsetZ + Float(z) * dx
                if hypot(px, pz) > islandRadius + 0.3 { continue }
                
                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }
        
        let srcPos = SCNGeometrySource(vertices: vertices)
        let srcNorm = SCNGeometrySource(normals: normals)
        let srcUV = SCNGeometrySource(textureCoordinates: uvs)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        // UNIFIED SOLID TERRAIN (No duplicate layers, NO Z-fighting, NO angle color shifts!)
        let terrainGeo = SCNGeometry(sources: [srcPos, srcNorm, srcUV], elements: [element])
        let terrainMat = SCNMaterial()
        terrainMat.lightingModel = .physicallyBased
        terrainMat.diffuse.contents = "art.scnassets/textures/island_diffuse.jpg"
        terrainMat.normal.contents = "art.scnassets/textures/island_normal.png"
        terrainMat.roughness.contents = "art.scnassets/textures/island_roughness.png"
        terrainMat.diffuse.magnificationFilter = .linear
        terrainMat.diffuse.minificationFilter = .linear
        terrainMat.normal.magnificationFilter = .linear
        terrainMat.normal.minificationFilter = .linear
        terrainMat.roughness.magnificationFilter = .linear
        terrainMat.roughness.minificationFilter = .linear
        terrainMat.isDoubleSided = false
        terrainGeo.materials = [terrainMat]
        
        let terrainNode = SCNNode(geometry: terrainGeo)
        terrainNode.castsShadow = true
        root.addChildNode(terrainNode)
        
        // Underwater rock base: tapered and fully below the opaque water surface.
        let baseGeo = SCNCone(
            topRadius: CGFloat(islandRadius - 1.2),
            bottomRadius: CGFloat(islandRadius - 0.2),
            height: 3.0
        )
        let baseMat = SCNMaterial()
        baseMat.lightingModel = .physicallyBased
        baseMat.diffuse.contents = UIColor(red: 0.35, green: 0.30, blue: 0.25, alpha: 1.0)
        baseMat.roughness.contents = NSNumber(value: 0.9)
        baseGeo.materials = [baseMat]
        let baseNode = SCNNode(geometry: baseGeo)
        baseNode.position = SCNVector3(0, -1.85, 0)
        root.addChildNode(baseNode)
        
        return root
    }
}
