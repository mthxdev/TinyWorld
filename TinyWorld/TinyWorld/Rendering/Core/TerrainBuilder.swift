import SceneKit
import UIKit

class TerrainBuilder {
    static func getHeight(at px: Float, z pz: Float) -> Float {
        let h1 = sin(px * 0.2) * cos(pz * 0.2) * 0.5
        let h2 = sin(px * 0.5 + 1.2) * sin(pz * 0.4 + 0.5) * 0.2
        let h3 = cos(px * 0.1) * sin(pz * 0.1) * 1.5
        
        let distToCenter = sqrt(px*px + pz*pz)
        var height = h1 + h2 + h3
        if distToCenter < 10.0 {
            let blend = distToCenter / 10.0
            height = height * blend
        }
        return height
    }

    static func createTerrain(width: Float, depth: Float, subdivisions: Int) -> SCNNode {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []
        var uvs: [CGPoint] = []
        
        let dx = width / Float(subdivisions)
        let dz = depth / Float(subdivisions)
        
        let offsetX = -width / 2.0
        let offsetZ = -depth / 2.0
        
        // Generate heightmap
        var heights = [[Float]](repeating: [Float](repeating: 0, count: subdivisions + 1), count: subdivisions + 1)
        
        for z in 0...subdivisions {
            for x in 0...subdivisions {
                let px = offsetX + Float(x) * dx
                let pz = offsetZ + Float(z) * dz
                heights[z][x] = getHeight(at: px, z: pz)
            }
        }
        
        // Build vertices
        for z in 0...subdivisions {
            for x in 0...subdivisions {
                let px = offsetX + Float(x) * dx
                let pz = offsetZ + Float(z) * dz
                let py = heights[z][x]
                
                vertices.append(SCNVector3(px, py, pz))
                uvs.append(CGPoint(x: CGFloat(x) / CGFloat(subdivisions), y: CGFloat(z) / CGFloat(subdivisions)))
                
                // Approximate normal
                var hL = py; var hR = py; var hD = py; var hU = py
                if x > 0 { hL = heights[z][x-1] }
                if x < subdivisions { hR = heights[z][x+1] }
                if z > 0 { hD = heights[z-1][x] }
                if z < subdivisions { hU = heights[z+1][x] }
                
                let nx = hL - hR
                let ny: Float = 2.0 * dx // simplified normal
                let nz = hD - hU
                let len = sqrt(nx*nx + ny*ny + nz*nz)
                
                normals.append(SCNVector3(nx/len, ny/len, nz/len))
            }
        }
        
        // Build indices
        for z in 0..<subdivisions {
            for x in 0..<subdivisions {
                let topLeft = Int32(z * (subdivisions + 1) + x)
                let topRight = topLeft + 1
                let bottomLeft = Int32((z + 1) * (subdivisions + 1) + x)
                let bottomRight = bottomLeft + 1
                
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
        
        let geo = SCNGeometry(sources: [srcPos, srcNorm, srcUV], elements: [element])
        
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.35, green: 0.65, blue: 0.30, alpha: 1.0)
        mat.lightingModel = .physicallyBased
        mat.roughness.contents = 0.8
        geo.materials = [mat]
        
        let node = SCNNode(geometry: geo)
        node.castsShadow = true
        return node
    }
}

