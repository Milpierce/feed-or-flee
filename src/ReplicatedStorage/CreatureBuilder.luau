-- CreatureBuilder (ModuleScript in ReplicatedStorage)
-- Builds a fish model from CreatureData entries.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreatureData = require(ReplicatedStorage:WaitForChild("CreatureData"))

local CreatureBuilder = {}

local function newPart(name, size, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function weld(a, b, offset)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	b.CFrame = a.CFrame * (offset or CFrame.new())
end

-- Builds and returns a Model. PrimaryPart is the body block.
function CreatureBuilder.Build(creatureName)
	local data = CreatureData.Creatures[creatureName]
	if not data then warn("Unknown creature: " .. tostring(creatureName)) return nil end

	local model = Instance.new("Model")
	model.Name = creatureName

	-- Body (main hull)
	local body = newPart("Body", data.bodySize, data.bodyColor, Enum.Material.SmoothPlastic, model)
	body.Shape = Enum.PartType.Block
	model.PrimaryPart = body

	-- Tail fin (vertical triangle-ish, made from a wedge)
	local tail = Instance.new("WedgePart")
	tail.Name = "Tail"
	tail.Size = Vector3.new(data.bodySize.X * 0.4, data.bodySize.Y * 1.2, data.bodySize.Z * 0.3)
	tail.Color = data.finColor
	tail.Material = Enum.Material.SmoothPlastic
	tail.TopSurface = Enum.SurfaceType.Smooth
	tail.BottomSurface = Enum.SurfaceType.Smooth
	tail.CastShadow = false
	tail.Parent = model
	weld(body, tail, CFrame.new(-data.bodySize.X * 0.6, 0, 0) * CFrame.Angles(0, math.rad(180), 0))

	-- Top fin (dorsal)
	local dorsal = Instance.new("WedgePart")
	dorsal.Name = "Dorsal"
	dorsal.Size = Vector3.new(data.bodySize.X * 0.3, data.bodySize.Y * 0.8, data.bodySize.Z * 0.2)
	dorsal.Color = data.finColor
	dorsal.Material = Enum.Material.SmoothPlastic
	dorsal.TopSurface = Enum.SurfaceType.Smooth
	dorsal.BottomSurface = Enum.SurfaceType.Smooth
	dorsal.CastShadow = false
	dorsal.Parent = model
	weld(body, dorsal, CFrame.new(0, data.bodySize.Y * 0.6, 0))

	-- Eyes (two small black spheres near front)
	for i, side in ipairs({-1, 1}) do
		local eye = newPart("Eye" .. i, Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 20, 20), Enum.Material.Neon, model)
		eye.Shape = Enum.PartType.Ball
		weld(body, eye, CFrame.new(data.bodySize.X * 0.4, data.bodySize.Y * 0.2, side * data.bodySize.Z * 0.45))
	end

	-- Special: glow lure for Anglerfish
	if creatureName == "Anglerfish" then
		local lureRod = newPart("LureRod", Vector3.new(2, 0.2, 0.2), Color3.fromRGB(40, 30, 50), Enum.Material.SmoothPlastic, model)
		weld(body, lureRod, CFrame.new(data.bodySize.X * 0.6, data.bodySize.Y * 0.7, 0))
		local lure = newPart("Lure", Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(255, 240, 100), Enum.Material.Neon, model)
		lure.Shape = Enum.PartType.Ball
		weld(body, lure, CFrame.new(data.bodySize.X * 0.6 + 1, data.bodySize.Y * 0.7, 0))
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 240, 100)
		light.Brightness = 3
		light.Range = 20
		light.Parent = lure
	end

	-- Make all parts share the same collision (acts as one fish, not separate parts)
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			p.CanCollide = false  -- fish don't collide with each other
			p.Massless = true
		end
	end
	body.CanCollide = true  -- only main body collides with terrain
	body.Massless = false

	return model
end

return CreatureBuilder
