import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var world: WorldData
    @Published var selectedInhabitantId: UUID?
    
    private var timer: Timer?
    
    private let movementSystem = MovementSystem()
    private let activitySystem = ActivitySystem()
    
    // Taux de conversion : 20 ticks = 1 heure in-game. (1 tick = 0.1s réelle, donc 1h in-game = 2s réelles).
    private let ticksPerHour: Float = 20.0
    
    init() {
        if let savedWorld = SaveManager.shared.load() {
            self.world = savedWorld
            self.catchUpOfflineTime()
        } else {
            self.world = WorldData()
        }
    }
    
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick(deltaTime: 0.1)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        world.lastSavedDate = Date()
        SaveManager.shared.save(world: world)
    }
    
    func save() {
        world.lastSavedDate = Date()
        SaveManager.shared.save(world: world)
    }
    
    private func catchUpOfflineTime() {
        let now = Date()
        let elapsedRealSeconds = now.timeIntervalSince(world.lastSavedDate)
        
        // On cap le rattrapage à 12 heures réelles pour ne pas freeze le jeu à l'ouverture
        let cappedElapsed = min(elapsedRealSeconds, 12 * 3600) 
        
        if cappedElapsed > 1 {
            // 1 seconde réelle = 10 ticks.
            let missedTicks = Int(cappedElapsed * 10)
            
            // Pour des raisons de perfs, si l'absence est très longue, on simule par plus grands pas
            let maxSimulationSteps = 500
            let stepDeltaTime = Float(missedTicks) * 0.1 / Float(maxSimulationSteps)
            let actualSteps = min(missedTicks, maxSimulationSteps)
            let actualDelta = (missedTicks > maxSimulationSteps) ? stepDeltaTime : 0.1
            
            for _ in 0..<actualSteps {
                updateSystems(deltaTime: actualDelta)
            }
        }
        
        world.lastSavedDate = now
    }
    
    private func tick(deltaTime: Float) {
        updateSystems(deltaTime: deltaTime)
    }
    
    private func updateSystems(deltaTime: Float) {
        // Temps: 0.05 par deltaTime de 0.1 -> 0.5 par seconde.
        // Donc 24.0 prend 48 secondes réelles.
        world.timeOfDay += (0.05 * (deltaTime / 0.1))
        if world.timeOfDay >= 24.0 { world.timeOfDay = 0.0 }
        
        // Délégation de la logique
        var tempWorld = world
        activitySystem.update(world: &tempWorld, deltaTime: deltaTime)
        movementSystem.update(world: &tempWorld, deltaTime: deltaTime)
        world = tempWorld
    }
    
    // UI Helper
    var selectedInhabitant: InhabitantData? {
        guard let id = selectedInhabitantId else { return nil }
        return world.inhabitants.first { $0.id == id }
    }
}
