import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var world: WorldData
    
    private var timer: Timer?
    
    private let movementSystem = MovementSystem()
    
    init() {
        self.world = WorldData()
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick(deltaTime: 0.1)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick(deltaTime: Float) {
        // Temps
        world.timeOfDay += 0.05
        if world.timeOfDay >= 24.0 { world.timeOfDay = 0.0 }
        
        // Délégation de la logique de déplacement
        movementSystem.update(world: &world, deltaTime: deltaTime)
    }
}
