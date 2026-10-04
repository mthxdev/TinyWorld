import SwiftUI
import SceneKit

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var simulationEngine = SimulationEngine()
    @State private var gameScene = GameScene()

    var body: some View {
        ZStack {
            // Conteneur de la scene 3D
            SceneContainerView(scene: gameScene, engine: simulationEngine)
                .ignoresSafeArea()
                .onAppear {
                    simulationEngine.start()
                }
                .onReceive(simulationEngine.$world) { updatedWorld in
                    gameScene.sync(with: updatedWorld)
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        simulationEngine.start()
                    } else if newPhase == .background || newPhase == .inactive {
                        simulationEngine.save()
                    }
                }

            // HUD minimal (Overlay)
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tiny World")
                            .font(.headline)
                        
                        let hour = Int(simulationEngine.world.timeOfDay)
                        let minute = Int((simulationEngine.world.timeOfDay - Float(hour)) * 60)
                        Text(String(format: "%02d:%02d", hour, minute))
                            .font(.subheadline)
                        
                        Text("\(simulationEngine.world.inhabitants.count) habitants")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Panneau d'informations sur l'habitant sélectionné
                    if let inhabitant = simulationEngine.selectedInhabitant {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(inhabitant.name)
                                .font(.headline)
                            Text(activityDescription(for: inhabitant.activity))
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    private func activityDescription(for activity: Activity) -> String {
        switch activity {
        case .sleeping: return "Dort paisiblement"
        case .eating: return "Mange"
        case .working: return "Travaille"
        case .resting: return "Se repose chez soi"
        case .wandering: return "Se promène"
        }
    }
}
