import SceneKit
import UIKit

class TerrainBuilder {
    static let islandRadius: Float = 16.0
    
    static func getHeight(at px: Float, z pz: Float) -> Float {
        // Organic rolling hills
        let h1 = sin(px * 0.2 + 1.5) * cos(pz * 0.25) * 0.8
        let h2 = sin(px * 0.4) * sin(pz * 0.3 + 2.0) * 0.3
        let h3 = cos(px * 0.8) * cos(pz * 0.7) * 0.1
        
        var height = h1 + h2 + h3
        
        let dist = hypot(px, pz)
        if dist < 6.0 {
            height *= (dist / 6.0)
        }
        
        if dist > islandRadius - 3.0 {
            let drop = (dist - (islandRadius - 3.0)) * 0.5
            height -= drop * drop
        }
        
        return height
    }

    static func getPathIntensity(at px: Float, z pz: Float) -> Float {
        // Center plaza is pure dirt
        let dist = hypot(px, pz)
        if dist < 4.0 {
            let fade = max(0.0, 1.0 - (dist - 2.5)/1.5)
            return fade
        }
        
        // Organic dirt patches scattered across the grass
        let n1 = sin(px * 0.7) * cos(pz * 0.5)
        let n2 = cos(px * 1.3 + 2.0) * sin(pz * 1.1)
        var intensity = (n1 + n2) * 0.5
        
        // Only keep the peaks of the noise so we get patches of dirt
        intensity = (intensity - 0.3) * 2.5
        
        return min(1.0, max(0.0, intensity))
    }

    static func createTerrain(width: Float, depth: Float, subdivisions: Int) -> SCNNode {
        let root = SCNNode()
        root.name = "terrain_root"
        
        // Ensure minimum resolution for a beautiful mesh
        let actualSubdivisions = max(subdivisions, 120)
        let size: Float = 32.0
        let dx = size / Float(actualSubdivisions)
        
        let offsetX = -size / 2.0
        let offsetZ = -size / 2.0
        
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []
        var indices: [Int32] = []
        var grassColors: [Float] = [] // RGBA
        var dirtColors: [Float] = [] // RGBA
        
        for z in 0...actualSubdivisions {
            for x in 0...actualSubdivisions {
                let px = offsetX + Float(x) * dx
                let pz = offsetZ + Float(z) * dx
                
                let dist = hypot(px, pz)
                if dist > islandRadius + 1.0 {
                    vertices.append(SCNVector3(px, -10.0, pz))
                    uvs.append(CGPoint(x: CGFloat(px), y: CGFloat(pz)))
                    normals.append(SCNVector3(0, 1, 0))
                    grassColors.append(contentsOf: [1,1,1,0])
                    dirtColors.append(contentsOf: [1,1,1,0])
                    continue
                }
                
                let py = getHeight(at: px, z: pz)
                vertices.append(SCNVector3(px, py, pz))
                // Scale UVs so texture doesn't stretch too much
                uvs.append(CGPoint(x: CGFloat(px * 0.5), y: CGFloat(pz * 0.5)))
                
                let intensity = getPathIntensity(at: px, z: pz)
                
                grassColors.append(contentsOf: [1, 1, 1, 1])
                // Dirt color alpha blends
                dirtColors.append(contentsOf: [1, 1, 1, intensity])
                
                let eps: Float = 0.1
                let hR = getHeight(at: px + eps, z: pz)
                let hL = getHeight(at: px - eps, z: pz)
                let hU = getHeight(at: px, z: pz + eps)
                let hD = getHeight(at: px, z: pz - eps)
                
                let nx = hL - hR
                let ny = 2.0 * eps
                let nz = hD - hU
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
                if hypot(px, pz) > islandRadius { continue }
                
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
        
        let grassColorData = Data(bytes: grassColors, count: grassColors.count * MemoryLayout<Float>.size)
        let srcGrassColor = SCNGeometrySource(data: grassColorData, semantic: .color, vectorCount: grassColors.count / 4, usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<Float>.size * 4)
        
        let dirtColorData = Data(bytes: dirtColors, count: dirtColors.count * MemoryLayout<Float>.size)
        let srcDirtColor = SCNGeometrySource(data: dirtColorData, semantic: .color, vectorCount: dirtColors.count / 4, usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<Float>.size * 4)
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        // GRASS LAYER
        let grassGeo = SCNGeometry(sources: [srcPos, srcNorm, srcUV, srcGrassColor], elements: [element])
        let grassMat = SCNMaterial()
        grassMat.lightingModel = .physicallyBased
        grassMat.diffuse.contents = "art.scnassets/textures/leafy_grass/diffuse.jpg"
        grassMat.normal.contents = "art.scnassets/textures/leafy_grass/normal.jpg"
        grassMat.roughness.contents = "art.scnassets/textures/leafy_grass/roughness.jpg"
        grassMat.diffuse.wrapS = .repeat
        grassMat.diffuse.wrapT = .repeat
        grassMat.normal.wrapS = .repeat
        grassMat.normal.wrapT = .repeat
        grassMat.roughness.wrapS = .repeat
        grassMat.roughness.wrapT = .repeat
        grassGeo.materials = [grassMat]
        
        let grassNode = SCNNode(geometry: grassGeo)
        grassNode.castsShadow = true
        root.addChildNode(grassNode)
        
        // DIRT LAYER
        var dirtVertices = vertices
        for i in 0..<dirtVertices.count {
            dirtVertices[i].y += 0.005 // Minimal elevation
        }
        let srcDirtPos = SCNGeometrySource(vertices: dirtVertices)
        let dirtGeo = SCNGeometry(sources: [srcDirtPos, srcNorm, srcUV, srcDirtColor], elements: [element])
        let dirtMat = SCNMaterial()
        dirtMat.lightingModel = .physicallyBased
        dirtMat.diffuse.contents = "art.scnassets/textures/dirt/diffuse.jpg"
        dirtMat.normal.contents = "art.scnassets/textures/dirt/normal.jpg"
        dirtMat.roughness.contents = "art.scnassets/textures/dirt/roughness.jpg"
        dirtMat.diffuse.wrapS = .repeat
        dirtMat.diffuse.wrapT = .repeat
        dirtMat.normal.wrapS = .repeat
        dirtMat.normal.wrapT = .repeat
        dirtMat.roughness.wrapS = .repeat
        dirtMat.roughness.wrapT = .repeat
        dirtMat.isDoubleSided = false
        dirtMat.blendMode = .alpha
        dirtMat.writesToDepthBuffer = false // PREVENT Z-FIGHTING (Fix "deux grandes zones de couleurs")
        dirtGeo.materials = [dirtMat]
        
        let dirtNode = SCNNode(geometry: dirtGeo)
        dirtNode.castsShadow = false
        dirtNode.renderingOrder = 10 // Render after grass
        root.addChildNode(dirtNode)
        
        // Base of the island (dirt cylinder)
        let baseGeo = SCNCylinder(radius: CGFloat(islandRadius - 0.5), height: 4.0)
        let baseMat = SCNMaterial()
        baseMat.lightingModel = .physicallyBased
        baseMat.diffuse.contents = "art.scnassets/textures/dirt/diffuse.jpg"
        baseMat.normal.contents = "art.scnassets/textures/dirt/normal.jpg"
        baseMat.roughness.contents = "art.scnassets/textures/dirt/roughness.jpg"
        baseMat.diffuse.wrapS = .repeat
        baseMat.diffuse.wrapT = .repeat
        // Tiling adjustments for base cylinder
        baseMat.diffuse.contentsTransform = SCNMatrix4MakeScale(8, 2, 1)
        baseGeo.materials = [baseMat]
        let baseNode = SCNNode(geometry: baseGeo)
        baseNode.position = SCNVector3(0, -2.0 - 0.5, 0)
        root.addChildNode(baseNode)
        
        return root
    }
}

