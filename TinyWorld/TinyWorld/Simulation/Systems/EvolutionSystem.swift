import Foundation

class EvolutionSystem {
    
    func update(world: inout WorldData, deltaTime: Float) {
        // Le score augmente si les gens travaillent
        let workers = world.inhabitants.filter { $0.activity == .working && !$0.isMoving }.count
        
        // 0.5 point par seconde reelle par travailleur
        world.developmentScore += Float(workers) * deltaTime * 0.5
    }
    
    func catchUp(world: inout WorldData, offlineSeconds: TimeInterval) {
        let workerCount = Float(world.inhabitants.count)
        let estimatedWorkingSeconds = Float(offlineSeconds) * 0.33
        
        world.developmentScore += workerCount * estimatedWorkingSeconds * 0.5
        
        let timePassed = Float(offlineSeconds) * 0.02
        world.timeOfDay = (world.timeOfDay + timePassed).truncatingRemainder(dividingBy: 24.0)
        
        // Replacer logiquement les habitants
        let activitySystem = ActivitySystem()
        for i in 0..<world.inhabitants.count {
            var inh = world.inhabitants[i]
            inh.activity = activitySystem.determineActivity(for: inh, time: world.timeOfDay)
            inh.isMoving = false
            
            if let zone = activitySystem.getZone(for: inh.activity, inhabitant: inh, world: world) {
                let angle = Float.random(in: 0...(2 * .pi))
                let r = Float.random(in: 0...(zone.radius * 0.8))
                inh.positionX = zone.centerX + r * cos(angle)
                inh.positionZ = zone.centerZ + r * sin(angle)
            }
            world.inhabitants[i] = inh
        }
    }
}
