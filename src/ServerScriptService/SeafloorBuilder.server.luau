-- SeafloorBuilder (Script in ServerScriptService)
-- Builds biome-specific seafloor terrain. Chunks large operations to avoid voxel limits.

local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

-- Helper: clear a region by breaking it into chunks (FillRegion has a 4M voxel limit)
local function clearInChunks(xMin, xMax, yMin, yMax, zMin, zMax, chunkSize)
	chunkSize = chunkSize or 500
	for x = xMin, xMax - 1, chunkSize do
		for z = zMin, zMax - 1, chunkSize do
			local x2 = math.min(x + chunkSize, xMax)
			local z2 = math.min(z + chunkSize, zMax)
			local region = Region3.new(Vector3.new(x, yMin, z), Vector3.new(x2, yMax, z2))
			region = region:ExpandToGrid(4)
			Terrain:FillRegion(region, 4, Enum.Material.Air)
		end
	end
end

-- Helper: fill a region with material, in chunks
local function fillInChunks(xMin, xMax, yMin, yMax, zMin, zMax, material, chunkSize)
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

-- Helper: stamp a bumpy floor
local function stampFloor(xMin, xMax, zMin, zMax, baseY, thickness, material, bumpiness)
	local size = Vector3.new(xMax - xMin, thickness, zMax - zMin)
	local center = Vector3.new((xMin + xMax)/2, baseY - thickness/2, (zMin + zMax)/2)
	Terrain:FillBlock(CFrame.new(center), size, material)

	local numBumps = math.floor((xMax - xMin) * (zMax - zMin) / 40000)
	for _ = 1, numBumps do
		local bx = math.random(xMin, xMax)
		local bz = math.random(zMin, zMax)
		local bRadius = math.random(20, 60)
		local bHeight = math.random(5, bumpiness)
		Terrain:FillBall(Vector3.new(bx, baseY + bHeight/2, bz), bRadius, material)
	end
end

local function scatterAccents(xMin, xMax, zMin, zMax, baseY, material, count, sizeRange)
	for _ = 1, count do
		local ax = math.random(xMin, xMax)
		local az = math.random(zMin, zMax)
		local r = math.random(sizeRange[1], sizeRange[2])
		Terrain:FillBall(Vector3.new(ax, baseY + 5, az), r, material)
	end
end

print("Clearing build region (this may take a moment)...")
clearInChunks(-3000, 3000, -1500, -400, -1000, 1000)

-- ARCTIC
print("Building Arctic seafloor...")
stampFloor(-3000, -1000, -1000, 1000, -450, 50, Enum.Material.Glacier, 30)
scatterAccents(-3000, -1000, -1000, 1000, -445, Enum.Material.Snow, 25, {15, 40})

-- OCEAN
print("Building Ocean seafloor...")
stampFloor(-1000, 1000, -1000, 1000, -440, 60, Enum.Material.Sand, 40)
scatterAccents(-1000, 1000, -1000, 1000, -435, Enum.Material.Rock, 15, {20, 50})

-- SWAMP
print("Building Swamp seafloor...")
stampFloor(1000, 3000, -1000, 1000, -460, 40, Enum.Material.Mud, 25)
scatterAccents(1000, 3000, -1000, 1000, -455, Enum.Material.LeafyGrass, 30, {15, 35})
scatterAccents(1000, 3000, -1000, 1000, -455, Enum.Material.Ground, 20, {20, 40})

-- DEEP
print("Building Deep seafloor...")
stampFloor(-3000, 3000, -1000, 1000, -1380, 100, Enum.Material.Rock, 80)
scatterAccents(-3000, 3000, -1000, 1000, -1370, Enum.Material.Basalt, 40, {30, 80})
for i = 1, 8 do
	local rx = math.random(-2800, 2800)
	local rz = math.random(-800, 800)
	Terrain:FillBlock(
		CFrame.new(rx, -1340, rz) * CFrame.Angles(0, math.rad(math.random(0, 180)), math.rad(math.random(-15, 15))),
		Vector3.new(math.random(80, 200), math.random(40, 100), math.random(40, 80)),
		Enum.Material.Basalt
	)
end

-- WATER (also chunked)
print("Filling water in surface biomes...")
fillInChunks(-3000, 3000, -500, 400, -1000, 1000, Enum.Material.Water)

print("Filling water in Deep zone...")
fillInChunks(-3000, 3000, -1500, -500, -1000, 1000, Enum.Material.Water)

print("Seafloor build complete!")
script.Disabled = true
