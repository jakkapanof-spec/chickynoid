local AssaultRifleModule = {}
AssaultRifleModule.__index = AssaultRifleModule

local path = game.ReplicatedFirst.Packages.Chickynoid
local EffectsModule = require(path.Client.Effects)
local BloodEffect = require(game.ReplicatedFirst.Examples.BloodEffect)
local WriteBuffer = require(path.Shared.Vendor.WriteBuffer)
local ReadBuffer = require(path.Shared.Vendor.ReadBuffer)
local ServerMods = nil
local Enums = require(path.Shared.Enums)

function AssaultRifleModule.new()
	local self = setmetatable({
		rateOfFire = 0.1,
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
	}, AssaultRifleModule)
	return self
end

function AssaultRifleModule:ClientThink(_deltaTime)
	local gui = self.client:GetGui()
	local state = self.clientState
	local counter = gui:FindFirstChild("AmmoCounter", true)
	if counter then
		counter.Text = state.ammo .. " / " .. state.maxAmmo
	end
end

function AssaultRifleModule:ClientProcessCommand(command)
	local currentTime = self.totalTime
	local state = self.clientState

	if command.f and command.f > 0 and command.fa then
		if state.ammo > 0 and currentTime > state.nextFire then
			state.ammo -= 1
			state.nextFire = currentTime + state.fireDelay
			self:SetPredictedState()

			self.client:DebugMarkAllPlayers(tostring(state.ammo + 1))

			local clientChickynoid = self.client:GetClientChickynoid()
			if clientChickynoid then
				local origin = clientChickynoid.simulation.state.pos
				local dest = command.fa
				local vec = (dest - origin).Unit

				local clone = EffectsModule:SpawnEffect("Tracer", origin + vec * 2)
				if clone then
					clone.CFrame = CFrame.lookAt(origin, origin + vec)
				end
			end
		end
	end
end

function AssaultRifleModule:ClientSetup() end
function AssaultRifleModule:ClientEquip() end
function AssaultRifleModule:ClientDequip() end

function AssaultRifleModule:ClientOnBulletImpact(_client, event)
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

function AssaultRifleModule:ServerSetup()
	self.state.maxAmmo = 30
	self.state.ammo = self.state.maxAmmo
	self.state.fireDelay = self.rateOfFire
	self.state.nextFire = 0
	self.timeOfLastShot = 0
end

function AssaultRifleModule:ServerThink(_deltaTime)
	local currentTime = self.totalTime
	local state = self.state
	if state.ammo == 0 and currentTime > self.timeOfLastShot + 2.0 then
		state.ammo = state.maxAmmo
	end
end

function AssaultRifleModule:ServerProcessCommand(command)
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
				local pos, normal, otherPlayer = self.weaponModule:QueryBullet(
					self.playerRecord,
					self.server,
					origin,
					vec,
					command.serverTime,
					nil
				)
				local surface = 0
				if otherPlayer then
					surface = 1
				end

				local event = {}
				event.t = Enums.EventType.BulletImpact
				event.b = self:BuildPacketString(origin, pos, normal, surface)
				self.playerRecord:SendEventToClients(event)

				if otherPlayer then
					if ServerMods == nil then
						ServerMods = require(game.ServerScriptService.Packages.Chickynoid.Server.ServerMods)
					end
					local HitPoints = ServerMods:GetMod("servermods", "Hitpoints")
					if HitPoints then
						HitPoints:DamagePlayer(otherPlayer, 12, self.playerRecord)
					end
				end
			end
		end
	end
end

function AssaultRifleModule:BuildPacketString(origin, position, normal, surface)
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

function AssaultRifleModule:UnpackPacket(event)
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

function AssaultRifleModule:ServerEquip() end
function AssaultRifleModule:ServerDequip() end
function AssaultRifleModule:ClientRemoved() end
function AssaultRifleModule:ServerRemoved() end

return AssaultRifleModule
