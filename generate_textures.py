import os
import math
import numpy as np
from PIL import Image

def organic_noise(size, cells, seed):
    """Create a deterministic, softly varying field without directional bands."""
    rng = np.random.default_rng(seed)
    low_size = max(2, cells + 1)
    low = rng.random((low_size, low_size), dtype=np.float32)
    field = Image.fromarray(np.clip(low * 255.0, 0, 255).astype(np.uint8))
    field = field.resize((size, size), Image.Resampling.BICUBIC)
    return np.asarray(field, dtype=np.float32) / 255.0

def generate_textures():
    size = 2048
    print(f"Generating {size}x{size} island textures...")

    # Coordinate grids in world space [-16.0, 16.0]
    lin = np.linspace(-16.0, 16.0, size, dtype=np.float32)
    x, z = np.meshgrid(lin, lin) # shape (size, size)
    r = np.sqrt(x**2 + z**2)
    angle = np.arctan2(x, z)

    # 1. Base terrain height field for macro color shading
    # Same hills formula as TerrainBuilder (updated with biome features):
    h1 = np.sin(x * 0.18 + 1.5) * np.cos(z * 0.22) * 1.1
    h2 = np.sin(x * 0.35) * np.sin(z * 0.28 + 2.0) * 0.5
    h3 = np.cos(x * 0.7) * np.cos(z * 0.65) * 0.15
    h4 = np.sin(x * 0.12 + 0.7) * np.cos(z * 0.15 + 1.2) * 0.3
    h5 = np.sin(x * 0.5 + angle * 0.3) * np.cos(z * 0.45 - angle * 0.2) * 0.25
    h6 = np.cos(x * 0.28 + 1.8) * np.sin(z * 0.32 + 0.5) * 0.18
    height = h1 + h2 + h3 + h4 + h5 + h6

    # Biome-aware terrain shaping (must match TerrainBuilder.getHeight)
    # Northwest: elevated forested hills
    nw_mask = ((x < -4.0) & (z < -4.0)).astype(np.float32)
    nw_dist = np.sqrt((x + 9.0)**2 + (z + 8.0)**2)
    nw_biome = np.clip(1.0 - nw_dist / 7.0, 0.0, 1.0) * 0.35 * nw_mask
    
    # Northeast: rocky elevated terrain
    ne_mask = ((x > 4.0) & (z < -4.0)).astype(np.float32)
    ne_dist = np.sqrt((x - 8.0)**2 + (z + 7.0)**2)
    ne_biome = np.clip(1.0 - ne_dist / 7.0, 0.0, 1.0) * 0.5 * ne_mask
    
    # South: gentle meadow depression
    s_mask = (z > 6.0).astype(np.float32)
    s_dist = np.sqrt(x**2 + (z - 10.0)**2)
    s_biome = -np.clip(1.0 - s_dist / 8.0, 0.0, 1.0) * 0.2 * s_mask
    
    height += nw_biome + ne_biome + s_biome

    # Center plaza mound
    center_mound = np.clip(1.0 - r / 5.0, 0.0, 1.0) * 0.4
    height = np.where(r < 5.0, height * np.maximum(0.3, r / 5.0) + center_mound, height)

    # Gentle descent towards shoreline
    shore_drop = np.clip((r - 11.5) * 0.42, 0.0, None)
    height -= shore_drop

    # Beach/sand transition zone (slightly flattened)
    beach_factor = np.clip(1.0 - (r - 13.0) / 2.5, 0.0, 1.0)
    beach_zone = ((r > 13.0) & (r < 15.5)).astype(np.float32)
    height = np.where(beach_zone > 0, height * (0.3 + beach_factor * 0.7) - 0.05, height)

    # Underwater slope
    edge_drop = np.clip((r - 15.5) * 1.4, 0.0, None)
    height -= edge_drop * edge_drop

    # Normalize height variation to [-1, 1] for color interpolation
    h_norm = np.clip(height / 1.5, -1.0, 1.0)

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
    # Add a soft, irregular breakup to dirt edges without directional repetition.
    edge_variation = organic_noise(size, cells=48, seed=4401)
    edge_variation = (edge_variation - 0.5) * 0.18
    total_dirt_mask = np.clip(total_dirt_mask + edge_variation, 0.0, 1.0)

    # 3. Shoreline Mask
    # Transition to beach sand from radius 13.0 to 15.8
    shore_mask = np.clip((r - 13.0) / 2.6, 0.0, 1.0)
    # Beyond radius 15.8 is the underwater drop
    outer_drop = np.clip((r - 15.8) / 0.8, 0.0, 1.0)

    # 4. Synthesize Lush Stylized Grass Color Palette
    # Warmer, more harmonious greens for stylized look
    # Base meadow green: #6BA34A (107, 163, 74)
    # Sunlit hilltop: #8FC955 (143, 201, 85)
    # Shaded valley: #4D8C32 (77, 140, 50)
    grass_base = np.array([107.0, 163.0, 74.0], dtype=np.float32)
    grass_sunlit = np.array([143.0, 201.0, 85.0], dtype=np.float32)
    grass_shaded = np.array([77.0, 140.0, 50.0], dtype=np.float32)

    # Height-based grass color interpolation
    h_weight = (h_norm + 1.0) * 0.5 # [0, 1]
    grass_color = np.zeros((size, size, 3), dtype=np.float32)
    for c in range(3):
        grass_color[:, :, c] = grass_shaded[c] * (1.0 - h_weight) + grass_sunlit[c] * h_weight

    # Add broad, irregular grass variation. Independent fields avoid a visible grid
    # and keep the albedo pattern separate from the normal-map relief.
    grass_variation = organic_noise(size, cells=28, seed=1401)
    grass_variation = (grass_variation - 0.5) * 2.0
    for c in range(3):
        grass_color[:, :, c] += grass_variation * 6.0

    # Biome-specific grass tinting
    # Northwest forest: slightly cooler, deeper green
    nw_grass_tint = np.clip(1.0 - nw_dist / 8.0, 0.0, 1.0) * nw_mask
    grass_color[:, :, 0] -= nw_grass_tint * 8.0   # Less red
    grass_color[:, :, 1] += nw_grass_tint * 5.0   # More green
    grass_color[:, :, 2] -= nw_grass_tint * 3.0   # Less blue
    
    # Northeast rocky: more muted, olive tones
    ne_grass_tint = np.clip(1.0 - ne_dist / 8.0, 0.0, 1.0) * ne_mask
    grass_color[:, :, 0] += ne_grass_tint * 10.0  # More red/brown
    grass_color[:, :, 1] -= ne_grass_tint * 8.0   # Less green
    grass_color[:, :, 2] -= ne_grass_tint * 5.0   # Less blue
    
    # South meadow: brighter, warmer
    s_grass_tint = np.clip(1.0 - s_dist / 9.0, 0.0, 1.0) * s_mask
    grass_color[:, :, 0] += s_grass_tint * 5.0    # Warmer
    grass_color[:, :, 1] += s_grass_tint * 10.0   # Brighter green
    grass_color[:, :, 2] -= s_grass_tint * 2.0

    # 5. Warm Golden Earth & Dirt Path Palette
    # More harmonious earth tones
    # Base earth: #C49A6C (196, 154, 108)
    # Light path sand: #D8B58A (216, 181, 138)
    # Warm gravel accents: #A87C4A (168, 124, 74)
    dirt_base = np.array([196.0, 154.0, 108.0], dtype=np.float32)
    dirt_light = np.array([216.0, 181.0, 138.0], dtype=np.float32)
    dirt_gravel = organic_noise(size, cells=64, seed=2401)

    dirt_color = np.zeros((size, size, 3), dtype=np.float32)
    for c in range(3):
        dirt_color[:, :, c] = dirt_base[c] + dirt_gravel * (dirt_light[c] - dirt_base[c])

    # 6. Golden Beach Sand Shoreline Palette
    # Warmer, more inviting sand tones
    # Beach sand: #EDD0A0 (237, 208, 160)
    # Wet shore sand: #D4B88C (212, 184, 140)
    sand_base = np.array([237.0, 208.0, 160.0], dtype=np.float32)
    sand_wet = np.array([212.0, 184.0, 140.0], dtype=np.float32)
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
    # Submerged cliff edge tint (dark cool rock under water)
    drop_3d = np.repeat(outer_drop[:, :, np.newaxis], 3, axis=2)
    cliff_color = np.array([60.0, 70.0, 85.0], dtype=np.float32)
    final_diffuse = final_diffuse * (1.0 - drop_3d) + cliff_color * drop_3d

    final_diffuse = np.clip(final_diffuse, 0.0, 255.0).astype(np.uint8)

    # 8. Generate a soft normal map from terrain height and an independent,
    # low-frequency relief field. It must not repeat the albedo pattern.
    relief_variation = organic_noise(size, cells=16, seed=3401)
    relief_variation = (relief_variation - 0.5) * 0.08
    micro_relief = relief_variation * (1.0 - total_dirt_mask)
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

    # Keep the diffuse JPG path stable; the data-oriented maps use lossless PNG files.
    Image.fromarray(final_diffuse).save(
        os.path.join(out_dir, "island_diffuse.jpg"), quality=100, subsampling=0
    )
    # Lossless maps avoid block and chroma artifacts in the normal and roughness channels.
    Image.fromarray(normal_map).save(
        os.path.join(out_dir, "island_normal.png"), format="PNG", optimize=True
    )
    Image.fromarray(roughness_map).save(
        os.path.join(out_dir, "island_roughness.png"), format="PNG", optimize=True
    )

    print("Successfully generated island_diffuse.jpg, island_normal.png, island_roughness.png!")

if __name__ == "__main__":
    generate_textures()
