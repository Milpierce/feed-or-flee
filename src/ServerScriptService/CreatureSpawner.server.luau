-- CreatureSpawner (Script in ServerScriptService)
-- Replaces the default Roblox character with a fish creature.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CreatureData = require(ReplicatedStorage:WaitForChild("CreatureData"))
local CreatureBuilder = require(ReplicatedStorage:WaitForChild("CreatureBuilder"))

-- Disable default character spawning at the service level
Players.CharacterAutoLoads = false

local playerCreature = {}

local function getSpawnCFrame()
	local oceanZone = Workspace:WaitForChild("World"):WaitForChild("OceanZone")
	local pos = oceanZone.Position + Vector3.new(
		math.random(-200, 200),
		math.random(-100, 100),
		math.random(-200, 200)
	)
	return CFrame.new(pos)
end

local function spawnAsCreature(player, creatureName)
	creatureName = creatureName or CreatureData.StartingCreature
	local data = CreatureData.Creatures[creatureName]
	if not data then warn("Bad creature: " .. tostring(creatureName)) return end

	if player.Character then
		player.Character:Destroy()
		player.Character = nil
	end

	local model = CreatureBuilder.Build(creatureName)
	model.Name = player.Name

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = data.health
	humanoid.Health = data.health
	humanoid.WalkSpeed = data.speed
	humanoid.JumpPower = 0
	humanoid.AutoRotate = true
	humanoid.DisplayName = data.displayName
	humanoid.HealthDisplayDistance = 100
	humanoid.NameDisplayDistance = 100
	humanoid.Parent = model

	local body = model.PrimaryPart
	body.Name = "HumanoidRootPart"

	model:PivotTo(getSpawnCFrame())
	model.Parent = Workspace
	player.Character = model

	model:SetAttribute("CreatureName", creatureName)
	model:SetAttribute("Tier", data.tier)
	model:SetAttribute("XP", 0)
	playerCreature[player] = creatureName

	humanoid.Died:Connect(function()
		task.wait(2)
		if player.Parent then
			spawnAsCreature(player, playerCreature[player] or CreatureData.StartingCreature)
		end
	end)

	print(player.Name .. " spawned as " .. data.displayName .. " (Tier " .. data.tier .. ")")
end

local function onPlayerAdded(player)
	spawnAsCreature(player, CreatureData.StartingCreature)
end

-- Handle players who already joined before this script ran (Studio play case)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	playerCreature[player] = nil
end)

_G.SpawnAsCreature = spawnAsCreature
