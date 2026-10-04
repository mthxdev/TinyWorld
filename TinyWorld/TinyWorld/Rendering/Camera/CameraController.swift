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
        camera.zFar = 100.0
        cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Inclinaison de 45 degrés, reculée
        cameraNode.position = SCNVector3(x: 0, y: 20, z: 20)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 4, y: 0, z: 0)
        pivotNode.addChildNode(cameraNode)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        // On translate le pivot sur le sol (X et Z)
        let panSpeed: Float = 0.05
        pivotNode.position.x -= Float(translation.x) * panSpeed
        pivotNode.position.z -= Float(translation.y) * panSpeed
        
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
            
            // Limites du zoom
            fov = max(20, min(fov, 90))
            camera.fieldOfView = fov
            
            gesture.scale = 1.0
        }
    }
}
