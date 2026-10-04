import Foundation

class MovementSystem {
    func update(world: inout WorldData, deltaTime: Float) {
        for i in 0..<world.inhabitants.count {
            var inhabitant = world.inhabitants[i]
            
            switch inhabitant.state {
            case .idle:
                // Attente avant de bouger
                inhabitant.waitTimer -= deltaTime
                if inhabitant.waitTimer <= 0 {
                    inhabitant.state = .moving
                    // Nouvelle destination aléatoire sur le terrain
                    inhabitant.destinationX = Float.random(in: -world.size/2...world.size/2)
                    inhabitant.destinationZ = Float.random(in: -world.size/2...world.size/2)
                }
                
            case .moving:
                guard let destX = inhabitant.destinationX, let destZ = inhabitant.destinationZ else {
                    inhabitant.state = .idle
                    inhabitant.waitTimer = Float.random(in: 1.0...5.0)
                    world.inhabitants[i] = inhabitant
                    continue
                }
                
                let dx = destX - inhabitant.positionX
                let dz = destZ - inhabitant.positionZ
                let distance = sqrt(dx*dx + dz*dz)
                
                // Déplacement selon la vitesse et le tick
                let moveAmount = inhabitant.speed * deltaTime * Float(5.0) // Ajustement global de la vitesse
                
                if distance <= moveAmount {
                    // Arrivé à destination
                    inhabitant.positionX = destX
                    inhabitant.positionZ = destZ
                    inhabitant.state = .idle
                    inhabitant.destinationX = nil
                    inhabitant.destinationZ = nil
                    inhabitant.waitTimer = Float.random(in: 2.0...8.0) // Attente désynchronisée
                } else {
                    // Mouvement vers la destination
                    let ratio = moveAmount / distance
                    inhabitant.positionX += dx * ratio
                    inhabitant.positionZ += dz * ratio
                }
            }
            
            world.inhabitants[i] = inhabitant
        }
    }
}
