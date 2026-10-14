-- BiomeAtmosphere (Script in ServerScriptService)
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local biomeSettings = {
	ArcticZone = {fog = Color3.fromRGB(180,210,255), fogEnd = 500},
	OceanZone  = {fog = Color3.fromRGB(0,150,255),   fogEnd = 400},
	SwampZone  = {fog = Color3.fromRGB(60,80,40),    fogEnd = 150},
	DeepZone   = {fog = Color3.fromRGB(5,5,20),      fogEnd = 60},
	SkyZone    = {fog = Color3.fromRGB(255,255,255), fogEnd = 2000},
}

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local currentBiome = nil

local function setBiome(biomeName)
	if biomeName == currentBiome then return end
	currentBiome = biomeName
	local data = biomeSettings[biomeName]
	if not data then return end

	TweenService:Create(Lighting, tweenInfo, {
		FogColor = data.fog,
		FogEnd = data.fogEnd,
	}):Play()
end

local worldFolder = Workspace:WaitForChild("World")
for biomeName, _ in pairs(biomeSettings) do
	local zone = worldFolder:WaitForChild(biomeName)
	zone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			setBiome(biomeName)
		end
	end)
end
