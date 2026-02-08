local Debris = game:GetService("Debris")

local BloodEffect = {}

function BloodEffect:Spawn(position, normal)
	if not position then
		return
	end

	local dir = normal or Vector3.new(0, 1, 0)

	-- Spawn red blood particles
	for _ = 1, 8 do
		local part = Instance.new("Part")
		part.Name = "Blood"
		part.Size = Vector3.new(0.15, 0.15, 0.15)
		part.Shape = Enum.PartType.Ball
		part.Color = Color3.fromRGB(180, 0, 0)
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = false
		part.CFrame = CFrame.new(position)
		part.Parent = game.Workspace

		-- Random scatter velocity
		local scatter = Vector3.new(
			(math.random() - 0.5) * 12,
			math.random() * 8 + 2,
			(math.random() - 0.5) * 12
		)
		local velocity = dir * 6 + scatter

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.MaxForce = 1000
		linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVelocity.VectorVelocity = velocity

		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		linearVelocity.Attachment0 = attachment
		linearVelocity.Parent = part

		-- Disable velocity after a short moment so gravity takes over
		task.delay(0.05, function()
			if linearVelocity and linearVelocity.Parent then
				linearVelocity:Destroy()
			end
		end)

		-- Auto-remove after 1 second
		Debris:AddItem(part, 1)
	end

	-- Spawn a bigger blood splash at hit point
	local splash = Instance.new("Part")
	splash.Name = "BloodSplash"
	splash.Size = Vector3.new(0.6, 0.6, 0.6)
	splash.Shape = Enum.PartType.Ball
	splash.Color = Color3.fromRGB(200, 0, 0)
	splash.Material = Enum.Material.Neon
	splash.Transparency = 0.3
	splash.CanCollide = false
	splash.CanQuery = false
	splash.CanTouch = false
	splash.Anchored = true
	splash.CFrame = CFrame.new(position)
	splash.Parent = game.Workspace

	-- Fade out the splash
	task.spawn(function()
		for i = 1, 10 do
			task.wait(0.05)
			if splash and splash.Parent then
				splash.Transparency = 0.3 + (i / 10) * 0.7
				splash.Size = Vector3.new(0.6, 0.6, 0.6) * (1 + i * 0.1)
			end
		end
		if splash and splash.Parent then
			splash:Destroy()
		end
	end)
end

return BloodEffect
