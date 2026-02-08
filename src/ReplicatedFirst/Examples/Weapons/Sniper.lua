local RunService = game:GetService("RunService")
local SniperModule = {}
SniperModule.__index = SniperModule

local path = game.ReplicatedFirst.Packages.Chickynoid
local EffectsModule = require(path.Client.Effects)
local BloodEffect = require(game.ReplicatedFirst.Examples.BloodEffect)
local WriteBuffer = require(path.Shared.Vendor.WriteBuffer)
local ReadBuffer = require(path.Shared.Vendor.ReadBuffer)
local Enums = require(path.Shared.Enums)

local isServer = false
if game:GetService("RunService"):IsServer() then
	isServer = true
end
local ServerFastProjectiles = nil
local ClientFastProjectiles = nil
local ServerMods = nil
if isServer then
	ServerFastProjectiles = require(game.ServerScriptService.Examples.ServerMods.ServerFastProjectiles)
	ServerMods = require(game.ServerScriptService.Packages.Chickynoid.Server.ServerMods)
end
if isServer ~= true then
	ClientFastProjectiles = require(game.ReplicatedFirst.Examples.ClientMods.ClientFastProjectiles)
end

function SniperModule.new()
	local self = setmetatable({
		rateOfFire = 1.2,
		bulletDrop = -0.1,
		bulletSpeed = 800,
		bulletMaxDistance = 800,
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
	}, SniperModule)
	return self
end

function SniperModule:ClientThink(_deltaTime)
	local gui = self.client:GetGui()
	local state = self.clientState
	local counter = gui:FindFirstChild("AmmoCounter", true)
	if counter then
		counter.Text = state.ammo .. " / " .. state.maxAmmo
	end
end

function SniperModule:ClientProcessCommand(command)
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
				local vec = (dest - origin).Unit

				local clone = EffectsModule:SpawnEffect("Tracer", origin + vec * 2)
				if clone then
					clone.CFrame = CFrame.lookAt(origin, origin + vec)
				end

				local bulletRecord = ClientFastProjectiles:FireBullet(origin, vec, self.bulletSpeed, self.bulletMaxDistance, self.bulletDrop, -1)
				bulletRecord.DoCollisionCheck = function(record, old, new)
					return self:DoClientBulletCheck(record, old, new)
				end
			end
		end
	end
end

function SniperModule:DoClientBulletCheck(_bulletRecord, old, new)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = { game.Workspace.GameArea }
	local vec = (new - old)
	local results = game.Workspace:Raycast(old, vec, ray)
	if results ~= nil then
		return results
	end
	return nil
end

function SniperModule:ClientSetup() end
function SniperModule:ClientEquip() end
function SniperModule:ClientDequip() end

function SniperModule:ClientOnBulletImpact(_client, event)
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
	ClientFastProjectiles:TerminateBullet(event.bulletId)
end

function SniperModule:ClientOnBulletFire(_client, event)
	if event.player.userId ~= game.Players.LocalPlayer.UserId then
		local clone = EffectsModule:SpawnEffect("Tracer", event.origin + event.vec * 2)
		if clone then
			clone.CFrame = CFrame.lookAt(event.origin, event.origin + event.vec)
		end
		ClientFastProjectiles:FireBullet(event.origin, event.vec, event.speed, event.maxDistance, event.drop, event.bulletId)
	end
end

function SniperModule:ServerSetup()
	self.state.maxAmmo = 5
	self.state.ammo = self.state.maxAmmo
	self.state.fireDelay = self.rateOfFire
	self.state.nextFire = 0
	self.timeOfLastShot = 0
end

function SniperModule:ServerThink(_deltaTime)
	local currentTime = self.totalTime
	local state = self.state
	if state.ammo == 0 and currentTime > self.timeOfLastShot + 2.5 then
		state.ammo = state.maxAmmo
	end
end

function SniperModule:ServerProcessCommand(command)
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
				local vec = (dest - origin).Unit

				local speed = self.bulletSpeed
				local maxDistance = self.bulletMaxDistance
				local drop = self.bulletDrop

				local raycastParams = nil

				local bulletRecord = ServerFastProjectiles:FireBullet(origin, vec, speed, maxDistance, drop, command.serverTime)

				bulletRecord.DoCollisionCheck = function(bulletRecord, old, new)
					local bvec = (new - old).Unit
					local range = (new - old).Magnitude
					local pos, normal, otherPlayer = self.weaponModule:QueryBullet(
						self.playerRecord,
						self.server,
						old,
						bvec,
						bulletRecord.serverTime,
						nil,
						raycastParams,
						range
					)

					if normal ~= nil then
						local surface = 0
						if otherPlayer then
							surface = 1
						end
						bulletRecord.die = true
						bulletRecord.surface = surface
						bulletRecord.position = pos
						bulletRecord.normal = normal
						bulletRecord.otherPlayer = otherPlayer
					end
				end

				bulletRecord.OnBulletDie = function(bulletRecord)
					local event = {}
					event.t = Enums.EventType.BulletImpact
					event.b = self:BuildImpactPacketString(bulletRecord.position, bulletRecord.normal, bulletRecord.surface, bulletRecord.bulletId)

					self.playerRecord:SendEventToClients(event)

					if bulletRecord.otherPlayer then
						local HitPoints = ServerMods:GetMod("servermods", "Hitpoints")
						if HitPoints then
							HitPoints:DamagePlayer(bulletRecord.otherPlayer, 70, self.playerRecord)
						end
					end
				end

				local event = {}
				event.t = Enums.EventType.BulletFire
				event.b = self:BuildFirePacketString(origin, vec, speed, maxDistance, drop, bulletRecord.bulletId)
				self.playerRecord:SendEventToClients(event)
			end
		end
	end
end

function SniperModule:BuildImpactPacketString(position, normal, surface, bulletId)
	local buf = WriteBuffer.new()
	buf:WriteI16(self.weaponId)
	buf:WriteU8(self.playerRecord.slot)
	buf:WriteVector3(position)
	buf:WriteI16(bulletId)
	if normal then
		buf:WriteU8(1)
		buf:WriteVector3(normal)
		buf:WriteU8(surface)
	else
		buf:WriteU8(0)
	end
	return buf:GetBuffer()
end

function SniperModule:BuildFirePacketString(origin, vec, speed, maxDistance, drop, bulletId)
	local buf = WriteBuffer.new()
	buf:WriteI16(self.weaponId)
	buf:WriteU8(self.playerRecord.slot)
	buf:WriteVector3(origin)
	buf:WriteVector3(vec)
	buf:WriteFloat16(speed)
	buf:WriteFloat16(maxDistance)
	buf:WriteFloat16(drop)
	buf:WriteI16(bulletId)
	return buf:GetBuffer()
end

function SniperModule:UnpackPacket(event)
	if event.t == Enums.EventType.BulletImpact then
		local buf = ReadBuffer.new(event.b)
		event.weaponID = buf:ReadI16()
		event.slot = buf:ReadU8()
		event.position = buf:ReadVector3()
		event.bulletId = buf:ReadI16()
		local hasNormal = buf:ReadU8()
		if hasNormal > 0 then
			event.normal = buf:ReadVector3()
			event.surface = buf:ReadU8()
		end
		return event
	elseif event.t == Enums.EventType.BulletFire then
		local buf = ReadBuffer.new(event.b)
		event.weaponID = buf:ReadI16()
		event.slot = buf:ReadU8()
		event.origin = buf:ReadVector3()
		event.vec = buf:ReadVector3()
		event.speed = buf:ReadFloat16()
		event.maxDistance = buf:ReadFloat16()
		event.drop = buf:ReadFloat16()
		event.bulletId = buf:ReadI16()
		return event
	end
end

function SniperModule:ServerEquip() end
function SniperModule:ServerDequip() end
function SniperModule:ClientRemoved() end
function SniperModule:ServerRemoved() end

return SniperModule
