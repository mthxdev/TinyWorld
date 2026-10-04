import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var world: WorldData
    
    private var timer: Timer?
    
    init() {
        self.world = WorldData()
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        // Temps
        world.timeOfDay += 0.05
        if world.timeOfDay >= 24.0 { world.timeOfDay = 0.0 }
        
        // IA basique des habitants
        let speed: Float = 0.5 // distance par tick
        
        for i in 0..<world.inhabitants.count {
            var inhabitant = world.inhabitants[i]
            
            if inhabitant.state == .idle {
                // 5% de chance de commencer à bouger
                if Float.random(in: 0...1) < 0.05 {
                    inhabitant.state = .moving
                    inhabitant.destinationX = Float.random(in: -world.size/2...world.size/2)
                    inhabitant.destinationZ = Float.random(in: -world.size/2...world.size/2)
                }
            } else if inhabitant.state == .moving {
                guard let destX = inhabitant.destinationX, let destZ = inhabitant.destinationZ else {
                    inhabitant.state = .idle
                    world.inhabitants[i] = inhabitant
                    continue
                }
                
                let dx = destX - inhabitant.positionX
                let dz = destZ - inhabitant.positionZ
                let distance = sqrt(dx*dx + dz*dz)
                
                if distance < speed {
                    // Arrivé
                    inhabitant.positionX = destX
                    inhabitant.positionZ = destZ
                    inhabitant.state = .idle
                    inhabitant.destinationX = nil
                    inhabitant.destinationZ = nil
                } else {
                    // Mouvement
                    let ratio = speed / distance
                    inhabitant.positionX += dx * ratio
                    inhabitant.positionZ += dz * ratio
                }
            }
            world.inhabitants[i] = inhabitant
        }
    }
}
