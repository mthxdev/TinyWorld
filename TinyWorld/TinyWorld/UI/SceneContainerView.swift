import SwiftUI
import SceneKit

struct SceneContainerView: UIViewRepresentable {
    let scene: GameScene
    let engine: SimulationEngine
    
    class Coordinator: NSObject {
        let engine: SimulationEngine
        let scene: GameScene
        
        init(engine: SimulationEngine, scene: GameScene) {
            self.engine = engine
            self.scene = scene
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hits = scnView.hitTest(location, options: [.boundingBoxOnly: true])
            
            // Chercher le premier noeud avec un nom (l'UUID de l'habitant)
            for hit in hits {
                if let name = hit.node.name, let uuid = UUID(uuidString: name) {
                    DispatchQueue.main.async {
                        self.engine.selectedInhabitantId = uuid
                    }
                    return
                } else if let parentName = hit.node.parent?.name, let uuid = UUID(uuidString: parentName) {
                    DispatchQueue.main.async {
                        self.engine.selectedInhabitantId = uuid
                    }
                    return
                }
            }
            // Clique dans le vide -> deselection
            DispatchQueue.main.async {
                self.engine.selectedInhabitantId = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(engine: engine, scene: scene)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.allowsCameraControl = false
        view.showsStatistics = true
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        view.antialiasingMode = .multisampling4X
        
        setupGestures(in: view, context: context)
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    private func setupGestures(in view: UIView, context: Context) {
        let panGesture = UIPanGestureRecognizer(target: scene.cameraController, action: #selector(CameraController.handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: scene.cameraController, action: #selector(CameraController.handlePinch(_:)))
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(pinchGesture)
        view.addGestureRecognizer(tapGesture)
    }
}
