import Foundation

class EvolutionSystem {
    
    func update(world: inout WorldData, deltaTime: Float) {
        // Le score augmente si les gens travaillent
        let workers = world.inhabitants.filter { $0.activity == .working && !$0.isMoving }.count
        
        // 1.0 point par travailleur par seconde in-game
        // deltaTime est en secondes reelles. 1 seconde reelle = 50 secondes in-game (avec l'echelle lente).
        // Restons simple : 0.5 point par seconde reelle par travailleur
        world.developmentScore += Float(workers) * deltaTime * 0.5
        
        checkMilestones(world: &world)
    }
    
    private func checkMilestones(world: inout WorldData) {
        let score = world.developmentScore
        let index = world.milestoneIndex
        
        // Palier 1 : 150 points -> Maison 2 (id: 2) construite + 2 habitants
        if index == 0 && score >= 150 {
            buildZone(id: 2, in: &world)
            world.addInhabitants(count: 2, toHome: 2, work: 1)
            world.milestoneIndex = 1
        }
        // Palier 2 : 400 points -> Parc (id: 3) construit
        else if index == 1 && score >= 400 {
            buildZone(id: 3, in: &world)
            world.milestoneIndex = 2
        }
        // Palier 3 : 800 points -> Maison 3 (id: 4) construite + 2 habitants
        else if index == 2 && score >= 800 {
            buildZone(id: 4, in: &world)
            world.addInhabitants(count: 2, toHome: 4, work: 1)
            world.milestoneIndex = 3
        }
        // Palier 4 : 1500 points -> Nourriture (id: 5) construite
        else if index == 3 && score >= 1500 {
            buildZone(id: 5, in: &world)
            world.milestoneIndex = 4
        }
        // Palier 5 : 2500 points -> Maison 4 (id: 6) construite + 3 habitants
        else if index == 4 && score >= 2500 {
            buildZone(id: 6, in: &world)
            world.addInhabitants(count: 3, toHome: 6, work: 1)
            world.milestoneIndex = 5
        }
    }
    
    private func buildZone(id: Int, in world: inout WorldData) {
        if let idx = world.zones.firstIndex(where: { $0.id == id }) {
            world.zones[idx].isBuilt = true
        }
    }
    
    func catchUp(world: inout WorldData, offlineSeconds: TimeInterval) {
        // Ratio moyen : un habitant travaille environ 8h par jour, soit 1/3 du temps.
        let workerCount = Float(world.inhabitants.count)
        let estimatedWorkingSeconds = Float(offlineSeconds) * 0.33
        
        world.developmentScore += workerCount * estimatedWorkingSeconds * 0.5
        
        // Echelle de temps : 1 seconde reelle = 0.02 heures in-game (donc 1h in-game = 50s reelles)
        let timePassed = Float(offlineSeconds) * 0.02
        world.timeOfDay = (world.timeOfDay + timePassed).truncatingRemainder(dividingBy: 24.0)
        
        // Verifier tous les paliers debloques par ce grand bon dans le temps
        while true {
            let previousIndex = world.milestoneIndex
            checkMilestones(world: &world)
            if world.milestoneIndex == previousIndex { break } // Plus de paliers franchis
        }
        
        // Replacer logiquement les habitants
        let activitySystem = ActivitySystem()
        for i in 0..<world.inhabitants.count {
            var inh = world.inhabitants[i]
            inh.activity = activitySystem.determineActivity(for: inh, time: world.timeOfDay)
            inh.isMoving = false
            
            if let zone = activitySystem.getZone(for: inh.activity, inhabitant: inh, world: world) {
                // Placer dans la zone
                let angle = Float.random(in: 0...(2 * .pi))
                let r = Float.random(in: 0...(zone.radius * 0.8))
                inh.positionX = zone.centerX + r * cos(angle)
                inh.positionZ = zone.centerZ + r * sin(angle)
            }
            world.inhabitants[i] = inh
        }
    }
}
