import SwiftUI
import SceneKit

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var simulationEngine = SimulationEngine()
    @State private var gameScene = GameScene()

    var body: some View {
        ZStack {
            SceneContainerView(scene: gameScene, engine: simulationEngine)
                .ignoresSafeArea()
                .onAppear { simulationEngine.start() }
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
                            
                        Text("Dev: \(Int(simulationEngine.world.developmentScore))")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    
                    Spacer()
                    
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
                    } else if let zone = simulationEngine.selectedZone, !zone.isBuilt {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Projet: \(zone.name)")
                                .font(.headline)
                            Text("Coût: \(Int(zone.cost))")
                                .font(.subheadline)
                                .foregroundColor(simulationEngine.world.developmentScore >= zone.cost ? .green : .red)
                            
                            Button(action: {
                                simulationEngine.buildZone(id: zone.id)
                            }) {
                                Text("Construire")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(simulationEngine.world.developmentScore >= zone.cost ? Color.blue : Color.gray)
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            .disabled(simulationEngine.world.developmentScore < zone.cost)
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
        case .eating: return "Au marché"
        case .working: return "Travaille"
        case .resting: return "Se repose chez soi"
        case .wandering: return "Se promène au parc"
        }
    }
}
