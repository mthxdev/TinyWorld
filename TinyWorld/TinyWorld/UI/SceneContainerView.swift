import SwiftUI
import SceneKit

struct SceneContainerView: UIViewRepresentable {
    let scene: GameScene
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.allowsCameraControl = false // On gere la camera nous-memes via GameScene
        view.showsStatistics = true
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        view.antialiasingMode = .multisampling4X
        
        // Configuration des gestes
        setupGestures(in: view)
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Mise a jour si necessaire
    }
    
    private func setupGestures(in view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: scene.cameraController, action: #selector(CameraController.handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: scene.cameraController, action: #selector(CameraController.handlePinch(_:)))
        
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(pinchGesture)
    }
}
