import SceneKit
import UIKit

class CameraController {
    let pivotNode: SCNNode
    let cameraNode: SCNNode
    private let camera: SCNCamera
    
    private var lastPanLocation: CGPoint = .zero
    
    init(scene: SCNScene) {
        // Pivot placed at ground level, centered on island for natural orbit
        pivotNode = SCNNode()
        pivotNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(pivotNode)
        
        // Camera attached to pivot
        camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 300.0
        camera.fieldOfView = 38.0 // Narrower FOV for cinematic framing, island fills screen
        camera.wantsHDR = true
        camera.exposureOffset = 0.15
        camera.wantsDepthOfField = true
        camera.focalDistance = 14.0
        camera.fStop = 2.0
        cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Tilt ~42 degrees, distance optimized for island composition
        // Camera positioned to frame island with minimal ocean, showing buildings/trees clearly
        cameraNode.position = SCNVector3(x: 0, y: 13.5, z: 15.5)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 4.3, y: 0, z: 0)
        pivotNode.addChildNode(cameraNode)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        // Translate the pivot on ground plane (X and Z)
        let panSpeed: Float = 0.022
        pivotNode.position.x -= Float(translation.x) * panSpeed
        pivotNode.position.z -= Float(translation.y) * panSpeed
        
        // Keep island always in view - bounds matching island radius + margin for composition
        pivotNode.position.x = max(-15.0, min(15.0, pivotNode.position.x))
        pivotNode.position.z = max(-15.0, min(15.0, pivotNode.position.z))
        
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let zoomSpeed: Float = 1.1
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            var fov = camera.fieldOfView
            
            // Pinch out (scale > 1) = zoom in = fov decreases
            if scale > 1.0 {
                fov -= CGFloat(zoomSpeed)
            } else {
                fov += CGFloat(zoomSpeed)
            }
            
            // Zoom limits: intimate closeup (14°) to island overview (65°)
            fov = max(14, min(fov, 65))
            camera.fieldOfView = fov
            
            // Adjust focal distance based on FOV for depth of field
            camera.focalDistance = CGFloat(14.0 * (38.0 / fov))
            
            gesture.scale = 1.0
        }
    }
}
