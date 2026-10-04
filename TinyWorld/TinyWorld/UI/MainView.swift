import SwiftUI
import SceneKit

struct MainView: View {
    @StateObject private var simulationEngine = SimulationEngine()
    @State private var gameScene = GameScene()

    var body: some View {
        ZStack {
            // Conteneur de la scene 3D
            SceneContainerView(scene: gameScene)
                .ignoresSafeArea()
                .onAppear {
                    simulationEngine.start()
                }
                .onReceive(simulationEngine.$world) { updatedWorld in
                    // Synchronisation strictement unidirectionnelle (Données -> Vue)
                    gameScene.sync(with: updatedWorld)
                }

            // HUD minimal (Overlay)
            VStack {
                HStack {
                    Text("Tiny World")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, 20)
                Spacer()
            }
        }
    }
}
