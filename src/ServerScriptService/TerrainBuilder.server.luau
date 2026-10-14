-- TerrainBuilder (Script in ServerScriptService)
-- Paints the entire vertical world using native Roblox terrain voxels.
-- Layers: Sky (above water) → Surface biomes → Mid-Water → Rock barrier → Deep abyss.

local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

-- ========================================================
-- WORLD DIMENSIONS
-- ========================================================
local WORLD_X_MIN, WORLD_X_MAX = -3000, 3000   -- 6000 wide
local WORLD_Z_MIN, WORLD_Z_MAX = -1000, 1000   -- 2000 deep

-- Vertical layer boundaries
local SURFACE_TOP = 200      -- top of sky (islands cap out here)
local WATER_LINE = 0         -- sea level
local SURFACE_FLOOR = -300   -- bottom of surface biomes / top of mid-water
local CEILING_TOP = -500     -- top of rock barrier
local CEILING_BOTTOM = -700  -- bottom of rock barrier (start of deep)
local DEEP_FLOOR = -1450     -- abyss floor (just above safety baseplate)

-- Surface biome regions (X ranges)
local ARCTIC_X = {-3000, -1000}
local OCEAN_X = {-1000, 1000}
local SWAMP_X = {1000, 3000}

-- ========================================================
-- HELPERS
-- ========================================================
local function fillChunked(xMin, xMax, yMin, yMax, zMin, zMax, material, chunkSize)
	chunkSize = chunkSize or 500
	for x = xMin, xMax - 1, chunkSize do
		for z = zMin, zMax - 1, chunkSize do
			local x2 = math.min(x + chunkSize, xMax)
			local z2 = math.min(z + chunkSize, zMax)
			local region = Region3.new(Vector3.new(x, yMin, z), Vector3.new(x2, yMax, z2))
			region = region:ExpandToGrid(4)
			Terrain:FillRegion(region, 4, material)
		end
	end
end

-- ========================================================
-- 1. WATER FILL (everything from surface down to deep floor)
-- ========================================================
print("[1/6] Filling water...")
fillChunked(WORLD_X_MIN, WORLD_X_MAX, DEEP_FLOOR, WATER_LINE, WORLD_Z_MIN, WORLD_Z_MAX, Enum.Material.Water)

-- ========================================================
-- 2. SEAFLOOR PER BIOME (sand/glacier/mud at Y = SURFACE_FLOOR)
-- ========================================================
print("[2/6] Painting seafloor per biome...")

-- Arctic seafloor: glacier with bumps
local arcticSeed = math.random() * 1000
for x = ARCTIC_X[1], ARCTIC_X[2], 60 do
	for z = WORLD_Z_MIN, WORLD_Z_MAX, 60 do
		local h = math.noise(x/300, z/300, arcticSeed) * 30 + 20
		Terrain:FillBlock(
			CFrame.new(x, SURFACE_FLOOR + h/2, z),
			Vector3.new(64, math.max(20, h), 64),
			Enum.Material.Glacier
		)
	end
end

-- Ocean seafloor: sand dunes
local oceanSeed = math.random() * 1000
for x = OCEAN_X[1], OCEAN_X[2], 60 do
	for z = WORLD_Z_MIN, WORLD_Z_MAX, 60 do
		local h = math.noise(x/300, z/300, oceanSeed) * 25 + 15
		Terrain:FillBlock(
			CFrame.new(x, SURFACE_FLOOR + h/2, z),
			Vector3.new(64, math.max(15, h), 64),
			Enum.Material.Sand
		)
	end
end

-- Swamp seafloor: mud, lumpier
local swampSeed = math.random() * 1000
for x = SWAMP_X[1], SWAMP_X[2], 60 do
	for z = WORLD_Z_MIN, WORLD_Z_MAX, 60 do
		local h = math.noise(x/200, z/200, swampSeed) * 35 + 25
		Terrain:FillBlock(
			CFrame.new(x, SURFACE_FLOOR + h/2, z),
			Vector3.new(64, math.max(25, h), 64),
			Enum.Material.Mud
		)
	end
end

-- ========================================================
-- 3. ISLANDS (above water, biome-specific)
-- ========================================================
print("[3/6] Generating islands...")

local function buildIsland(centerX, centerZ, radius, peakHeight, material, biomeName)
	local islandSeed = math.random() * 1000
	for x = centerX - radius, centerX + radius, 12 do
		for z = centerZ - radius, centerZ + radius, 12 do
			local dx = (x - centerX) / radius
			local dz = (z - centerZ) / radius
			local distFromCenter = math.sqrt(dx*dx + dz*dz)
			if distFromCenter < 1 then
				-- Falloff from peak at center to 0 at edge, plus noise
				local falloff = (1 - distFromCenter) ^ 1.5
				local noiseDetail = math.noise(x/50, z/50, islandSeed) * 8
				local height = peakHeight * falloff + noiseDetail
				if height > 2 then
					Terrain:FillBlock(
						CFrame.new(x, WATER_LINE + height/2 - 2, z),
						Vector3.new(14, height + 4, 14),
						material
					)
				end
			end
		end
	end
end

-- 3 Ocean islands (sandy beaches)
buildIsland(-700, -400, 300, 80, Enum.Material.Sand, "Ocean")
buildIsland(0, 500, 350, 100, Enum.Material.Sand, "Ocean")
buildIsland(700, -200, 280, 70, Enum.Material.Sand, "Ocean")

-- 2 Arctic islands (glacier/snow)
buildIsland(-2500, 200, 280, 120, Enum.Material.Glacier, "Arctic")
buildIsland(-1500, -500, 250, 90, Enum.Material.Snow, "Arctic")

-- 3 Swamp islands (low, muddy, with grass on top)
buildIsland(1500, 300, 320, 40, Enum.Material.Mud, "Swamp")
buildIsland(2200, -400, 280, 50, Enum.Material.Ground, "Swamp")
buildIsland(2700, 600, 240, 35, Enum.Material.LeafyGrass, "Swamp")

-- ========================================================
-- 4. ROCK CEILING BARRIER (jagged, opaque, separates Mid-Water from Deep)
-- ========================================================
print("[4/6] Forging rock ceiling barrier...")

local ceilingSeed = math.random() * 1000
for x = WORLD_X_MIN, WORLD_X_MAX, 50 do
	for z = WORLD_Z_MIN, WORLD_Z_MAX, 50 do
		-- Jagged top and bottom surfaces, ~200 studs thick
		local topJag = math.noise(x/250, z/250, ceilingSeed) * 40
		local botJag = math.noise(x/250, z/250, ceilingSeed + 100) * 40
		local top = CEILING_TOP + topJag
		local bottom = CEILING_BOTTOM + botJag
		local thickness = top - bottom
		local centerY = (top + bottom) / 2
		Terrain:FillBlock(
			CFrame.new(x, centerY, z),
			Vector3.new(54, thickness, 54),
			Enum.Material.Rock
		)
	end
end

-- ========================================================
-- 5. CARVE TRENCH TUNNELS (6 vertical shafts through the ceiling)
-- ========================================================
print("[5/6] Carving 6 trench tunnels...")

-- Tunnel positions: spread across X axis, varied Z
local tunnels = {
	{x = -2300, z = -200, radius = 80},
	{x = -1400, z = 400, radius = 90},
	{x = -500, z = -500, radius = 100},
	{x = 400, z = 300, radius = 95},
	{x = 1300, z = -400, radius = 85},
	{x = 2200, z = 200, radius = 90},
}

for _, t in ipairs(tunnels) do
	-- Carve a wide cylinder of air through the rock barrier
	-- Use overlapping balls for an organic, jagged tunnel shape
	for y = CEILING_TOP - 60, CEILING_BOTTOM + 60, 30 do
		local jitterX = math.noise(y/100, t.x/100) * 20
		local jitterZ = math.noise(y/100, t.z/100 + 50) * 20
		Terrain:FillBall(
			Vector3.new(t.x + jitterX, y, t.z + jitterZ),
			t.radius,
			Enum.Material.Air
		)
	end
	-- Refill with water (so player can swim through, not float in vacuum)
	for y = CEILING_TOP - 60, CEILING_BOTTOM + 60, 30 do
		local jitterX = math.noise(y/100, t.x/100) * 20
		local jitterZ = math.noise(y/100, t.z/100 + 50) * 20
		Terrain:FillBall(
			Vector3.new(t.x + jitterX, y, t.z + jitterZ),
			t.radius - 5,
			Enum.Material.Water
		)
	end
end

-- ========================================================
-- 6. DEEP ABYSS FLOOR (rocky, dramatic ridges)
-- ========================================================
print("[6/6] Sculpting abyss floor...")

local deepSeed = math.random() * 1000
for x = WORLD_X_MIN, WORLD_X_MAX, 80 do
	for z = WORLD_Z_MIN, WORLD_Z_MAX, 80 do
		local h = math.noise(x/400, z/400, deepSeed) * 80 + 50
		Terrain:FillBlock(
			CFrame.new(x, DEEP_FLOOR + h/2, z),
			Vector3.new(84, math.max(50, h), 84),
			Enum.Material.Basalt
		)
	end
end

-- A few dramatic basalt spires
for i = 1, 12 do
	local sx = math.random(WORLD_X_MIN + 200, WORLD_X_MAX - 200)
	local sz = math.random(WORLD_Z_MIN + 200, WORLD_Z_MAX - 200)
	local height = math.random(150, 350)
	Terrain:FillBlock(
		CFrame.new(sx, DEEP_FLOOR + height/2, sz),
		Vector3.new(math.random(60, 120), height, math.random(60, 120)),
		Enum.Material.Basalt
	)
end

print(string.rep("=", 50))
print("TERRAIN BUILD COMPLETE")
print(string.rep("=", 50))
print("Layers painted: Sky, Surface biomes, Mid-Water, Rock ceiling, Deep abyss")
print("Tunnels carved: 6")
print("Islands generated: 8 (3 Ocean, 2 Arctic, 3 Swamp)")
print(string.rep("=", 50))

script.Disabled = true
