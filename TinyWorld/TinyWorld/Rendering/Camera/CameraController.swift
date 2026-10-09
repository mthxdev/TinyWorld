import SceneKit
import UIKit

class CameraController {
    let pivotNode: SCNNode
    let cameraNode: SCNNode
    private let camera: SCNCamera
    
    private var lastPanLocation: CGPoint = .zero
    
    init(scene: SCNScene) {
        // Pivot placé au sol
        pivotNode = SCNNode()
        pivotNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(pivotNode)
        
        // Caméra inclinée attachée au pivot
        camera = SCNCamera()
        camera.zNear = 1.0
        camera.zFar = 120.0
        camera.fieldOfView = 48.0 // Cadrage équilibré pour que l'île remplisse bien l'écran
        cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Inclinaison de ~41 degrés, distance optimisée pour admirer les habitants et bâtiments
        cameraNode.position = SCNVector3(x: 0, y: 15.0, z: 16.5)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 4.4, y: 0, z: 0)
        pivotNode.addChildNode(cameraNode)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        // On translate le pivot sur le sol (X et Z)
        let panSpeed: Float = 0.04
        pivotNode.position.x -= Float(translation.x) * panSpeed
        pivotNode.position.z -= Float(translation.y) * panSpeed
        
        // Garder l'île toujours dans le champ de vision
        pivotNode.position.x = max(-16.0, min(16.0, pivotNode.position.x))
        pivotNode.position.z = max(-16.0, min(16.0, pivotNode.position.z))
        
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let zoomSpeed: Float = 2.0
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            var fov = camera.fieldOfView
            
            // Le pinch out (scale > 1) = zoom in = fov diminue
            if scale > 1.0 {
                fov -= CGFloat(zoomSpeed)
            } else {
                fov += CGFloat(zoomSpeed)
            }
            
            // Limites du zoom : gros plan intimiste (24°) jusqu'à vue d'ensemble de l'île (72°)
            fov = max(24, min(fov, 72))
            camera.fieldOfView = fov
            
            gesture.scale = 1.0
        }
    }
}
