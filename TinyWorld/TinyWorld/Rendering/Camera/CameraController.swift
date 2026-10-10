import SceneKit
import UIKit

class CameraController {
    let pivotNode: SCNNode
    let cameraNode: SCNNode
    private let camera: SCNCamera
    
    private var lastPanLocation: CGPoint = .zero
    
    init(scene: SCNScene) {
        // Pivot placé au sol, légèrement décalé pour un cadrage plus intéressant
        pivotNode = SCNNode()
        pivotNode.position = SCNVector3(x: 0.5, y: 0, z: -1.0)
        scene.rootNode.addChildNode(pivotNode)
        
        // Caméra inclinée attachée au pivot
        camera = SCNCamera()
        camera.zNear = 0.3
        camera.zFar = 200.0
        camera.fieldOfView = 50.0 // Slightly narrower for more intimate feel
        camera.wantsHDR = true
        camera.exposureOffset = 0.15
        camera.wantsDepthOfField = true
        camera.focalDistance = 14.0
        camera.fStop = 2.8
        cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Inclinaison de ~40 degrés, distance optimisée pour admirer les détails
        cameraNode.position = SCNVector3(x: 0, y: 13.0, z: 14.5)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 4.5, y: 0, z: 0)
        pivotNode.addChildNode(cameraNode)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        // On translate le pivot sur le sol (X et Z)
        let panSpeed: Float = 0.028
        pivotNode.position.x -= Float(translation.x) * panSpeed
        pivotNode.position.z -= Float(translation.y) * panSpeed
        
        // Garder l'île toujours dans le champ de vision - slightly larger bounds
        pivotNode.position.x = max(-22.0, min(22.0, pivotNode.position.x))
        pivotNode.position.z = max(-22.0, min(22.0, pivotNode.position.z))
        
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let zoomSpeed: Float = 1.4
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            var fov = camera.fieldOfView
            
            // Le pinch out (scale > 1) = zoom in = fov diminue
            if scale > 1.0 {
                fov -= CGFloat(zoomSpeed)
            } else {
                fov += CGFloat(zoomSpeed)
            }
            
            // Limites du zoom : gros plan intimiste (18°) jusqu'à vue d'ensemble de l'île (85°)
            fov = max(18, min(fov, 85))
            camera.fieldOfView = fov
            
            // Adjust focal distance based on FOV for depth of field
            camera.focalDistance = CGFloat(14.0 * (50.0 / fov))
            
            gesture.scale = 1.0
        }
    }
}
