import SwiftUI
import SceneKit

struct MainView: View {
    @StateObject private var engine = SimulationEngine()
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            if isLoaded {
                // Jeu principal
                ZStack {
                    SceneContainerView(engine: engine)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Tiny World")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 2)
                                Text("Habitants: \(engine.worldData.inhabitants.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 2)
                                Text("Score Dév: \(engine.worldData.developmentScore)")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black.opacity(0.8), radius: 2)
                            }
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                            
                            Spacer()
                        }
                        .padding(.top, 40)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Panel de construction contextuel
                        if let zoneId = engine.selectedZoneId,
                           let zone = engine.worldData.zones.first(where: { $0.id == zoneId }),
                           !zone.isBuilt {
                            
                            VStack(spacing: 10) {
                                Text("Construire : \(zone.name)")
                                    .font(.headline)
                                Text("Coût : \(zone.cost) pts")
                                    .font(.subheadline)
                                
                                if engine.worldData.developmentScore >= zone.cost {
                                    Button(action: {
                                        engine.buildZone(id: zoneId)
                                    }) {
                                        Text("Construire")
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.green)
                                            .cornerRadius(10)
                                    }
                                } else {
                                    Text("Pas assez de points")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding()
                        }
                    }
                }
            } else {
                // Ecran de chargement elegant
                ZStack {
                    Color(red: 0.1, green: 0.15, blue: 0.2).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .cornerRadius(25)
                            .shadow(radius: 10)
                            
                        Text("TINY WORLD")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                            
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            
                        Text("Chargement du monde...")
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                }
                .onAppear {
                    // Chargement lourd asynchrone
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Pre-chauffer l'engine et les assets (AssetManager est lazy, on l'invoque)
                        _ = AssetManager.shared.characterScene
                        _ = AssetManager.shared.getModel(named: "building-type-a", folder: "suburban")
                        
                        engine.start() // demarre la simu
                        
                        DispatchQueue.main.async {
                            withAnimation(.easeIn(duration: 1.0)) {
                                self.isLoaded = true
                            }
                        }
                    }
                }
            }
        }
    }
}
