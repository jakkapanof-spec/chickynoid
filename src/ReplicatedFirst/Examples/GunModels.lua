local GunModels = {}

local function MakePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Anchored = false
	return part
end

local function WeldParts(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
end

function GunModels.Build(weaponName)
	local builder = GunModels["Build" .. weaponName]
	if builder then
		return builder()
	end
	return GunModels.BuildPistol()
end

function GunModels.BuildPistol()
	local model = Instance.new("Model")
	model.Name = "PistolModel"

	local grip = MakePart("Grip", Vector3.new(0.25, 0.55, 0.15), Color3.fromRGB(50, 50, 50))
	grip.Parent = model

	local barrel = MakePart("Barrel", Vector3.new(0.18, 0.18, 0.6), Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	barrel.CFrame = grip.CFrame * CFrame.new(0, 0.18, -0.3)
	barrel.Parent = model
	WeldParts(grip, barrel)

	model.PrimaryPart = grip
	return model
end

function GunModels.BuildShotgun()
	local model = Instance.new("Model")
	model.Name = "ShotgunModel"

	local grip = MakePart("Grip", Vector3.new(0.25, 0.5, 0.15), Color3.fromRGB(101, 67, 33))
	grip.Parent = model

	local body = MakePart("Body", Vector3.new(0.22, 0.22, 0.7), Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	body.CFrame = grip.CFrame * CFrame.new(0, 0.15, -0.35)
	body.Parent = model
	WeldParts(grip, body)

	local barrel = MakePart("Barrel", Vector3.new(0.26, 0.26, 0.9), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	barrel.CFrame = grip.CFrame * CFrame.new(0, 0.15, -0.9)
	barrel.Parent = model
	WeldParts(grip, barrel)

	model.PrimaryPart = grip
	return model
end

function GunModels.BuildAssaultRifle()
	local model = Instance.new("Model")
	model.Name = "AssaultRifleModel"

	local grip = MakePart("Grip", Vector3.new(0.2, 0.45, 0.15), Color3.fromRGB(30, 30, 30))
	grip.Parent = model

	local body = MakePart("Body", Vector3.new(0.2, 0.22, 0.6), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	body.CFrame = grip.CFrame * CFrame.new(0, 0.15, -0.25)
	body.Parent = model
	WeldParts(grip, body)

	local barrel = MakePart("Barrel", Vector3.new(0.12, 0.12, 0.8), Color3.fromRGB(50, 50, 50), Enum.Material.Metal)
	barrel.CFrame = grip.CFrame * CFrame.new(0, 0.15, -0.9)
	barrel.Parent = model
	WeldParts(grip, barrel)

	local stock = MakePart("Stock", Vector3.new(0.18, 0.18, 0.4), Color3.fromRGB(30, 30, 30))
	stock.CFrame = grip.CFrame * CFrame.new(0, 0.15, 0.25)
	stock.Parent = model
	WeldParts(grip, stock)

	model.PrimaryPart = grip
	return model
end

function GunModels.BuildSniper()
	local model = Instance.new("Model")
	model.Name = "SniperModel"

	local grip = MakePart("Grip", Vector3.new(0.2, 0.45, 0.15), Color3.fromRGB(34, 60, 34))
	grip.Parent = model

	local barrel = MakePart("Barrel", Vector3.new(0.1, 0.1, 1.4), Color3.fromRGB(50, 50, 50), Enum.Material.Metal)
	barrel.CFrame = grip.CFrame * CFrame.new(0, 0.15, -0.7)
	barrel.Parent = model
	WeldParts(grip, barrel)

	local scope = MakePart("Scope", Vector3.new(0.1, 0.14, 0.3), Color3.fromRGB(20, 20, 20), Enum.Material.Metal)
	scope.CFrame = grip.CFrame * CFrame.new(0, 0.27, -0.2)
	scope.Parent = model
	WeldParts(grip, scope)

	local stock = MakePart("Stock", Vector3.new(0.16, 0.2, 0.45), Color3.fromRGB(34, 60, 34))
	stock.CFrame = grip.CFrame * CFrame.new(0, 0.1, 0.3)
	stock.Parent = model
	WeldParts(grip, stock)

	model.PrimaryPart = grip
	return model
end

function GunModels.BuildRocketLauncher()
	local model = Instance.new("Model")
	model.Name = "RocketLauncherModel"

	local grip = MakePart("Grip", Vector3.new(0.2, 0.45, 0.15), Color3.fromRGB(75, 83, 32))
	grip.Parent = model

	local tube = MakePart("Tube", Vector3.new(0.35, 0.35, 1.2), Color3.fromRGB(75, 83, 32), Enum.Material.Metal)
	tube.CFrame = grip.CFrame * CFrame.new(0, 0.2, -0.4)
	tube.Parent = model
	WeldParts(grip, tube)

	local rear = MakePart("Rear", Vector3.new(0.38, 0.38, 0.15), Color3.fromRGB(50, 55, 25), Enum.Material.Metal)
	rear.CFrame = grip.CFrame * CFrame.new(0, 0.2, 0.2)
	rear.Parent = model
	WeldParts(grip, rear)

	model.PrimaryPart = grip
	return model
end

return GunModels
