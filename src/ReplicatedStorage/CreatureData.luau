-- CreatureData (ModuleScript in ReplicatedStorage)
-- Single source of truth for every creature's stats and visuals.

local CreatureData = {}

-- Biome constants
CreatureData.Biomes = {
	OCEAN  = "OceanZone",
	ARCTIC = "ArcticZone",
	SWAMP  = "SwampZone",
	DEEP   = "DeepZone",
	SKY    = "SkyZone",
}

-- Each creature: stats + visual recipe
-- xpToEvolve = how much XP needed to tier up FROM this creature
-- speed = studs/second base swim speed
-- bodySize = main body part size (Vector3)
-- bodyColor / finColor = visual palette
-- habitats = biomes where creature takes NO damage; outside these, takes habitat damage
-- canBreathe = "water" (drowns in air), "both" (mammals), "air" (none in v1)
CreatureData.Creatures = {
	-- ===== TIER 1 =====
	Shrimp = {
		tier = 1, displayName = "Shrimp",
		health = 30, speed = 24, damage = 2,
		xpToEvolve = 50,
		bodySize = Vector3.new(2, 1, 1), bodyColor = Color3.fromRGB(255, 150, 130),
		finColor = Color3.fromRGB(220, 100, 90),
		habitats = {"OceanZone", "SwampZone"}, canBreathe = "water",
	},
	Minnow = {
		tier = 1, displayName = "Minnow",
		health = 25, speed = 28, damage = 1,
		xpToEvolve = 50,
		bodySize = Vector3.new(2, 1, 1), bodyColor = Color3.fromRGB(180, 200, 220),
		finColor = Color3.fromRGB(140, 160, 180),
		habitats = {"OceanZone"}, canBreathe = "water",
	},
	Krill = {
		tier = 1, displayName = "Krill",
		health = 25, speed = 26, damage = 1,
		xpToEvolve = 50,
		bodySize = Vector3.new(1.5, 0.8, 0.8), bodyColor = Color3.fromRGB(255, 180, 160),
		finColor = Color3.fromRGB(220, 140, 120),
		habitats = {"ArcticZone", "OceanZone"}, canBreathe = "water",
	},

	-- ===== TIER 2 =====
	Sardine = {
		tier = 2, displayName = "Sardine",
		health = 60, speed = 30, damage = 8,
		xpToEvolve = 150,
		bodySize = Vector3.new(4, 1.5, 1.5), bodyColor = Color3.fromRGB(180, 200, 220),
		finColor = Color3.fromRGB(100, 130, 160),
		habitats = {"OceanZone"}, canBreathe = "water",
	},
	Mackerel = {
		tier = 2, displayName = "Mackerel",
		health = 70, speed = 32, damage = 10,
		xpToEvolve = 150,
		bodySize = Vector3.new(5, 1.8, 1.8), bodyColor = Color3.fromRGB(80, 110, 140),
		finColor = Color3.fromRGB(40, 60, 90),
		habitats = {"OceanZone", "ArcticZone"}, canBreathe = "water",
	},
	Piranha = {
		tier = 2, displayName = "Piranha",
		health = 65, speed = 30, damage = 14,
		xpToEvolve = 150,
		bodySize = Vector3.new(4, 2, 1.8), bodyColor = Color3.fromRGB(140, 80, 60),
		finColor = Color3.fromRGB(180, 60, 60),
		habitats = {"SwampZone"}, canBreathe = "water",
	},

	-- ===== TIER 3 =====
	Tuna = {
		tier = 3, displayName = "Tuna",
		health = 140, speed = 36, damage = 22,
		xpToEvolve = 400,
		bodySize = Vector3.new(8, 3, 3), bodyColor = Color3.fromRGB(50, 70, 100),
		finColor = Color3.fromRGB(200, 220, 80),
		habitats = {"OceanZone"}, canBreathe = "water",
	},
	Seal = {
		tier = 3, displayName = "Seal",
		health = 160, speed = 32, damage = 24,
		xpToEvolve = 400,
		bodySize = Vector3.new(7, 3, 3), bodyColor = Color3.fromRGB(80, 80, 90),
		finColor = Color3.fromRGB(60, 60, 70),
		habitats = {"ArcticZone"}, canBreathe = "both",
	},
	Crocodile = {
		tier = 3, displayName = "Crocodile",
		health = 180, speed = 26, damage = 32,
		xpToEvolve = 400,
		bodySize = Vector3.new(10, 2, 2.5), bodyColor = Color3.fromRGB(60, 80, 50),
		finColor = Color3.fromRGB(40, 60, 30),
		habitats = {"SwampZone"}, canBreathe = "both",
	},

	-- ===== TIER 4 =====
	Hammerhead = {
		tier = 4, displayName = "Hammerhead Shark",
		health = 280, speed = 38, damage = 45,
		xpToEvolve = 1000,
		bodySize = Vector3.new(12, 3.5, 3.5), bodyColor = Color3.fromRGB(110, 120, 130),
		finColor = Color3.fromRGB(70, 80, 90),
		habitats = {"OceanZone"}, canBreathe = "water",
	},
	PolarBear = {
		tier = 4, displayName = "Polar Bear",
		health = 320, speed = 30, damage = 50,
		xpToEvolve = 1000,
		bodySize = Vector3.new(8, 5, 4), bodyColor = Color3.fromRGB(245, 245, 250),
		finColor = Color3.fromRGB(220, 220, 225),
		habitats = {"ArcticZone"}, canBreathe = "both",
	},
	Anglerfish = {
		tier = 4, displayName = "Anglerfish",
		health = 260, speed = 24, damage = 55,
		xpToEvolve = 1000,
		bodySize = Vector3.new(8, 5, 5), bodyColor = Color3.fromRGB(40, 30, 50),
		finColor = Color3.fromRGB(80, 50, 100),
		habitats = {"DeepZone"}, canBreathe = "water",
	},

	-- ===== TIER 5 (APEX) =====
	GreatWhite = {
		tier = 5, displayName = "Great White Shark",
		health = 500, speed = 42, damage = 80,
		xpToEvolve = nil,  -- max tier
		bodySize = Vector3.new(18, 5, 5), bodyColor = Color3.fromRGB(140, 145, 155),
		finColor = Color3.fromRGB(90, 95, 105),
		habitats = {"OceanZone", "ArcticZone"}, canBreathe = "water",
	},
	Orca = {
		tier = 5, displayName = "Orca",
		health = 550, speed = 44, damage = 75,
		xpToEvolve = nil,
		bodySize = Vector3.new(20, 5, 5), bodyColor = Color3.fromRGB(20, 20, 25),
		finColor = Color3.fromRGB(245, 245, 250),
		habitats = {"OceanZone", "ArcticZone"}, canBreathe = "both",
	},
	GiantSquid = {
		tier = 5, displayName = "Giant Squid",
		health = 480, speed = 38, damage = 90,
		xpToEvolve = nil,
		bodySize = Vector3.new(14, 4, 4), bodyColor = Color3.fromRGB(180, 60, 80),
		finColor = Color3.fromRGB(120, 40, 60),
		habitats = {"DeepZone", "OceanZone"}, canBreathe = "water",
	},
}

-- Helper: get all creatures of a specific tier
function CreatureData.GetByTier(tier)
	local list = {}
	for name, data in pairs(CreatureData.Creatures) do
		if data.tier == tier then
			table.insert(list, name)
		end
	end
	return list
end

-- Helper: which creatures can a tier-N creature evolve INTO?
function CreatureData.GetEvolutionOptions(currentCreatureName)
	local current = CreatureData.Creatures[currentCreatureName]
	if not current or not current.xpToEvolve then return {} end
	return CreatureData.GetByTier(current.tier + 1)
end

-- Helper: can creature A eat creature B? (A's tier >= B's tier)
function CreatureData.CanEat(predatorName, preyName)
	local pred = CreatureData.Creatures[predatorName]
	local prey = CreatureData.Creatures[preyName]
	if not pred or not prey then return false end
	return pred.tier >= prey.tier
end

-- Default starting creature for new players
CreatureData.StartingCreature = "Shrimp"

return CreatureData
