import Foundation

class ActivitySystem {
    func update(world: inout WorldData, deltaTime: Float) {
        let time = world.timeOfDay
        
        for i in 0..<world.inhabitants.count {
            var inhabitant = world.inhabitants[i]
            
            // Déterminer la nouvelle activité selon l'heure
            let newActivity = determineActivity(for: inhabitant, time: time)
            
            if inhabitant.activity != newActivity {
                // Changement d'activité
                inhabitant.activity = newActivity
                inhabitant.isMoving = true
                
                // Définir la destination
                let targetZone = getZone(for: newActivity, inhabitant: inhabitant, world: world)
                
                // Point aléatoire dans la zone
                if let zone = targetZone {
                    let angle = Float.random(in: 0...(2 * .pi))
                    let r = Float.random(in: 0...zone.radius)
                    inhabitant.destinationX = zone.centerX + r * cos(angle)
                    inhabitant.destinationZ = zone.centerZ + r * sin(angle)
                }
                
                // Reset timer local (pour éviter qu'il change tout de suite d'avis)
                inhabitant.waitTimer = 0
            }
            
            world.inhabitants[i] = inhabitant
        }
    }
    
    func determineActivity(for inhabitant: InhabitantData, time: Float) -> Activity {
        if time < inhabitant.wakeUpTime || time > inhabitant.sleepTime {
            return .sleeping
        } else if time >= inhabitant.wakeUpTime && time < (inhabitant.wakeUpTime + 1.5) {
            return .eating // Petit dej
        } else if time >= 8.5 && time < 17.0 {
            if time >= 12.0 && time < 13.5 {
                return .eating // Dejeuner
            }
            return .working
        } else if time >= 17.0 && time < 20.0 {
            return .wandering // Temps libre
        } else {
            return .resting // Soirée à la maison
        }
    }
    
    func getZone(for activity: Activity, inhabitant: InhabitantData, world: WorldData) -> Zone? {
        let activeZones = world.zones.filter { $0.isBuilt }
        
        switch activity {
        case .sleeping, .resting:
            return activeZones.first { $0.id == inhabitant.homeZoneId }
        case .working:
            return activeZones.first { $0.id == inhabitant.workZoneId }
        case .eating:
            // S'il n'y a pas de zone de nourriture construite, on rentre a la maison
            if let foodZone = activeZones.first(where: { $0.type == .food }) {
                return foodZone
            }
            return activeZones.first { $0.id == inhabitant.homeZoneId }
        case .wandering:
            // S'il n'y a pas de parc, on erre pres de la maison
            if let parkZone = activeZones.first(where: { $0.type == .park }) {
                return parkZone
            }
            return activeZones.first { $0.id == inhabitant.homeZoneId }
        }
    }
}
