import UIKit

class TextureGenerator {
    static let shared = TextureGenerator()
    
    // Cache for textures
    private var cache: [String: UIImage] = [:]
    
    func getGrassTexture() -> UIImage {
        if let tex = cache["grass"] { return tex }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            for x in 0..<256 {
                for y in 0..<256 {
                    let noise = CGFloat.random(in: 0.8...1.0)
                    cgCtx.setFillColor(UIColor(red: 0.3 * noise, green: 0.6 * noise, blue: 0.2 * noise, alpha: 1.0).cgColor)
                    cgCtx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        cache["grass"] = img
        return img
    }
    
    func getWoodTexture() -> UIImage {
        if let tex = cache["wood"] { return tex }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            for x in 0..<256 {
                for y in 0..<256 {
                    // Lignes verticales de grain
                    let grain = sin(Float(x) * 0.1) * 0.5 + 0.5
                    let noise = CGFloat.random(in: 0.8...1.0)
                    let base = CGFloat(0.4 + 0.1 * grain) * noise
                    cgCtx.setFillColor(UIColor(red: base, green: base * 0.7, blue: base * 0.4, alpha: 1.0).cgColor)
                    cgCtx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        cache["wood"] = img
        return img
    }
    
    func getStoneTexture() -> UIImage {
        if let tex = cache["stone"] { return tex }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            for x in 0..<256 {
                for y in 0..<256 {
                    let noise = CGFloat.random(in: 0.7...1.0)
                    cgCtx.setFillColor(UIColor(white: 0.6 * noise, alpha: 1.0).cgColor)
                    cgCtx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        cache["stone"] = img
        return img
    }
    
    func getRoofTexture() -> UIImage {
        if let tex = cache["roof"] { return tex }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            for x in 0..<256 {
                for y in 0..<256 {
                    // Tuiles horizontales
                    let tileY: CGFloat = (y % 32) < 2 ? 0.6 : 1.0
                    let noise = CGFloat.random(in: 0.9...1.0)
                    let r = 0.8 * tileY * noise
                    let g = 0.3 * tileY * noise
                    let b = 0.25 * tileY * noise
                    cgCtx.setFillColor(UIColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
                    cgCtx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        cache["roof"] = img
        return img
    }
    
    func getWaterTexture() -> UIImage {
        if let tex = cache["water"] { return tex }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            for x in 0..<256 {
                for y in 0..<256 {
                    let noise = CGFloat.random(in: 0.9...1.0)
                    cgCtx.setFillColor(UIColor(red: 0.2 * noise, green: 0.6 * noise, blue: 0.9 * noise, alpha: 0.8).cgColor)
                    cgCtx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        cache["water"] = img
        return img
    }
}
