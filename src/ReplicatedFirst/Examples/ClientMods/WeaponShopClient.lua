local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}
module.client = nil
module.shopGui = nil
module.shopVisible = false
module.shopRemote = nil
module.shopEvent = nil

local SHOP_KEY = Enum.KeyCode.B
local WEAPON_ORDER = { "Pistol", "Shotgun", "AssaultRifle", "Sniper", "RocketLauncher" }

local WEAPON_DESCRIPTIONS = {
	Pistol = "Reliable sidearm",
	Shotgun = "Devastating up close",
	AssaultRifle = "Rapid-fire workhorse",
	Sniper = "Lethal at distance",
	RocketLauncher = "Area damage",
}

function module:Setup(client)
	self.client = client

	-- Wait for remotes
	self.shopRemote = ReplicatedStorage:WaitForChild("WeaponShopRemote", 10)
	self.shopEvent = ReplicatedStorage:WaitForChild("WeaponShopEvent", 10)

	-- Create shop GUI
	self:CreateShopGui()

	-- Toggle with B key
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == SHOP_KEY then
			self:ToggleShop()
		end
	end)
end

function module:CreateShopGui()
	local player = game.Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WeaponShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	title.BorderSizePixel = 0
	title.Text = "WEAPON SHOP"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title

	-- Coins display
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0, 150, 0, 30)
	coinsLabel.Position = UDim2.new(1, -160, 0, 5)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "Coins: 0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextSize = 16
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
	coinsLabel.Parent = mainFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = mainFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 4)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		self:ToggleShop()
	end)

	-- Scrolling frame for weapon list
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "WeaponList"
	scrollFrame.Size = UDim2.new(1, -20, 1, -55)
	scrollFrame.Position = UDim2.new(0, 10, 0, 45)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #WEAPON_ORDER * 75)
	scrollFrame.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame

	-- Create weapon cards
	for _, weaponName in ipairs(WEAPON_ORDER) do
		self:CreateWeaponCard(scrollFrame, weaponName)
	end

	-- Hint label
	local hint = Instance.new("TextLabel")
	hint.Name = "HintLabel"
	hint.Size = UDim2.new(1, 0, 0, 20)
	hint.Position = UDim2.new(0, 0, 1, -20)
	hint.BackgroundTransparency = 1
	hint.Text = "Press B to close"
	hint.TextColor3 = Color3.fromRGB(150, 150, 150)
	hint.TextSize = 12
	hint.Font = Enum.Font.Gotham
	hint.Parent = mainFrame

	self.shopGui = screenGui
end

function module:CreateWeaponCard(parent, weaponName)
	local card = Instance.new("Frame")
	card.Name = weaponName .. "Card"
	card.Size = UDim2.new(1, 0, 0, 65)
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	card.BorderSizePixel = 0
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	-- Weapon name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "WeaponName"
	nameLabel.Size = UDim2.new(0, 200, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0, 250, 0, 20)
	descLabel.Position = UDim2.new(0, 10, 0, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = WEAPON_DESCRIPTIONS[weaponName] or ""
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextSize = 12
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = card

	-- Action button
	local actionBtn = Instance.new("TextButton")
	actionBtn.Name = "ActionButton"
	actionBtn.Size = UDim2.new(0, 100, 0, 35)
	actionBtn.Position = UDim2.new(1, -115, 0.5, -17)
	actionBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	actionBtn.Text = "FREE"
	actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionBtn.TextSize = 14
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.BorderSizePixel = 0
	actionBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = actionBtn

	actionBtn.MouseButton1Click:Connect(function()
		self:OnWeaponAction(weaponName, actionBtn)
	end)
end

function module:OnWeaponAction(weaponName, button)
	if not self.shopRemote then
		return
	end

	local currentText = button.Text

	if currentText == "EQUIP" then
		local ok, result = pcall(function()
			return self.shopRemote:InvokeServer("Equip", weaponName)
		end)
		if ok and result and result.success then
			self:RefreshShop()
		end
	elseif currentText ~= "OWNED" and currentText ~= "EQUIPPED" then
		-- Purchase
		button.Text = "..."
		local ok, result = pcall(function()
			return self.shopRemote:InvokeServer("Purchase", weaponName)
		end)
		if ok and result then
			if result.success then
				self:RefreshShop()
			else
				button.Text = result.error or "Error"
				task.delay(1, function()
					self:RefreshShop()
				end)
			end
		else
			button.Text = "Error"
			task.delay(1, function()
				self:RefreshShop()
			end)
		end
	end
end

function module:ToggleShop()
	if not self.shopGui then
		return
	end

	self.shopVisible = not self.shopVisible
	self.shopGui.Enabled = self.shopVisible

	if self.shopVisible then
		self:RefreshShop()
	end
end

function module:RefreshShop()
	if not self.shopRemote then
		return
	end

	local ok, data = pcall(function()
		return self.shopRemote:InvokeServer("QueryShopData")
	end)

	if not ok or not data or not data.success then
		return
	end

	-- Update coins display
	local mainFrame = self.shopGui:FindFirstChild("MainFrame")
	if mainFrame then
		local coinsLabel = mainFrame:FindFirstChild("CoinsLabel")
		if coinsLabel then
			coinsLabel.Text = "Coins: " .. tostring(data.coins)
		end
	end

	-- Build owned set
	local ownedSet = {}
	for _, name in ipairs(data.ownedWeapons or {}) do
		ownedSet[name] = true
	end

	-- Build price map from catalog
	local priceMap = {}
	for _, item in ipairs(data.catalog or {}) do
		priceMap[item.name] = item.price
	end

	-- Update weapon cards
	local scrollFrame = mainFrame and mainFrame:FindFirstChild("WeaponList")
	if not scrollFrame then
		return
	end

	for _, weaponName in ipairs(WEAPON_ORDER) do
		local card = scrollFrame:FindFirstChild(weaponName .. "Card")
		if card then
			local btn = card:FindFirstChild("ActionButton")
			if btn then
				if ownedSet[weaponName] then
					btn.Text = "EQUIP"
					btn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
				else
					local price = priceMap[weaponName] or 0
					if price == 0 then
						btn.Text = "FREE"
						btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
					else
						btn.Text = tostring(price) .. " coins"
						if data.coins >= price then
							btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
						else
							btn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
						end
					end
				end
			end
		end
	end
end

function module:Step(_client, _deltaTime) end

return module
