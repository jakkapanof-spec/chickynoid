local ShotgunModule = {}
ShotgunModule.__index = ShotgunModule

local path = game.ReplicatedFirst.Packages.Chickynoid
local EffectsModule = require(path.Client.Effects)
local BloodEffect = require(game.ReplicatedFirst.Examples.BloodEffect)
local WriteBuffer = require(path.Shared.Vendor.WriteBuffer)
local ReadBuffer = require(path.Shared.Vendor.ReadBuffer)
local ServerMods = nil
local Enums = require(path.Shared.Enums)

local PELLET_COUNT = 8
local SPREAD = 0.08
local DAMAGE_PER_PELLET = 8
local RANGE = 100

function ShotgunModule.new()
	local self = setmetatable({
		rateOfFire = 0.8,
		serial = nil,
		name = nil,
		client = nil,
		weaponModule = nil,
		clientState = nil,
		serverState = nil,
		preservePredictedStateTimer = 0,
		serverStateDirty = false,
		playerRecord = nil,
		state = {},
		previousState = {},
	}, ShotgunModule)
	return self
end

function ShotgunModule:ClientThink(_deltaTime)
	local gui = self.client:GetGui()
	local state = self.clientState
	local counter = gui:FindFirstChild("AmmoCounter", true)
	if counter then
		counter.Text = state.ammo .. " / " .. state.maxAmmo
	end
end

function ShotgunModule:ClientProcessCommand(command)
	local currentTime = self.totalTime
	local state = self.clientState

	if command.f and command.f > 0 and command.fa then
		if state.ammo > 0 and currentTime > state.nextFire then
			state.ammo -= 1
			state.nextFire = currentTime + state.fireDelay
			self:SetPredictedState()

			local clientChickynoid = self.client:GetClientChickynoid()
			if clientChickynoid then
				local origin = clientChickynoid.simulation.state.pos
				local dest = command.fa
				local baseVec = (dest - origin).Unit

				-- Show multiple tracers for spread
				for _ = 1, PELLET_COUNT do
					local spreadVec = Vector3.new(
						(math.random() - 0.5) * SPREAD,
						(math.random() - 0.5) * SPREAD,
						(math.random() - 0.5) * SPREAD
					)
					local pelletDir = (baseVec + spreadVec).Unit
					local clone = EffectsModule:SpawnEffect("Tracer", origin + pelletDir * 2)
					if clone then
						clone.CFrame = CFrame.lookAt(origin, origin + pelletDir)
					end
				end
			end
		end
	end
end

function ShotgunModule:ClientSetup() end
function ShotgunModule:ClientEquip() end
function ShotgunModule:ClientDequip() end

function ShotgunModule:ClientOnBulletImpact(_client, event)
	if event.normal then
		if event.surface == 0 then
			local effect = EffectsModule:SpawnEffect("ImpactWorld", event.position)
			if effect then
				effect.CFrame = CFrame.lookAt(event.position, event.position + event.normal)
			end
		end
		if event.surface == 1 then
			BloodEffect:Spawn(event.position, event.normal)
		end
	end

	if event.player.userId ~= game.Players.LocalPlayer.UserId then
		local origin = event.origin
		local vec = (event.position - event.origin).Unit
		local clone = EffectsModule:SpawnEffect("Tracer", origin + vec * 2)
		if clone then
			clone.CFrame = CFrame.lookAt(origin, origin + vec)
		end
	end
end

function ShotgunModule:ServerSetup()
	self.state.maxAmmo = 6
	self.state.ammo = self.state.maxAmmo
	self.state.fireDelay = self.rateOfFire
	self.state.nextFire = 0
	self.timeOfLastShot = 0
end

function ShotgunModule:ServerThink(_deltaTime)
	local currentTime = self.totalTime
	local state = self.state
	if state.ammo == 0 and currentTime > self.timeOfLastShot + 2.0 then
		state.ammo = state.maxAmmo
	end
end

function ShotgunModule:ServerProcessCommand(command)
	local currentTime = self.totalTime
	local state = self.state

	if command.f and command.f > 0 and command.fa then
		if state.ammo > 0 and currentTime > state.nextFire then
			state.ammo -= 1
			state.nextFire = currentTime + state.fireDelay
			self.timeOfLastShot = currentTime

			local serverChickynoid = self.playerRecord.chickynoid
			if serverChickynoid then
				local origin = serverChickynoid.simulation.state.pos
				local dest = command.fa
				local baseVec = (dest - origin).Unit

				-- Generate pellet directions with spread
				local origins = {}
				local directions = {}
				for _ = 1, PELLET_COUNT do
					local spreadVec = Vector3.new(
						(math.random() - 0.5) * SPREAD,
						(math.random() - 0.5) * SPREAD,
						(math.random() - 0.5) * SPREAD
					)
					table.insert(origins, origin)
					table.insert(directions, (baseVec + spreadVec).Unit)
				end

				local results = self.weaponModule:QueryShotgun(
					self.playerRecord,
					self.server,
					origins,
					directions,
					command.serverTime,
					nil,
					nil,
					RANGE
				)

				-- Process hits and send first impact event
				local hitPos = origin + baseVec * RANGE
				local hitNormal = nil
				local hitSurface = 0
				local playersHit = {}

				for _, result in ipairs(results) do
					if result.otherPlayerRecord then
						if not playersHit[result.otherPlayerRecord.userId] then
							playersHit[result.otherPlayerRecord.userId] = {
								record = result.otherPlayerRecord,
								hits = 0,
							}
						end
						playersHit[result.otherPlayerRecord.userId].hits += 1
						hitPos = result.pos
						hitNormal = result.normal
						hitSurface = 1
					elseif result.normal then
						hitPos = result.pos
						hitNormal = result.normal
					end
				end

				-- Apply damage per hit
				if ServerMods == nil then
					ServerMods = require(game.ServerScriptService.Packages.Chickynoid.Server.ServerMods)
				end
				local HitPoints = ServerMods:GetMod("servermods", "Hitpoints")
				for _, hitData in pairs(playersHit) do
					if HitPoints then
						HitPoints:DamagePlayer(hitData.record, DAMAGE_PER_PELLET * hitData.hits, self.playerRecord)
					end
				end

				local event = {}
				event.t = Enums.EventType.BulletImpact
				event.b = self:BuildPacketString(origin, hitPos, hitNormal, hitSurface)
				self.playerRecord:SendEventToClients(event)
			end
		end
	end
end

function ShotgunModule:BuildPacketString(origin, position, normal, surface)
	local buf = WriteBuffer.new()
	buf:WriteI16(self.weaponId)
	buf:WriteU8(self.playerRecord.slot)
	buf:WriteVector3(origin)
	buf:WriteVector3(position)
	buf:WriteU8(surface)
	if normal then
		buf:WriteU8(1)
		buf:WriteVector3(normal)
	else
		buf:WriteU8(0)
	end
	return buf:GetBuffer()
end

function ShotgunModule:UnpackPacket(event)
	local buf = ReadBuffer.new(event.b)
	event.weaponID = buf:ReadI16()
	event.slot = buf:ReadU8()
	event.origin = buf:ReadVector3()
	event.position = buf:ReadVector3()
	event.surface = buf:ReadU8()
	local hasNormal = buf:ReadU8()
	if hasNormal > 0 then
		event.normal = buf:ReadVector3()
	end
	return event
end

function ShotgunModule:ServerEquip() end
function ShotgunModule:ServerDequip() end
function ShotgunModule:ClientRemoved() end
function ShotgunModule:ServerRemoved() end

return ShotgunModule
