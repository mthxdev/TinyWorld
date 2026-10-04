import SceneKit
import UIKit

class BuildingBuilder {
    static let shared = BuildingBuilder()
    
    private let texGen = TextureGenerator.shared
    
    func buildHouse() -> SCNNode {
        let houseNode = SCNNode()
        
        // Murs en pierre
        let wallsGeo = SCNBox(width: 2.4, height: 1.8, length: 2.4, chamferRadius: 0.05)
        wallsGeo.firstMaterial?.diffuse.contents = texGen.getStoneTexture()
        wallsGeo.firstMaterial?.roughness.contents = NSNumber(value: 0.8)
        let walls = SCNNode(geometry: wallsGeo)
        walls.position.y = 0.9
        houseNode.addChildNode(walls)
        
        // Toit en tuiles
        let roofGeo = SCNPyramid(width: 2.8, height: 1.6, length: 2.8)
        roofGeo.firstMaterial?.diffuse.contents = texGen.getRoofTexture()
        roofGeo.firstMaterial?.roughness.contents = NSNumber(value: 0.9)
        let roof = SCNNode(geometry: roofGeo)
        roof.position.y = 1.8
        houseNode.addChildNode(roof)
        
        // Cheminée en pierre
        let chimneyGeo = SCNBox(width: 0.4, height: 1.2, length: 0.4, chamferRadius: 0.0)
        chimneyGeo.firstMaterial?.diffuse.contents = texGen.getStoneTexture()
        let chimney = SCNNode(geometry: chimneyGeo)
        chimney.position = SCNVector3(0.6, 2.2, -0.4)
        houseNode.addChildNode(chimney)
        
        // Porte en bois avec poignée
        let doorGeo = SCNBox(width: 0.7, height: 1.2, length: 0.1, chamferRadius: 0.02)
        doorGeo.firstMaterial?.diffuse.contents = texGen.getWoodTexture()
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(0, 0.6, 1.2)
        
        let knobGeo = SCNSphere(radius: 0.05)
        knobGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0)
        knobGeo.firstMaterial?.metalness.contents = NSNumber(value: 0.8)
        let knob = SCNNode(geometry: knobGeo)
        knob.position = SCNVector3(0.2, 0.0, 0.05)
        door.addChildNode(knob)
        houseNode.addChildNode(door)
        
        // Fenêtres avec cadre et vitres
        let windowPositions = [SCNVector3(-0.6, 1.0, 1.2), SCNVector3(1.2, 1.0, 0)]
        let windowRotations = [Float(0), Float.pi/2]
        
        for (i, pos) in windowPositions.enumerated() {
            let winNode = SCNNode()
            winNode.position = pos
            winNode.eulerAngles.y = windowRotations[i]
            
            // Cadre
            let frameGeo = SCNBox(width: 0.7, height: 0.7, length: 0.1, chamferRadius: 0.02)
            frameGeo.firstMaterial?.diffuse.contents = texGen.getWoodTexture()
            let frame = SCNNode(geometry: frameGeo)
            winNode.addChildNode(frame)
            
            // Vitre
            let glassGeo = SCNBox(width: 0.6, height: 0.6, length: 0.12, chamferRadius: 0)
            glassGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.9)
            glassGeo.firstMaterial?.metalness.contents = NSNumber(value: 0.5)
            glassGeo.firstMaterial?.roughness.contents = NSNumber(value: 0.1)
            let glass = SCNNode(geometry: glassGeo)
            winNode.addChildNode(glass)
            
            houseNode.addChildNode(winNode)
        }
        
        // Cloture de jardin (Picket fence)
        let fenceNode = SCNNode()
        let postGeo = SCNBox(width: 0.1, height: 0.6, length: 0.1, chamferRadius: 0)
        postGeo.firstMaterial?.diffuse.contents = texGen.getWoodTexture()
        
        // Placer les poteaux en carré de 5x5 autour de la maison
        for x in stride(from: -2.5, through: 2.5, by: 0.8) {
            for z in [-2.5, 2.5] {
                // Laisser un trou pour la porte
                if z == 2.5 && abs(x) < 0.9 { continue }
                let post = SCNNode(geometry: postGeo)
                post.position = SCNVector3(x, 0.3, z)
                fenceNode.addChildNode(post)
            }
        }
        for z in stride(from: -2.5, through: 2.5, by: 0.8) {
            for x in [-2.5, 2.5] {
                let post = SCNNode(geometry: postGeo)
                post.position = SCNVector3(x, 0.3, Float(z))
                fenceNode.addChildNode(post)
            }
        }
        houseNode.addChildNode(fenceNode)
        
        return houseNode.flattenedClone()
    }
    
    func buildFarm() -> SCNNode {
        let farmNode = SCNNode()
        
        // Grange rouge
        let barnGeo = SCNBox(width: 4.0, height: 2.2, length: 3.0, chamferRadius: 0.05)
        barnGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0) // Peinture rouge
        barnGeo.firstMaterial?.roughness.contents = NSNumber(value: 0.9)
        let barn = SCNNode(geometry: barnGeo)
        barn.position.y = 1.1
        farmNode.addChildNode(barn)
        
        // Toit classique de grange (gambrel)
        // Simplifie : toit pointu débordant
        let bRoofGeo = SCNPyramid(width: 4.4, height: 1.8, length: 3.4)
        bRoofGeo.firstMaterial?.diffuse.contents = texGen.getRoofTexture()
        let bRoof = SCNNode(geometry: bRoofGeo)
        bRoof.position.y = 2.2
        farmNode.addChildNode(bRoof)
        
        // Grande porte
        let doorGeo = SCNBox(width: 1.5, height: 1.8, length: 0.1, chamferRadius: 0.0)
        doorGeo.firstMaterial?.diffuse.contents = texGen.getWoodTexture()
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(0, 0.9, 1.51)
        
        // Croix blanche sur la porte
        let crossGeo1 = SCNBox(width: 0.1, height: 2.2, length: 0.12, chamferRadius: 0.0)
        crossGeo1.firstMaterial?.diffuse.contents = UIColor.white
        let cross1 = SCNNode(geometry: crossGeo1)
        cross1.eulerAngles.z = Float.pi / 4
        door.addChildNode(cross1)
        let cross2 = SCNNode(geometry: crossGeo1)
        cross2.eulerAngles.z = -Float.pi / 4
        door.addChildNode(cross2)
        
        farmNode.addChildNode(door)
        
        // Champs labourés
        let fieldGeo = SCNBox(width: 5.0, height: 0.1, length: 4.0, chamferRadius: 0)
        fieldGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        let field = SCNNode(geometry: fieldGeo)
        field.position = SCNVector3(4.5, 0.05, 0)
        
        // Lignes de cultures
        let cropGeo = SCNBox(width: 4.8, height: 0.15, length: 0.2, chamferRadius: 0)
        cropGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        for z in stride(from: -1.5, through: 1.5, by: 0.5) {
            let crop = SCNNode(geometry: cropGeo)
            crop.position = SCNVector3(0, 0.05, Float(z))
            field.addChildNode(crop)
        }
        
        farmNode.addChildNode(field)
        return farmNode.flattenedClone()
    }
    
    func buildTree(tall: Bool = false) -> SCNNode {
        let tree = SCNNode()
        let trunkH = tall ? Float.random(in: 1.5...2.2) : Float.random(in: 0.8...1.2)
        let trunkGeo = SCNCylinder(radius: 0.2, height: CGFloat(trunkH))
        trunkGeo.firstMaterial?.diffuse.contents = texGen.getWoodTexture()
        let trunk = SCNNode(geometry: trunkGeo)
        trunk.position.y = trunkH / 2
        tree.addChildNode(trunk)
        
        // Couronne de feuilles (plusieurs spheres)
        let leavesMat = SCNMaterial()
        leavesMat.diffuse.contents = texGen.getGrassTexture() // Reutiliser pour les feuilles
        
        let centerLeaves = SCNSphere(radius: CGFloat(tall ? 1.4 : 1.0))
        centerLeaves.firstMaterial = leavesMat
        let cNode = SCNNode(geometry: centerLeaves)
        cNode.position.y = trunkH + (tall ? 0.6 : 0.4)
        tree.addChildNode(cNode)
        
        let sideLeaves = SCNSphere(radius: CGFloat(tall ? 0.9 : 0.6))
        sideLeaves.firstMaterial = leavesMat
        let sNode1 = SCNNode(geometry: sideLeaves)
        sNode1.position = SCNVector3(0.6, trunkH + 0.2, 0)
        tree.addChildNode(sNode1)
        
        let sNode2 = SCNNode(geometry: sideLeaves)
        sNode2.position = SCNVector3(-0.6, trunkH + 0.2, 0)
        tree.addChildNode(sNode2)
        
        return tree.flattenedClone()
    }
}
