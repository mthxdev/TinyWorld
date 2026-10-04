import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var world: WorldData
    @Published var selectedInhabitantId: UUID?
    @Published var selectedZoneId: Int?
    
    private var timer: Timer?
    
    private let movementSystem = MovementSystem()
    private let activitySystem = ActivitySystem()
    private let evolutionSystem = EvolutionSystem()
    
    // Echelle : 1 seconde reelle = 0.02 heure in-game (50 secondes reelles = 1 heure in-game).
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
    
    func buildZone(id: Int) {
        guard let idx = world.zones.firstIndex(where: { $0.id == id }) else { return }
        let zone = world.zones[idx]
        if !zone.isBuilt && world.developmentScore >= zone.cost {
            world.developmentScore -= zone.cost
            world.zones[idx].isBuilt = true
            
            // Ajouter des habitants ou affecter des emplois
            if zone.type == .home {
                // Si on construit une maison, on ajoute des habitants
                // Ils travailleront a l'atelier par defaut (1) ou a la ferme (4) si construite
                let workId = world.zones.first(where: { $0.type == .farm && $0.isBuilt })?.id ?? 1
                world.addInhabitants(count: 2, toHome: id, work: workId)
            } else if zone.type == .farm {
                // Rediriger 2 habitants vers la ferme
                var count = 0
                for i in 0..<world.inhabitants.count {
                    if world.inhabitants[i].workZoneId == 1 && count < 2 {
                        world.inhabitants[i].workZoneId = id
                        count += 1
                    }
                }
            }
            
            selectedZoneId = nil
        }
    }
    
    private func catchUpOfflineTime() {
        let now = Date()
        let elapsedRealSeconds = now.timeIntervalSince(world.lastSavedDate)
        
        let cappedElapsed = min(elapsedRealSeconds, 24 * 3600) 
        
        if cappedElapsed > 1 {
            var tempWorld = world
            evolutionSystem.catchUp(world: &tempWorld, offlineSeconds: cappedElapsed)
            world = tempWorld
        }
        
        world.lastSavedDate = now
    }
    
    private func tick(deltaTime: Float) {
        let timeToAdd = timeScale * deltaTime
        world.timeOfDay += timeToAdd
        if world.timeOfDay >= 24.0 { world.timeOfDay = 0.0 }
        
        var tempWorld = world
        evolutionSystem.update(world: &tempWorld, deltaTime: deltaTime)
        activitySystem.update(world: &tempWorld, deltaTime: deltaTime)
        movementSystem.update(world: &tempWorld, deltaTime: deltaTime)
        world = tempWorld
    }
    
    var selectedInhabitant: InhabitantData? {
        guard let id = selectedInhabitantId else { return nil }
        return world.inhabitants.first { $0.id == id }
    }
    
    var selectedZone: Zone? {
        guard let id = selectedZoneId else { return nil }
        return world.zones.first { $0.id == id }
    }
}
