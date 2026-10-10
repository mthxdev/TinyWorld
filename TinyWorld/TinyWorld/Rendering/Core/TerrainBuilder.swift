import SceneKit
import UIKit

class TerrainBuilder {
    static let islandRadius: Float = 16.0
    
    static func getHeight(at px: Float, z pz: Float) -> Float {
        let dist = hypot(px, pz)
        let angle = atan2(px, pz)
        
        // Base macro hills (4 octaves of fBm)
        let h1 = sin(px * 0.18 + 1.5) * cos(pz * 0.22) * 1.1
        let h2 = sin(px * 0.35) * sin(pz * 0.28 + 2.0) * 0.5
        let h3 = cos(px * 0.7) * cos(pz * 0.65) * 0.15
        let h4 = sin(px * 0.12 + 0.7) * cos(pz * 0.15 + 1.2) * 0.3
        
        // Additional medium-scale variation for natural ridges/valleys
        let h5 = sin(px * 0.5 + angle * 0.3) * cos(pz * 0.45 - angle * 0.2) * 0.25
        let h6 = cos(px * 0.28 + 1.8) * sin(pz * 0.32 + 0.5) * 0.18
        
        var height = h1 + h2 + h3 + h4 + h5 + h6
        
        // Center plaza - gentle mound rather than flat
        if dist < 5.0 {
            let centerMound = (1.0 - dist / 5.0) * 0.4
            height = height * max(0.3, (dist / 5.0)) + centerMound
        }
        
        // Biome-aware terrain shaping
        // Northwest: slightly elevated forested hills
        if px < -4.0 && pz < -4.0 {
            let biomeDist = hypot(px + 9.0, pz + 8.0)
            if biomeDist < 7.0 {
                height += (1.0 - biomeDist / 7.0) * 0.35
            }
        }
        // Northeast: rocky elevated terrain
        if px > 4.0 && pz < -4.0 {
            let biomeDist = hypot(px - 8.0, pz + 7.0)
            if biomeDist < 7.0 {
                height += (1.0 - biomeDist / 7.0) * 0.5
            }
        }
        // South: gentle meadow depression
        if pz > 6.0 {
            let biomeDist = hypot(px, pz - 10.0)
            if biomeDist < 8.0 {
                height -= (1.0 - biomeDist / 8.0) * 0.2
            }
        }
        
        // Gentle descent towards the shoreline
        if dist > 11.5 {
            let drop = (dist - 11.5) * 0.42
            height -= drop
        }
        
        // Beach/sand transition zone (slightly flattened)
        if dist > 13.0 && dist < 15.5 {
            let beachFactor = 1.0 - min(1.0, (dist - 13.0) / 2.5)
            height = height * (0.3 + beachFactor * 0.7) - 0.05
        }
        
        // Underwater slope at the outer perimeter
        if dist > islandRadius - 0.5 {
            let edgeDrop = (dist - (islandRadius - 0.5)) * 1.4
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
        // Better PBR settings for stylized terrain
        terrainMat.metalness.contents = NSNumber(value: 0.0)
        terrainMat.roughness.intensity = 0.85
        terrainMat.normal.intensity = 0.6 // Reduced for more natural look
        terrainMat.diffuse.magnificationFilter = .linear
        terrainMat.diffuse.minificationFilter = .linear
        terrainMat.diffuse.mipFilter = .linear
        terrainMat.normal.magnificationFilter = .linear
        terrainMat.normal.minificationFilter = .linear
        terrainMat.normal.mipFilter = .linear
        terrainMat.roughness.magnificationFilter = .linear
        terrainMat.roughness.minificationFilter = .linear
        terrainMat.roughness.mipFilter = .linear
        terrainMat.isDoubleSided = false
        terrainGeo.materials = [terrainMat]
        
        let terrainNode = SCNNode(geometry: terrainGeo)
        terrainNode.castsShadow = true
        root.addChildNode(terrainNode)
        
        // Underwater rock base: fully submerged below water surface.
        // Water level is at y = -0.32, so base must stay below that.
        // Use a flatter cone that follows the island contour better
        let baseGeo = SCNCone(
            topRadius: CGFloat(islandRadius - 0.5),
            bottomRadius: CGFloat(islandRadius + 1.0),
            height: 2.0
        )
        let baseMat = SCNMaterial()
        baseMat.lightingModel = .physicallyBased
        // Darker, cooler underwater rock color - less brown, more slate/grey
        baseMat.diffuse.contents = UIColor(red: 0.12, green: 0.16, blue: 0.20, alpha: 1.0)
        baseMat.roughness.contents = NSNumber(value: 0.95)
        baseMat.metalness.contents = NSNumber(value: 0.0)
        baseGeo.materials = [baseMat]
        let baseNode = SCNNode(geometry: baseGeo)
        // Position so top of cone is at y = -1.0 (well below water at -0.32)
        baseNode.position = SCNVector3(0, -2.0, 0)
        root.addChildNode(baseNode)
        
        return root
    }
}
