-- WorldCleanup (Script in ServerScriptService)
-- Wipes the old world so the new TerrainBuilder can paint fresh.
-- Run ONCE, then disable or delete this script.

local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

print("=== STARTING WORLD CLEANUP ===")

-- 1. Clear all terrain in build region (chunked to avoid voxel limit)
local function clearTerrainChunks(xMin, xMax, yMin, yMax, zMin, zMax)
	local chunk = 500
	for x = xMin, xMax - 1, chunk do
		for z = zMin, zMax - 1, chunk do
			local x2 = math.min(x + chunk, xMax)
			local z2 = math.min(z + chunk, zMax)
			local region = Region3.new(Vector3.new(x, yMin, z), Vector3.new(x2, yMax, z2))
			region = region:ExpandToGrid(4)
			Terrain:FillRegion(region, 4, Enum.Material.Air)
		end
	end
end

print("Clearing terrain (this takes a moment)...")
clearTerrainChunks(-3500, 3500, -1600, 400, -1500, 1500)
print("Terrain cleared.")

-- 2. Delete old World folder (zones)
local world = Workspace:FindFirstChild("World")
if world then
	world:Destroy()
	print("Old World folder deleted.")
end

-- 3. Delete old StaticTerrain (decorations)
local staticTerrain = Workspace:FindFirstChild("StaticTerrain")
if staticTerrain then
	staticTerrain:Destroy()
	print("Old StaticTerrain folder deleted.")
end

-- 4. Delete old food orbs
local food = Workspace:FindFirstChild("FoodOrbs")
if food then
	food:Destroy()
	print("Old FoodOrbs folder deleted.")
end

-- 5. Delete old ambient life
local ambient = Workspace:FindFirstChild("AmbientLife")
if ambient then
	ambient:Destroy()
	print("Old AmbientLife folder deleted.")
end

-- 6. Disable old world-building scripts so they don't fight the new ones
local sss = game:GetService("ServerScriptService")
for _, scriptName in ipairs({"WorldGridBuilder", "SeafloorBuilder", "WorldDecorator", "AmbientLife"}) do
	local s = sss:FindFirstChild(scriptName)
	if s then
		s.Disabled = true
		print("Disabled: " .. scriptName)
	end
end

print("=== CLEANUP COMPLETE ===")
print("Now ready to run the new TerrainBuilder.")

script.Disabled = true
