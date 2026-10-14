-- WorldGridBuilder (Script in ServerScriptService)
-- Builds the 5 biome zones and folders. Runs once, then disables itself.

local Workspace = game:GetService("Workspace")

-- Create folders
local function getOrMakeFolder(name)
	local f = Workspace:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = Workspace
	end
	return f
end

local worldFolder = getOrMakeFolder("World")
getOrMakeFolder("StaticTerrain")
getOrMakeFolder("InteractiveObjects")

-- Zone definitions: {name, size, position, color}
local zones = {
	{"ArcticZone", Vector3.new(2000,1000,2000), Vector3.new(-2000,0,0), Color3.fromRGB(180,210,255)},
	{"OceanZone",  Vector3.new(2000,1000,2000), Vector3.new(0,0,0),     Color3.fromRGB(0,150,255)},
	{"SwampZone",  Vector3.new(2000,1000,2000), Vector3.new(2000,0,0),  Color3.fromRGB(60,80,40)},
	{"DeepZone",   Vector3.new(6000,1000,2000), Vector3.new(0,-1000,0), Color3.fromRGB(5,5,20)},
	{"SkyZone",    Vector3.new(6000,500,2000),  Vector3.new(0,750,0),   Color3.fromRGB(255,255,255)},
}

for _, z in ipairs(zones) do
	local existing = worldFolder:FindFirstChild(z[1])
	if existing then existing:Destroy() end
	local p = Instance.new("Part")
	p.Name = z[1]
	p.Size = z[2]
	p.Position = z[3]
	p.Color = z[4]
	p.Transparency = 0.8
	p.CanCollide = false
	p.CanTouch = true
	p.Anchored = true
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = worldFolder
end

-- Move the Baseplate to act as the safety floor
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate.Position = Vector3.new(baseplate.Position.X, -1500, baseplate.Position.Z)
end

print("World grid built successfully.")
script.Disabled = true
