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
        camera.zNear = 0.3
        camera.zFar = 200.0
        camera.fieldOfView = 52.0 // Slightly wider for better island view
        camera.wantsHDR = true // Enable HDR for better lighting
        camera.exposureOffset = 0.2 // Subtle exposure boost for stylized look
        cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Inclinaison de ~38 degrés, distance optimisée pour admirer les habitants et bâtiments
        cameraNode.position = SCNVector3(x: 0, y: 12.5, z: 13.5)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 4.7, y: 0, z: 0)
        pivotNode.addChildNode(cameraNode)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        // On translate le pivot sur le sol (X et Z)
        let panSpeed: Float = 0.03
        pivotNode.position.x -= Float(translation.x) * panSpeed
        pivotNode.position.z -= Float(translation.y) * panSpeed
        
        // Garder l'île toujours dans le champ de vision
        pivotNode.position.x = max(-20.0, min(20.0, pivotNode.position.x))
        pivotNode.position.z = max(-20.0, min(20.0, pivotNode.position.z))
        
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let zoomSpeed: Float = 1.6
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            var fov = camera.fieldOfView
            
            // Le pinch out (scale > 1) = zoom in = fov diminue
            if scale > 1.0 {
                fov -= CGFloat(zoomSpeed)
            } else {
                fov += CGFloat(zoomSpeed)
            }
            
            // Limites du zoom : gros plan intimiste (20°) jusqu'à vue d'ensemble de l'île (80°)
            fov = max(20, min(fov, 80))
            camera.fieldOfView = fov
            
            gesture.scale = 1.0
        }
    }
}
