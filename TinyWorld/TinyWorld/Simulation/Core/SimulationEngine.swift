import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var world: WorldData
    @Published var selectedInhabitantId: UUID?
    
    private var timer: Timer?
    
    private let movementSystem = MovementSystem()
    private let activitySystem = ActivitySystem()
    private let evolutionSystem = EvolutionSystem()
    
    // Echelle : 1 seconde reelle = 0.02 heure in-game (50 secondes reelles = 1 heure in-game).
    // Un jour complet (24h) dure donc 1200 secondes (20 minutes).
    private let timeScale: Float = 0.02
    
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
        
        // On cap le rattrapage à 24 heures réelles
        let cappedElapsed = min(elapsedRealSeconds, 24 * 3600) 
        
        if cappedElapsed > 1 {
            var tempWorld = world
            evolutionSystem.catchUp(world: &tempWorld, offlineSeconds: cappedElapsed)
            world = tempWorld
        }
        
        world.lastSavedDate = now
    }
    
    private func tick(deltaTime: Float) {
        updateSystems(deltaTime: deltaTime)
    }
    
    private func updateSystems(deltaTime: Float) {
        // Temps
        let timeToAdd = timeScale * deltaTime // 0.02 * 0.1 = 0.002
        world.timeOfDay += timeToAdd
        if world.timeOfDay >= 24.0 { world.timeOfDay = 0.0 }
        
        var tempWorld = world
        evolutionSystem.update(world: &tempWorld, deltaTime: deltaTime)
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
