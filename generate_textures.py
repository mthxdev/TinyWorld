import os
import math
import numpy as np
from PIL import Image

def generate_textures():
    size = 2048
    print(f"Generating {size}x{size} island textures...")

    # Coordinate grids in world space [-16.0, 16.0]
    lin = np.linspace(-16.0, 16.0, size, dtype=np.float32)
    x, z = np.meshgrid(lin, lin) # shape (size, size)
    r = np.sqrt(x**2 + z**2)

    # 1. Base terrain height field for macro color shading
    # Same hills formula as TerrainBuilder:
    h1 = np.sin(x * 0.2 + 1.5) * np.cos(z * 0.25) * 0.8
    h2 = np.sin(x * 0.4) * np.sin(z * 0.3 + 2.0) * 0.3
    h3 = np.cos(x * 0.8) * np.cos(z * 0.7) * 0.1
    height = h1 + h2 + h3

    # Normalize height variation to [-1, 1]
    h_norm = np.clip(height / 1.2, -1.0, 1.0)

    # 2. Paths and Plaza Mask
    # Village center plaza (radius 3.8, feather 1.2)
    plaza_dist = r
    plaza_mask = np.clip(1.0 - (plaza_dist - 2.8) / 1.5, 0.0, 1.0)

    # Zones to connect
    zones = [
        (-6.0, -6.0),   # Zone 0: Maison Fondatrice
        (0.0, 8.0),     # Zone 1: Atelier
        (8.0, -6.0),    # Zone 2: Petite Maison
        (0.0, -12.0),   # Zone 3: Parc
        (-12.0, 6.0),   # Zone 4: Ferme
        (-14.0, -4.0),  # Zone 5: Maison de Fermier
        (12.0, 6.0),    # Zone 6: Marché
        (15.0, -12.0),  # Zone 7: Forêt Paisible
        (6.0, 14.0)     # Zone 8: Maison Lointaine
    ]

    path_mask = np.zeros((size, size), dtype=np.float32)

    # Calculate distance to line segments from (0,0) to each zone
    for (zx, zz) in zones:
        # Vector from (0,0) to (zx, zz)
        seg_len_sq = zx**2 + zz**2
        # Projection of point (x, z) onto segment
        t = np.clip((x * zx + z * zz) / seg_len_sq, 0.0, 1.0)
        # Closest point on segment with slight natural meander
        meander = np.sin(t * math.pi * 3.0) * 0.4
        perp_x = -zz / math.sqrt(seg_len_sq)
        perp_z = zx / math.sqrt(seg_len_sq)
        
        proj_x = t * zx + meander * perp_x
        proj_z = t * zz + meander * perp_z
        
        dist_to_path = np.sqrt((x - proj_x)**2 + (z - proj_z)**2)
        # Path width: 1.2m core, 0.6m feather
        seg_mask = np.clip(1.0 - (dist_to_path - 0.9) / 0.6, 0.0, 1.0)
        path_mask = np.maximum(path_mask, seg_mask)

        # Zone clearing circle
        zone_dist = np.sqrt((x - zx)**2 + (z - zz)**2)
        zone_clearing = np.clip(1.0 - (zone_dist - 1.8) / 0.8, 0.0, 1.0) * 0.75
        path_mask = np.maximum(path_mask, zone_clearing)

    total_dirt_mask = np.maximum(plaza_mask, path_mask)
    # Add soft organic fractal break-up to the dirt mask edges
    noise_freq1 = np.sin(x * 3.5) * np.cos(z * 3.5) * 0.1
    noise_freq2 = np.sin(x * 7.0 + 1.2) * np.cos(z * 7.0 + 0.8) * 0.05
    total_dirt_mask = np.clip(total_dirt_mask + noise_freq1 + noise_freq2, 0.0, 1.0)

    # 3. Shoreline Mask
    # Transition to beach sand from radius 13.0 to 15.8
    shore_mask = np.clip((r - 13.0) / 2.6, 0.0, 1.0)
    # Beyond radius 15.8 is the underwater drop
    outer_drop = np.clip((r - 15.8) / 0.8, 0.0, 1.0)

    # 4. Synthesize Lush Stylized Grass Color Palette
    # Base cozy green: #5E9F34 (94, 159, 52)
    # Sunlit hilltop green: #75BA3E (117, 186, 62)
    # Lush valley emerald: #438025 (67, 128, 37)
    grass_base = np.array([94.0, 159.0, 52.0], dtype=np.float32)
    grass_sunlit = np.array([122.0, 192.0, 64.0], dtype=np.float32)
    grass_shaded = np.array([66.0, 126.0, 36.0], dtype=np.float32)

    # Height-based grass color interpolation
    h_weight = (h_norm + 1.0) * 0.5 # [0, 1]
    grass_color = np.zeros((size, size, 3), dtype=np.float32)
    for c in range(3):
        grass_color[:, :, c] = grass_shaded[c] * (1.0 - h_weight) + grass_sunlit[c] * h_weight

    # Add procedural grass micro-pattern (clover tufts & stylized color patches)
    tuft_pat = (np.sin(x * 12.0) * np.cos(z * 12.0) +
                np.sin(x * 24.0 + 1.5) * np.sin(z * 24.0 + 2.1) * 0.5)
    for c in range(3):
        grass_color[:, :, c] += tuft_pat * 8.0

    # 5. Warm Golden Earth & Dirt Path Palette
    # Base earth: #C89965 (200, 153, 101)
    # Light path sand: #DCB382 (220, 179, 130)
    # Warm gravel accents: #B07E4C (176, 126, 76)
    dirt_base = np.array([205.0, 160.0, 108.0], dtype=np.float32)
    dirt_light = np.array([226.0, 185.0, 135.0], dtype=np.float32)
    dirt_gravel = (np.sin(x * 30.0) * np.cos(z * 30.0) * 0.5 + 0.5)

    dirt_color = np.zeros((size, size, 3), dtype=np.float32)
    for c in range(3):
        dirt_color[:, :, c] = dirt_base[c] + dirt_gravel * (dirt_light[c] - dirt_base[c])

    # 6. Golden Beach Sand Shoreline Palette
    # Beach sand: #E6C58F (230, 197, 143)
    # Wet shore sand: #CCA66E (204, 166, 110)
    sand_base = np.array([230.0, 197.0, 143.0], dtype=np.float32)
    sand_wet = np.array([195.0, 158.0, 105.0], dtype=np.float32)
    shore_wetness = np.clip((r - 14.8) / 1.0, 0.0, 1.0)

    shore_color = np.zeros((size, size, 3), dtype=np.float32)
    for c in range(3):
        shore_color[:, :, c] = sand_base[c] * (1.0 - shore_wetness) + sand_wet[c] * shore_wetness

    # 7. Blend Final Diffuse Albedo Map
    diffuse = np.zeros((size, size, 3), dtype=np.float32)
    dirt_3d = np.repeat(total_dirt_mask[:, :, np.newaxis], 3, axis=2)
    shore_3d = np.repeat(shore_mask[:, :, np.newaxis], 3, axis=2)

    # Blend grass and paths
    intermediate = grass_color * (1.0 - dirt_3d) + dirt_color * dirt_3d
    # Blend with shore
    final_diffuse = intermediate * (1.0 - shore_3d) + shore_color * shore_3d
    # Submerged cliff edge tint (dark rock under water)
    drop_3d = np.repeat(outer_drop[:, :, np.newaxis], 3, axis=2)
    cliff_color = np.array([120.0, 105.0, 80.0], dtype=np.float32)
    final_diffuse = final_diffuse * (1.0 - drop_3d) + cliff_color * drop_3d

    final_diffuse = np.clip(final_diffuse, 0.0, 255.0).astype(np.uint8)

    # 8. Generate Crisp Stylized Normal Map
    # Sobel / finite difference on height and micro-texture
    micro_relief = (grass_color[:, :, 1] / 255.0) * (1.0 - total_dirt_mask) * 0.4
    total_surface = height * 0.2 + micro_relief
    
    # Calculate gradients
    dy, dx = np.gradient(total_surface, 32.0 / size)
    # Scale slopes for stylized roundness
    nx = -dx * 3.0
    ny = -dy * 3.0
    nz = np.ones_like(nx)
    length = np.sqrt(nx**2 + ny**2 + nz**2)
    nx /= length
    ny /= length
    nz /= length

    norm_r = np.clip((nx * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    norm_g = np.clip((ny * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    norm_b = np.clip((nz * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    normal_map = np.stack([norm_r, norm_g, norm_b], axis=2)

    # 9. Generate Roughness Map
    # Grass: 0.84 (velvety matte)
    # Dirt paths: 0.72 (compacted earth)
    # Shore / wet sand: 0.50 (slightly damp)
    roughness = np.full((size, size), 0.84, dtype=np.float32)
    roughness = roughness * (1.0 - total_dirt_mask) + 0.72 * total_dirt_mask
    roughness = roughness * (1.0 - shore_mask) + (0.75 * (1.0 - shore_wetness) + 0.48 * shore_wetness) * shore_mask
    roughness_map = np.clip(roughness * 255.0, 0, 255).astype(np.uint8)

    # Save images to textures folder
    out_dir = "TinyWorld/TinyWorld/art.scnassets/textures"
    os.makedirs(out_dir, exist_ok=True)

    Image.fromarray(final_diffuse).save(os.path.join(out_dir, "island_diffuse.jpg"), quality=95)
    Image.fromarray(normal_map).save(os.path.join(out_dir, "island_normal.jpg"), quality=95)
    Image.fromarray(roughness_map).save(os.path.join(out_dir, "island_roughness.jpg"), quality=95)

    print("Successfully generated island_diffuse.jpg, island_normal.jpg, island_roughness.jpg!")

if __name__ == "__main__":
    generate_textures()
