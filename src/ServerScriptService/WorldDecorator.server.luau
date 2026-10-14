-- WorldDecorator (Script in ServerScriptService)
-- Builds clustered points-of-interest with food orbs scattered for Phase 7.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local worldFolder = Workspace:WaitForChild("World", 10)
if not worldFolder then warn("World folder missing"); script.Disabled = true; return end

local staticTerrain = Workspace:FindFirstChild("StaticTerrain") or Instance.new("Folder")
staticTerrain.Name = "StaticTerrain"
staticTerrain.Parent = Workspace

-- Folder for food orbs (separate so AmbientLife/eating system can find them fast)
local foodFolder = Workspace:FindFirstChild("FoodOrbs") or Instance.new("Folder")
foodFolder.Name = "FoodOrbs"
foodFolder.Parent = Workspace

-- ========================================================
-- CONFIG: hotspot-based density
-- ========================================================
-- hotspots = number of point-of-interest clusters
-- itemsPerHotspot = how packed each hotspot is
local biomeConfig = {
	OceanZone  = {floorY = -440, sandColor = Color3.fromRGB(220, 200, 160), sandMaterial = Enum.Material.Sand,    hotspots = 6, reefsPerHotspot = 4, wrecks = 4, caves = 3, flora = 800,  food = 250},
	ArcticZone = {floorY = -450, sandColor = Color3.fromRGB(220, 230, 240), sandMaterial = Enum.Material.Glacier, hotspots = 4, reefsPerHotspot = 3, wrecks = 2, caves = 2, flora = 500,  food = 180},
	SwampZone  = {floorY = -460, sandColor = Color3.fromRGB(80, 70, 50),    sandMaterial = Enum.Material.Mud,     hotspots = 5, reefsPerHotspot = 4, wrecks = 2, caves = 2, flora = 1000, food = 300},
	DeepZone   = {floorY = -1380, sandColor = Color3.fromRGB(40, 40, 50),   sandMaterial = Enum.Material.Slate,   hotspots = 5, reefsPerHotspot = 3, wrecks = 6, caves = 8, flora = 600,  food = 200},
}

-- ========================================================
-- HELPERS
-- ========================================================
local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	return p
end

local function addGlow(part, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 2
	light.Range = range or 20
	light.Parent = part
end

local function randomPosOnFloor(zonePart, floorY)
	local pos = zonePart.Position
	local size = zonePart.Size
	return Vector3.new(
		pos.X + math.random(-size.X/2 + 100, size.X/2 - 100),
		floorY,
		pos.Z + math.random(-size.Z/2 + 100, size.Z/2 - 100)
	)
end

-- Pick N hotspot centers, evenly spread (not random) so we get clusters with channels between them
local function pickHotspotCenters(zonePart, count, floorY)
	local centers = {}
	local pos = zonePart.Position
	local size = zonePart.Size
	for i = 1, count do
		-- Jittered grid placement: divide zone into rough cells, place one hotspot per cell with random offset
		local cx = pos.X + ((i - 0.5) / count - 0.5) * (size.X - 400)
		local cz = pos.Z + (math.random() - 0.5) * (size.Z - 400)
		table.insert(centers, Vector3.new(cx, floorY, cz))
	end
	return centers
end

-- Pos near a hotspot center (within radius)
local function nearHotspot(center, radius, floorY)
	local angle = math.rad(math.random(0, 360))
	local dist = math.random(0, radius)
	return Vector3.new(
		center.X + math.cos(angle) * dist,
		floorY,
		center.Z + math.sin(angle) * dist
	)
end

-- ========================================================
-- DUNES (math.noise)
-- ========================================================
local function buildDunes(zonePart, config, biomeFolder)
	local pos = zonePart.Position
	local size = zonePart.Size
	local seed = math.random() * 1000
	local step = 80
	local count = 0
	for x = -size.X/2, size.X/2, step do
		for z = -size.Z/2, size.Z/2, step do
			local nx = (pos.X + x) / 400
			local nz = (pos.Z + z) / 400
			local height = math.noise(nx, nz, seed) * 25 + 10
			local dune = newPart({
				Name = "SandDune",
				Size = Vector3.new(step + 10, math.max(8, height), step + 10),
				Position = Vector3.new(pos.X + x, config.floorY + height/2 - 10, pos.Z + z),
				Material = config.sandMaterial,
				Color = config.sandColor,
			})
			dune.Parent = biomeFolder
			count = count + 1
		end
	end
	return count
end

-- ========================================================
-- REEF (slightly bigger and richer than before)
-- ========================================================
local reefPalette = {
	Color3.fromRGB(255, 100, 150), Color3.fromRGB(255, 180, 80),
	Color3.fromRGB(120, 220, 255), Color3.fromRGB(180, 80, 220),
	Color3.fromRGB(255, 220, 100), Color3.fromRGB(80, 255, 180),
}

local function buildReef(centerPos, biomeFolder, isDeep)
	local reefSize = math.random(18, 35)
	local mound = newPart({
		Name = "ReefBase", Shape = Enum.PartType.Ball,
		Size = Vector3.new(reefSize * 4, reefSize * 1.5, reefSize * 4),
		Position = centerPos,
		Material = Enum.Material.Rock, Color = Color3.fromRGB(150, 130, 100),
	})
	mound.Parent = biomeFolder

	for i = 1, reefSize do
		local angle = math.rad(math.random(0, 360))
		local dist = math.random(5, reefSize * 2)
		local cPos = centerPos + Vector3.new(math.cos(angle) * dist, math.random(5, 30), math.sin(angle) * dist)
		local color = reefPalette[math.random(1, #reefPalette)]
		local coral = newPart({
			Name = "Coral",
			Shape = (math.random() > 0.5) and Enum.PartType.Block or Enum.PartType.Cylinder,
			Size = Vector3.new(math.random(3, 9), math.random(8, 30), math.random(3, 9)),
			Position = cPos,
			Material = isDeep and Enum.Material.Neon or Enum.Material.Slate,
			Color = color,
			Transparency = isDeep and 0.1 or 0,
		})
		coral.CFrame = CFrame.new(cPos) * CFrame.Angles(math.rad(math.random(-20, 20)), math.rad(math.random(0, 360)), math.rad(math.random(-20, 20)))
		coral.Parent = biomeFolder
		if isDeep or math.random() < 0.25 then addGlow(coral, color, 1.5, 15) end
	end

	for i = 1, math.random(4, 8) do
		local color = reefPalette[math.random(1, #reefPalette)]
		local angle = math.rad(math.random(0, 360))
		local dist = math.random(0, reefSize)
		local anem = newPart({
			Name = "Anemone", Shape = Enum.PartType.Ball,
			Size = Vector3.new(math.random(6, 14), math.random(5, 10), math.random(6, 14)),
			Position = centerPos + Vector3.new(math.cos(angle) * dist, 5, math.sin(angle) * dist),
			Material = Enum.Material.Neon, Color = color, Transparency = 0.2,
		})
		CollectionService:AddTag(anem, "HidingSpot")
		addGlow(anem, color, 1, 12)
		anem.Parent = biomeFolder
	end

	for i = 1, math.random(3, 6) do
		local angle = math.rad(math.random(0, 360))
		local dist = math.random(0, reefSize * 2)
		local sponge = newPart({
			Name = "Sponge", Shape = Enum.PartType.Ball,
			Size = Vector3.new(math.random(5, 11), math.random(6, 16), math.random(5, 11)),
			Position = centerPos + Vector3.new(math.cos(angle) * dist, math.random(3, 14), math.sin(angle) * dist),
			Material = Enum.Material.Foil,
			Color = Color3.fromRGB(math.random(150, 255), math.random(100, 200), math.random(100, 255)),
		})
		sponge.Parent = biomeFolder
	end
end

-- ========================================================
-- MANGROVE GROVE (Swamp special, tangled roots)
-- ========================================================
local function buildMangroveGrove(centerPos, biomeFolder)
	for i = 1, math.random(8, 15) do
		local angle = math.rad(math.random(0, 360))
		local dist = math.random(0, 40)
		local rootPos = centerPos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		local height = math.random(40, 90)
		local root = newPart({
			Name = "MangroveRoot", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, math.random(3, 6), math.random(3, 6)),
			CFrame = CFrame.new(rootPos + Vector3.new(0, height/2, 0))
				* CFrame.Angles(math.rad(math.random(-30, 30)), math.rad(math.random(0, 360)), math.rad(80 + math.random(-15, 15))),
			Material = Enum.Material.Wood, Color = Color3.fromRGB(50, 35, 20),
		})
		CollectionService:AddTag(root, "HidingSpot")
		root.Parent = biomeFolder
	end
end

-- ========================================================
-- SHIPWRECK
-- ========================================================
local function buildShipwreck(centerPos, biomeFolder)
	local wreckFolder = Instance.new("Folder")
	wreckFolder.Name = "Shipwreck"
	CollectionService:AddTag(wreckFolder, "Shipwreck")
	wreckFolder.Parent = biomeFolder

	local tilt = math.rad(math.random(-25, 25))
	local yaw = math.rad(math.random(0, 360))
	local buried = math.random() < 0.5
	local sinkDepth = buried and -10 or 0

	local hullCFrame = CFrame.new(centerPos + Vector3.new(0, 15 + sinkDepth, 0)) * CFrame.Angles(tilt, yaw, 0)
	local hull = newPart({
		Name = "Hull", Size = Vector3.new(80, 25, 25),
		CFrame = hullCFrame, Material = Enum.Material.Wood, Color = Color3.fromRGB(60, 40, 25),
	})
	hull.Parent = wreckFolder

	for i = -3, 3 do
		local rib = newPart({
			Name = "Rib", Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 2, 2),
			CFrame = hullCFrame * CFrame.new(i * 12, 12, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 55, 35),
		})
		rib.Parent = wreckFolder
	end

	if not buried then
		for i = 1, 2 do
			local mast = newPart({
				Name = "Mast", Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, 3, 3),
				CFrame = hullCFrame * CFrame.new(i * 20 - 30, 30, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Material = Enum.Material.Wood, Color = Color3.fromRGB(50, 35, 20),
			})
			mast.Parent = wreckFolder
		end
	end

	for i = 1, 8 do
		local color = reefPalette[math.random(1, #reefPalette)]
		local patch = newPart({
			Name = "Encrustation", Shape = Enum.PartType.Ball,
			Size = Vector3.new(math.random(3, 6), math.random(3, 6), math.random(3, 6)),
			CFrame = hullCFrame * CFrame.new(math.random(-35, 35), math.random(-10, 12), math.random(-12, 12)),
			Material = Enum.Material.Slate, Color = color,
		})
		patch.Parent = wreckFolder
	end

	local chest = newPart({
		Name = "TreasureChest", Size = Vector3.new(8, 6, 5),
		CFrame = hullCFrame * CFrame.new(math.random(-30, 30), 5, 0),
		Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 40),
	})
	chest:SetAttribute("Loot", math.random(50, 500))
	chest:SetAttribute("Opened", false)
	CollectionService:AddTag(chest, "TreasureChest")
	addGlow(chest, Color3.fromRGB(255, 215, 0), 1.5, 20)
	chest.Parent = wreckFolder

	-- Bubble emitter on the hull (atmospheric)
	local bubbleAttachment = Instance.new("Attachment", hull)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	bubbles.Size = NumberSequence.new(0.5, 1.5)
	bubbles.Lifetime = NumberRange.new(3, 6)
	bubbles.Rate = 4
	bubbles.Speed = NumberRange.new(2, 5)
	bubbles.SpreadAngle = Vector2.new(20, 20)
	bubbles.Acceleration = Vector3.new(0, 5, 0)
	bubbles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	bubbles.Parent = bubbleAttachment
end

-- ========================================================
-- CAVE SYSTEM
-- ========================================================
local function buildCave(centerPos, biomeFolder, isDeep)
	local caveFolder = Instance.new("Folder")
	caveFolder.Name = "DeepSeaCave"
	CollectionService:AddTag(caveFolder, "DeepSeaCave")
	caveFolder.Parent = biomeFolder

	local chambers = math.random(4, 6)
	local chamberPositions = {centerPos}
	local lastPos = centerPos

	for c = 1, chambers do
		local nextPos = lastPos + Vector3.new(math.random(-70, 70), math.random(-15, 15), math.random(-70, 70))
		table.insert(chamberPositions, nextPos)

		local chamber = newPart({
			Name = "CaveChamber", Shape = Enum.PartType.Ball,
			Size = Vector3.new(math.random(45, 75), math.random(35, 55), math.random(45, 75)),
			Position = nextPos, Material = Enum.Material.Rock,
			Color = Color3.fromRGB(60, 55, 70), Transparency = 0.3, CanCollide = false,
		})
		CollectionService:AddTag(chamber, "HidingSpot")
		chamber.Parent = caveFolder

		for i = 1, 8 do
			local angle = math.rad(math.random(0, 360))
			local r = chamber.Size.X / 2
			local color = reefPalette[math.random(1, #reefPalette)]
			local lining = newPart({
				Name = "CaveCoral",
				Size = Vector3.new(math.random(3, 6), math.random(6, 14), math.random(3, 6)),
				Position = nextPos + Vector3.new(math.cos(angle) * r * 0.8, math.random(-r/3, r/3), math.sin(angle) * r * 0.8),
				Material = Enum.Material.Neon, Color = color, Transparency = 0.1,
			})
			addGlow(lining, color, 2, 18)
			lining.Parent = caveFolder
		end

		if c > 1 then
			local prev = chamberPositions[c]
			local mid = (prev + nextPos) / 2
			local dir = (nextPos - prev)
			local tunnel = newPart({
				Name = "CaveTunnel", Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(dir.Magnitude, 18, 18),
				CFrame = CFrame.new(mid, nextPos) * CFrame.Angles(0, math.rad(90), 0),
				Material = Enum.Material.Rock, Color = Color3.fromRGB(50, 45, 60),
				Transparency = 0.3, CanCollide = false,
			})
			tunnel.Parent = caveFolder
		end

		lastPos = nextPos
	end
end

-- ========================================================
-- FLORA
-- ========================================================
local function buildFlora(zonePart, config, biomeFolder)
	for i = 1, config.flora do
		local pos = randomPosOnFloor(zonePart, config.floorY)
		local floraType = math.random(1, 3)
		local part

		if floraType == 1 then
			local height = math.random(20, 80)
			local color = (zonePart.Name == "SwampZone") and Color3.fromRGB(60, 40, 25)
				or (zonePart.Name == "ArcticZone") and Color3.fromRGB(150, 200, 220)
				or (zonePart.Name == "DeepZone") and Color3.fromRGB(80, 40, 120)
				or Color3.fromRGB(40, 130, 60)
			part = newPart({
				Name = "Kelp", Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(height, 2, 2),
				CFrame = CFrame.new(pos + Vector3.new(0, height/2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Material = Enum.Material.Grass, Color = color, Transparency = 0.3,
			})
			if zonePart.Name == "DeepZone" then
				addGlow(part, Color3.fromRGB(180, 80, 255), 1, 12)
			end
		elseif floraType == 2 then
			part = newPart({
				Name = "Seagrass", Shape = Enum.PartType.Ball,
				Size = Vector3.new(math.random(4, 8), math.random(6, 12), math.random(4, 8)),
				Position = pos + Vector3.new(0, 5, 0),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(math.random(40, 100), math.random(120, 200), math.random(40, 100)),
			})
		else
			local color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(150, 255))
			part = newPart({
				Name = "Bioluminescence", Shape = Enum.PartType.Ball,
				Size = Vector3.new(2, 2, 2),
				Position = pos + Vector3.new(0, math.random(5, 60), 0),
				Material = Enum.Material.Neon, Color = color, Transparency = 0.2,
			})
			addGlow(part, color, 1.5, 10)
		end
		part.Parent = biomeFolder
	end
end

-- ========================================================
-- FOOD ORBS (Phase 7 prep)
-- ========================================================
local foodTypes = {
	{name = "Algae",    color = Color3.fromRGB(100, 220, 100), xp = 5,  biomes = {OceanZone = true, SwampZone = true, ArcticZone = true}},
	{name = "Plankton", color = Color3.fromRGB(150, 230, 255), xp = 3,  biomes = {OceanZone = true, ArcticZone = true, SwampZone = true, DeepZone = true}},
	{name = "AbyssGlow", color = Color3.fromRGB(180, 80, 255), xp = 12, biomes = {DeepZone = true}},
}

local function spawnFood(zonePart, config, count)
	local pos = zonePart.Position
	local size = zonePart.Size
	for i = 1, count do
		-- Pick a food type valid for this biome
		local validTypes = {}
		for _, ft in ipairs(foodTypes) do
			if ft.biomes[zonePart.Name] then table.insert(validTypes, ft) end
		end
		local ft = validTypes[math.random(1, #validTypes)]

		local orb = newPart({
			Name = "FoodOrb", Shape = Enum.PartType.Ball,
			Size = Vector3.new(2, 2, 2),
			Position = Vector3.new(
				pos.X + math.random(-size.X/2 + 100, size.X/2 - 100),
				config.floorY + math.random(20, 400),
				pos.Z + math.random(-size.Z/2 + 100, size.Z/2 - 100)
			),
			Material = Enum.Material.Neon, Color = ft.color, Transparency = 0.2,
			CanCollide = false,
		})
		orb:SetAttribute("FoodType", ft.name)
		orb:SetAttribute("XPValue", ft.xp)
		CollectionService:AddTag(orb, "Food")
		addGlow(orb, ft.color, 1, 8)
		orb.Parent = foodFolder
	end
end

-- ========================================================
-- MARINE SNOW (atmospheric particles, biome-wide)
-- ========================================================
local function addMarineSnow(zonePart)
	-- Big invisible attachment in zone center, emits drifting particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = zonePart

	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(Color3.fromRGB(220, 230, 240))
	snow.Size = NumberSequence.new(0.3, 0.8)
	snow.Lifetime = NumberRange.new(8, 15)
	snow.Rate = 30
	snow.Speed = NumberRange.new(0.5, 2)
	snow.SpreadAngle = Vector2.new(180, 180)
	snow.Acceleration = Vector3.new(0, -1, 0)
	snow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Parent = attachment
end

-- ========================================================
-- MAIN BUILD
-- ========================================================
local stats = {dunes = 0, reefs = 0, wrecks = 0, caves = 0, flora = 0, food = 0, mangroves = 0}
local biomes = {"OceanZone", "ArcticZone", "SwampZone", "DeepZone"}

for _, biomeName in ipairs(biomes) do
	local zonePart = worldFolder:FindFirstChild(biomeName)
	local config = biomeConfig[biomeName]
	if zonePart and config then
		local biomeFolder = Instance.new("Folder")
		biomeFolder.Name = biomeName .. "_Decor"
		biomeFolder.Parent = staticTerrain

		print("[" .. biomeName .. "] Sculpting seafloor...")
		stats.dunes = stats.dunes + buildDunes(zonePart, config, biomeFolder)

		print("[" .. biomeName .. "] Placing " .. config.hotspots .. " hotspot clusters...")
		local hotspots = pickHotspotCenters(zonePart, config.hotspots, config.floorY)
		for _, hotspot in ipairs(hotspots) do
			-- Each hotspot: a cluster of reefs
			for r = 1, config.reefsPerHotspot do
				local reefPos = nearHotspot(hotspot, 80, config.floorY + 15)
				buildReef(reefPos, biomeFolder, biomeName == "DeepZone")
				stats.reefs = stats.reefs + 1
			end
			-- Swamp gets mangroves at hotspots
			if biomeName == "SwampZone" then
				buildMangroveGrove(hotspot, biomeFolder)
				stats.mangroves = stats.mangroves + 1
			end
		end

		print("[" .. biomeName .. "] Sinking " .. config.wrecks .. " shipwrecks...")
		for i = 1, config.wrecks do
			buildShipwreck(randomPosOnFloor(zonePart, config.floorY + 10), biomeFolder)
			stats.wrecks = stats.wrecks + 1
		end

		print("[" .. biomeName .. "] Carving " .. config.caves .. " cave systems...")
		for i = 1, config.caves do
			buildCave(randomPosOnFloor(zonePart, config.floorY + 30), biomeFolder, biomeName == "DeepZone")
			stats.caves = stats.caves + 1
		end

		print("[" .. biomeName .. "] Scattering " .. config.flora .. " flora...")
		buildFlora(zonePart, config, biomeFolder)
		stats.flora = stats.flora + config.flora

		print("[" .. biomeName .. "] Dropping " .. config.food .. " food orbs...")
		spawnFood(zonePart, config, config.food)
		stats.food = stats.food + config.food

		addMarineSnow(zonePart)
	end
end

print(string.rep("=", 50))
print("LIVING ECOSYSTEM POPULATED")
print(string.rep("=", 50))
print("Sand dunes:    " .. stats.dunes)
print("Coral reefs:   " .. stats.reefs)
print("Mangroves:     " .. stats.mangroves)
print("Shipwrecks:    " .. stats.wrecks)
print("Cave systems:  " .. stats.caves)
print("Flora:         " .. stats.flora)
print("Food orbs:     " .. stats.food .. "  (tagged 'Food')")
print(string.rep("=", 50))

script.Disabled = true
