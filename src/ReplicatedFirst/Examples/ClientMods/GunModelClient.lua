local module = {}
module.client = nil
module.currentGunModel = nil
module.currentWeaponName = nil
module.characterModel = nil

local path = game.ReplicatedFirst.Packages.Chickynoid
local ClientModule = require(path.Client.ClientModule)
local GunModels = require(game.ReplicatedFirst.Examples.GunModels)

function module:Setup(client)
	self.client = client

	-- Listen for character model creation (fires before 3D model is ready)
	ClientModule.OnCharacterModelCreated:Connect(function(characterModel)
		-- Only track local player's model
		-- userId can be number or string, so normalize both to string for comparison
		local modelUserId = tostring(characterModel.userId)
		local localUserId = tostring(game.Players.LocalPlayer.UserId)

		if modelUserId == localUserId then
			self.characterModel = characterModel

			-- Wait for the actual 3D model to be ready (async creation via task.spawn)
			characterModel.onModelCreated:Connect(function()
				if self.currentWeaponName then
					self:AttachGunModel(self.currentWeaponName)
				end
			end)

			-- If model is already ready (rare but possible), attach now
			if characterModel.modelReady and self.currentWeaponName then
				self:AttachGunModel(self.currentWeaponName)
			end

			-- Clean up when model is destroyed
			characterModel.onModelDestroyed:Connect(function()
				self:DetachGunModel()
				if self.characterModel == characterModel then
					self.characterModel = nil
				end
			end)
		end
	end)
end

function module:AttachGunModel(weaponName)
	self:DetachGunModel()

	if not self.characterModel or not self.characterModel.model then
		return
	end

	local model = self.characterModel.model
	local rightHand = model:FindFirstChild("RightHand", true)
	if not rightHand then
		-- Fallback to RightUpperArm
		rightHand = model:FindFirstChild("RightUpperArm", true)
	end
	if not rightHand then
		return
	end

	local gunModel = GunModels.Build(weaponName)
	if not gunModel then
		return
	end

	-- Position and weld to hand
	gunModel:PivotTo(rightHand.CFrame * CFrame.new(0, -0.4, -0.3) * CFrame.Angles(math.rad(-90), 0, 0))
	gunModel.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rightHand
	weld.Part1 = gunModel.PrimaryPart
	weld.Parent = rightHand

	self.currentGunModel = gunModel
end

function module:DetachGunModel()
	if self.currentGunModel then
		self.currentGunModel:Destroy()
		self.currentGunModel = nil
	end
end

function module:Step(_client, _deltaTime)
	-- Check if weapon changed
	local WeaponsClient = require(path.Client.WeaponsClient)
	local currentWeapon = WeaponsClient.currentWeapon

	local newWeaponName = nil
	if currentWeapon then
		newWeaponName = currentWeapon.name
	end

	if newWeaponName ~= self.currentWeaponName then
		self.currentWeaponName = newWeaponName
		if newWeaponName then
			self:AttachGunModel(newWeaponName)
		else
			self:DetachGunModel()
		end
	end
end

return module
