local ReplicatedStorage = game:GetService("ReplicatedStorage")

local path = game.ReplicatedFirst.Packages.Chickynoid

local module = {}
module.client = nil
module.coinsLabel = nil
module.weaponLabel = nil
module.lastWeaponName = nil

function module:Setup(_client)
	self.client = _client

	-- Create HUD
	local player = game.Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CurrencyHUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 5
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "CoinFrame"
	frame.Size = UDim2.new(0, 160, 0, 40)
	frame.Position = UDim2.new(1, -170, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 30, 1, 0)
	coinIcon.Position = UDim2.new(0, 5, 0, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "$"
	coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinIcon.TextSize = 22
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = frame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsAmount"
	coinsLabel.Size = UDim2.new(1, -40, 1, 0)
	coinsLabel.Position = UDim2.new(0, 35, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinsLabel.TextSize = 18
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = frame

	self.coinsLabel = coinsLabel

	-- Hint text
	local hint = Instance.new("TextLabel")
	hint.Name = "ShopHint"
	hint.Size = UDim2.new(0, 160, 0, 18)
	hint.Position = UDim2.new(1, -170, 0, 52)
	hint.BackgroundTransparency = 1
	hint.Text = "[B] Shop"
	hint.TextColor3 = Color3.fromRGB(150, 150, 150)
	hint.TextSize = 12
	hint.Font = Enum.Font.Gotham
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Parent = screenGui

	-- Weapon name label (bottom left, above ammo counter)
	local weaponFrame = Instance.new("Frame")
	weaponFrame.Name = "WeaponFrame"
	weaponFrame.Size = UDim2.new(0, 200, 0, 30)
	weaponFrame.Position = UDim2.new(0, 10, 1, -100)
	weaponFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	weaponFrame.BackgroundTransparency = 0.3
	weaponFrame.BorderSizePixel = 0
	weaponFrame.Parent = screenGui

	local weaponCorner = Instance.new("UICorner")
	weaponCorner.CornerRadius = UDim.new(0, 6)
	weaponCorner.Parent = weaponFrame

	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Name = "WeaponName"
	weaponLabel.Size = UDim2.new(1, -10, 1, 0)
	weaponLabel.Position = UDim2.new(0, 10, 0, 0)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Text = "No weapon"
	weaponLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	weaponLabel.TextSize = 14
	weaponLabel.Font = Enum.Font.GothamBold
	weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
	weaponLabel.Parent = weaponFrame

	self.weaponLabel = weaponLabel

	-- Listen for coin updates
	local shopEvent = ReplicatedStorage:WaitForChild("WeaponShopEvent", 10)
	if shopEvent then
		shopEvent.OnClientEvent:Connect(function(data)
			if data.type == "CoinsUpdate" then
				self:UpdateCoins(data.coins)
			end
		end)
	end
end

function module:UpdateCoins(amount)
	if self.coinsLabel then
		self.coinsLabel.Text = tostring(amount)
	end
end

function module:Step(_client, _deltaTime)
	-- Update weapon name display
	local WeaponsClient = require(path.Client.WeaponsClient)
	local currentWeapon = WeaponsClient.currentWeapon

	local weaponName = nil
	if currentWeapon then
		weaponName = currentWeapon.name
	end

	if weaponName ~= self.lastWeaponName then
		self.lastWeaponName = weaponName
		if self.weaponLabel then
			self.weaponLabel.Text = weaponName or "No weapon"
		end
	end
end

return module
