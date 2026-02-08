local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerMods = nil

local module = {}
module.server = nil
module.lastPurchaseTime = {}

-- Weapon prices (must match WeaponDefs.lua)
local WEAPON_PRICES = {
	Pistol = 0,
	Shotgun = 200,
	AssaultRifle = 500,
	Sniper = 800,
	RocketLauncher = 1200,
}

local PURCHASE_COOLDOWN = 0.5

function module:Setup(server)
	self.server = server

	-- Create RemoteFunction for shop requests
	local shopRemote = Instance.new("RemoteFunction")
	shopRemote.Name = "WeaponShopRemote"
	shopRemote.Parent = ReplicatedStorage

	shopRemote.OnServerInvoke = function(player, action, weaponName)
		local playerRecord = server:GetPlayerByUserId(player.UserId)
		if not playerRecord then
			return { success = false, error = "Not connected" }
		end
		if not playerRecord.dataLoaded then
			return { success = false, error = "Data not loaded yet" }
		end

		if action == "QueryShopData" then
			return self:HandleQueryShopData(playerRecord)
		elseif action == "Purchase" then
			return self:HandlePurchase(playerRecord, weaponName)
		elseif action == "Equip" then
			return self:HandleEquip(playerRecord, weaponName)
		end

		return { success = false, error = "Unknown action" }
	end
end

function module:HandleQueryShopData(playerRecord)
	local catalog = {}
	for name, price in pairs(WEAPON_PRICES) do
		table.insert(catalog, { name = name, price = price })
	end

	-- Sort by price
	table.sort(catalog, function(a, b)
		return a.price < b.price
	end)

	return {
		success = true,
		coins = playerRecord.coins or 0,
		ownedWeapons = playerRecord.ownedWeapons or { "Pistol" },
		catalog = catalog,
	}
end

function module:HandlePurchase(playerRecord, weaponName)
	-- Rate limit
	local now = tick()
	local lastTime = self.lastPurchaseTime[playerRecord.userId] or 0
	if now - lastTime < PURCHASE_COOLDOWN then
		return { success = false, error = "Too fast" }
	end
	self.lastPurchaseTime[playerRecord.userId] = now

	-- Validate weapon exists
	local price = WEAPON_PRICES[weaponName]
	if price == nil then
		return { success = false, error = "Unknown weapon" }
	end

	-- Check already owned
	local ownedWeapons = playerRecord.ownedWeapons or { "Pistol" }
	for _, owned in ipairs(ownedWeapons) do
		if owned == weaponName then
			return { success = false, error = "Already owned" }
		end
	end

	-- Check coins
	if ServerMods == nil then
		ServerMods = require(game.ServerScriptService.Packages.Chickynoid.Server.ServerMods)
	end
	local CurrencyManager = ServerMods:GetMod("servermods", "CurrencyManager")
	if not CurrencyManager then
		return { success = false, error = "Currency system unavailable" }
	end

	if (playerRecord.coins or 0) < price then
		return { success = false, error = "Not enough coins" }
	end

	-- Deduct coins
	local removed = CurrencyManager:RemoveCoins(playerRecord, price)
	if not removed then
		return { success = false, error = "Not enough coins" }
	end

	-- Add to owned weapons
	table.insert(playerRecord.ownedWeapons, weaponName)

	-- Give weapon if player is alive
	if playerRecord.chickynoid then
		playerRecord:AddWeaponByName(weaponName, false)
	end

	-- Notify client
	local shopEvent = ReplicatedStorage:FindFirstChild("WeaponShopEvent")
	if shopEvent and playerRecord.player then
		shopEvent:FireClient(playerRecord.player, {
			type = "WeaponUnlocked",
			weaponName = weaponName,
		})
	end

	return {
		success = true,
		coins = playerRecord.coins,
		ownedWeapons = playerRecord.ownedWeapons,
	}
end

function module:HandleEquip(playerRecord, weaponName)
	if not playerRecord.chickynoid then
		return { success = false, error = "Not alive" }
	end

	-- Find weapon serial by name
	for serial, weaponRecord in pairs(playerRecord.weapons) do
		if weaponRecord.name == weaponName then
			playerRecord:EquipWeapon(serial)
			return { success = true }
		end
	end

	return { success = false, error = "Weapon not in inventory" }
end

function module:Step(_server, _deltaTime) end

return module
