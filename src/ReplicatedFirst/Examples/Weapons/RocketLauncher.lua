local RocketLauncherModule = {}
RocketLauncherModule.__index = RocketLauncherModule

local path = game.ReplicatedFirst.Packages.Chickynoid
local EffectsModule = require(path.Client.Effects)
local WriteBuffer = require(path.Shared.Vendor.WriteBuffer)
local ReadBuffer = require(path.Shared.Vendor.ReadBuffer)
local Enums = require(path.Shared.Enums)

local isServer = false
if game:GetService("RunService"):IsServer() then
	isServer = true
end

function RocketLauncherModule.new()
	local self = setmetatable({
		rateOfFire = 1.5,
		rocketSpeed = 80,
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
	}, RocketLauncherModule)
	return self
end

function RocketLauncherModule:ClientThink(_deltaTime)
	local gui = self.client:GetGui()
	local state = self.clientState
	local counter = gui:FindFirstChild("AmmoCounter", true)
	if counter then
		counter.Text = state.ammo .. " / " .. state.maxAmmo
	end
end

function RocketLauncherModule:ClientProcessCommand(command)
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
			end
		end
	end
end

function RocketLauncherModule:ClientSetup() end
function RocketLauncherModule:ClientEquip() end
function RocketLauncherModule:ClientDequip() end

function RocketLauncherModule:ClientOnBulletImpact(_client, event)
	if event.normal then
		local effect = EffectsModule:SpawnEffect("ImpactWorld", event.position)
		if effect then
			effect.CFrame = CFrame.lookAt(event.position, event.position + event.normal)
		end
	end
end

function RocketLauncherModule:ServerSetup()
	self.state.maxAmmo = 3
	self.state.ammo = self.state.maxAmmo
	self.state.fireDelay = self.rateOfFire
	self.state.nextFire = 0
	self.timeOfLastShot = 0
end

function RocketLauncherModule:ServerThink(_deltaTime)
	local currentTime = self.totalTime
	local state = self.state
	if state.ammo == 0 and currentTime > self.timeOfLastShot + 3.0 then
		state.ammo = state.maxAmmo
	end
end

function RocketLauncherModule:ServerProcessCommand(command)
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

				-- Fire a rocket using the existing rockets system
				self.weaponModule.rocketSerial += 1
				local serial = self.weaponModule.rocketSerial

				local rocket = {}
				rocket.p = origin + vec * 2 -- start position
				rocket.v = vec -- direction
				rocket.c = self.rocketSpeed -- speed
				rocket.o = self.server.serverSimulationTime -- origin time
				rocket.s = serial
				rocket.n = Vector3.new(0, 1, 0) -- default normal
				self.weaponModule.rockets[serial] = rocket

				-- Send rocket fire event to clients
				local event = {}
				event.t = Enums.EventType.RocketFire
				event.p = origin + vec * 2
				event.v = vec
				event.c = self.rocketSpeed
				event.s = serial
				self.server:SendEventToClients(event)
			end
		end
	end
end

function RocketLauncherModule:BuildPacketString(origin, position, normal, surface)
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

function RocketLauncherModule:UnpackPacket(event)
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

function RocketLauncherModule:ServerEquip() end
function RocketLauncherModule:ServerDequip() end
function RocketLauncherModule:ClientRemoved() end
function RocketLauncherModule:ServerRemoved() end

return RocketLauncherModule
