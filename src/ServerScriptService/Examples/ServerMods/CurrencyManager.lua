local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}
module.saveTimer = 0
module.SAVE_INTERVAL = 60
module.KILL_REWARD = 10
module.dataStore = nil
module.server = nil

-- RemoteEvent for pushing coin updates to client
local shopEvent = Instance.new("RemoteEvent")
shopEvent.Name = "WeaponShopEvent"
shopEvent.Parent = ReplicatedStorage

module.shopEvent = shopEvent

function module:Setup(server)
	self.server = server

	-- DataStore (pcall in case Studio doesn't have API access)
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("ChickynoidPlayerData")
	end)
	if ok then
		self.dataStore = store
	else
		warn("CurrencyManager: DataStore unavailable, using session-only mode")
	end

	server.OnPlayerConnected:Connect(function(_server, playerRecord)
		self:LoadPlayerData(playerRecord)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local playerRecord = server:GetPlayerByUserId(player.UserId)
		if playerRecord then
			self:SavePlayerData(playerRecord)
		end
	end)

	game:BindToClose(function()
		for _, playerRecord in pairs(server:GetPlayers()) do
			if playerRecord.dummy == false then
				self:SavePlayerData(playerRecord)
			end
		end
	end)
end

function module:LoadPlayerData(playerRecord)
	local START_COINS = 5000
	playerRecord.coins = START_COINS
	playerRecord.ownedWeapons = { "Pistol" }
	playerRecord.dataLoaded = false

	if self.dataStore and not playerRecord.dummy then
		local ok, data = pcall(function()
			return self.dataStore:GetAsync("player_" .. tostring(playerRecord.userId))
		end)

		if ok and data then
			playerRecord.coins = math.max(data.coins or 0, START_COINS)
			if data.ownedWeapons and #data.ownedWeapons > 0 then
				playerRecord.ownedWeapons = data.ownedWeapons
			end
		end
	end

	playerRecord.dataLoaded = true

	-- Send initial data to client
	self:SendCoinUpdate(playerRecord)
end

function module:SavePlayerData(playerRecord)
	if not self.dataStore then
		return
	end
	if playerRecord.dummy then
		return
	end
	if not playerRecord.dataLoaded then
		return
	end

	local data = {
		coins = playerRecord.coins or 0,
		ownedWeapons = playerRecord.ownedWeapons or { "Pistol" },
		version = 1,
	}

	pcall(function()
		self.dataStore:SetAsync("player_" .. tostring(playerRecord.userId), data)
	end)
end

function module:AddCoins(playerRecord, amount)
	if playerRecord == nil or playerRecord.dummy then
		return
	end
	playerRecord.coins = (playerRecord.coins or 0) + amount
	self:SendCoinUpdate(playerRecord)
end

function module:RemoveCoins(playerRecord, amount)
	if playerRecord == nil then
		return false
	end
	if (playerRecord.coins or 0) < amount then
		return false
	end
	playerRecord.coins = playerRecord.coins - amount
	self:SendCoinUpdate(playerRecord)
	return true
end

function module:GetCoins(playerRecord)
	return playerRecord.coins or 0
end

function module:SendCoinUpdate(playerRecord)
	if playerRecord.dummy then
		return
	end
	if playerRecord.player then
		self.shopEvent:FireClient(playerRecord.player, {
			type = "CoinsUpdate",
			coins = playerRecord.coins or 0,
		})
	end
end

function module:Step(_server, deltaTime)
	self.saveTimer = self.saveTimer + deltaTime
	if self.saveTimer >= self.SAVE_INTERVAL then
		self.saveTimer = 0
		if self.server then
			for _, playerRecord in pairs(self.server:GetPlayers()) do
				if not playerRecord.dummy and playerRecord.dataLoaded then
					self:SavePlayerData(playerRecord)
				end
			end
		end
	end
end

return module
