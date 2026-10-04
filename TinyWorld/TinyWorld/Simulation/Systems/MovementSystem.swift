import Foundation

class MovementSystem {
    func update(world: inout WorldData, deltaTime: Float) {
        for i in 0..<world.inhabitants.count {
            var inhabitant = world.inhabitants[i]
            
            if inhabitant.isMoving {
                // Déplacement vers un point spécifique (destination)
                guard let destX = inhabitant.destinationX, let destZ = inhabitant.destinationZ else {
                    inhabitant.isMoving = false
                    world.inhabitants[i] = inhabitant
                    continue
                }
                
                let dx = destX - inhabitant.positionX
                let dz = destZ - inhabitant.positionZ
                let distance = (dx*dx + dz*dz).squareRoot()
                
                let moveAmount = inhabitant.speed * deltaTime * Float(5.0)
                
                if distance <= moveAmount {
                    // Arrivé à destination
                    inhabitant.positionX = destX
                    inhabitant.positionZ = destZ
                    inhabitant.isMoving = false
                    inhabitant.destinationX = nil
                    inhabitant.destinationZ = nil
                    inhabitant.waitTimer = Float.random(in: 2.0...5.0) // Pause avant micro-déplacement
                } else {
                    let ratio = moveAmount / distance
                    inhabitant.positionX += dx * ratio
                    inhabitant.positionZ += dz * ratio
                }
            } else {
                // L'habitant est à destination. S'il ne dort pas, on le fait bouger un tout petit peu.
                if inhabitant.activity != .sleeping {
                    inhabitant.waitTimer -= deltaTime
                    if inhabitant.waitTimer <= 0 {
                        inhabitant.isMoving = true
                        // Micro-déplacement très proche
                        let angle = Float.random(in: 0...(2 * .pi))
                        let r = Float.random(in: 0...1.0)
                        inhabitant.destinationX = inhabitant.positionX + r * cos(angle)
                        inhabitant.destinationZ = inhabitant.positionZ + r * sin(angle)
                    }
                }
            }
            
            world.inhabitants[i] = inhabitant
        }
    }
}
