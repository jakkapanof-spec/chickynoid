local framework = require("../lib/framework")
local Loader = require("../lib/loader")

local describe = framework.describe
local it = framework.it
local expect = framework.expect

local Vector3 = Loader.Vector3

local MathUtils = Loader.load("src/ReplicatedFirst/Packages/Chickynoid/Shared/Simulation/MathUtils.lua")

local THETA = math.pi * 2

describe("MathUtils.AngleAbs", function()
    it("normalizes a negative angle to positive", function()
        local result = MathUtils:AngleAbs(-math.pi)
        expect(result).toBeCloseTo(math.pi)
    end)

    it("normalizes an angle greater than 2pi", function()
        local result = MathUtils:AngleAbs(3 * math.pi)
        expect(result).toBeCloseTo(math.pi)
    end)

    it("leaves an angle within [0, 2pi] unchanged", function()
        local result = MathUtils:AngleAbs(math.pi / 2)
        expect(result).toBeCloseTo(math.pi / 2)
    end)

    it("handles zero", function()
        local result = MathUtils:AngleAbs(0)
        expect(result).toBeCloseTo(0)
    end)
end)

describe("MathUtils.AngleShortest", function()
    it("returns the shortest path between two angles", function()
        local result = MathUtils:AngleShortest(0, math.pi / 2)
        expect(result).toBeCloseTo(math.pi / 2)
    end)

    it("goes negative when shorter to go backwards", function()
        local result = MathUtils:AngleShortest(math.pi / 4, -math.pi / 4)
        expect(result).toBeCloseTo(-math.pi / 2)
    end)

    it("returns 0 for identical angles", function()
        local result = MathUtils:AngleShortest(1.0, 1.0)
        expect(result).toBeCloseTo(0)
    end)
end)

describe("MathUtils.LerpAngle", function()
    it("returns start angle at frac=0", function()
        local result = MathUtils:LerpAngle(0, math.pi, 0)
        expect(result).toBeCloseTo(0)
    end)

    it("returns end angle at frac=1", function()
        local result = MathUtils:LerpAngle(0, math.pi, 1)
        expect(result).toBeCloseTo(math.pi)
    end)

    it("returns midpoint at frac=0.5", function()
        local result = MathUtils:LerpAngle(0, math.pi, 0.5)
        expect(result).toBeCloseTo(math.pi / 2)
    end)
end)

describe("MathUtils.PlayerVecToAngle / PlayerAngleToVec", function()
    it("PlayerVecToAngle returns consistent angles for known directions", function()
        local angle0 = MathUtils:PlayerVecToAngle(Vector3.new(0, 0, 1))
        local angle1 = MathUtils:PlayerVecToAngle(Vector3.new(0, 0, -1))
        -- Forward and backward should differ by ~pi
        local diff = math.abs(MathUtils:AngleShortest(angle0, angle1))
        expect(diff).toBeCloseTo(math.pi, 0.01)
    end)

    it("PlayerAngleToVec produces unit-length XZ vectors", function()
        for i = 0, 7 do
            local angle = (i / 8) * math.pi * 2
            local vec = MathUtils:PlayerAngleToVec(angle)
            local mag = math.sqrt(vec.X * vec.X + vec.Z * vec.Z)
            expect(mag).toBeCloseTo(1, 0.001)
        end
    end)

    it("PlayerAngleToVec gives correct sin/cos components", function()
        -- PlayerAngleToVec(angle) = Vector3(sin(angle), 0, cos(angle))
        local angle = math.pi / 4
        local vec = MathUtils:PlayerAngleToVec(angle)
        expect(vec.X).toBeCloseTo(math.sin(angle), 0.001)
        expect(vec.Y).toBeCloseTo(0, 0.001)
        expect(vec.Z).toBeCloseTo(math.cos(angle), 0.001)
    end)
end)

describe("MathUtils.Friction", function()
    it("decays a value toward zero over time", function()
        local result = MathUtils:Friction(100, 0.5, 1 / 60)
        expect(result).toBeLessThan(100)
        expect(result).toBeGreaterThan(0)
    end)

    it("returns the value unchanged when deltaTime is 0", function()
        local result = MathUtils:Friction(100, 0.5, 0)
        expect(result).toBeCloseTo(100)
    end)

    it("decays more with larger deltaTime", function()
        local fast = MathUtils:Friction(100, 0.5, 1)
        local slow = MathUtils:Friction(100, 0.5, 0.01)
        expect(fast).toBeLessThan(slow)
    end)
end)

describe("MathUtils.VelocityFriction", function()
    it("reduces velocity magnitude", function()
        local vel = Vector3.new(10, 0, 0)
        local result = MathUtils:VelocityFriction(vel, 0.5, 1 / 60)
        expect(result.Magnitude).toBeLessThan(vel.Magnitude)
    end)

    it("returns zero vector for very small speeds", function()
        local vel = Vector3.new(0.0001, 0, 0)
        local result = MathUtils:VelocityFriction(vel, 0.5, 10)
        expect(result.Magnitude).toBeCloseTo(0, 0.01)
    end)
end)

describe("MathUtils.FlatVec", function()
    it("zeroes the Y component", function()
        local result = MathUtils:FlatVec(Vector3.new(3, 5, 7))
        expect(result.X).toBeCloseTo(3)
        expect(result.Y).toBeCloseTo(0)
        expect(result.Z).toBeCloseTo(7)
    end)
end)

describe("MathUtils.CapVelocity", function()
    it("caps velocity to maxSpeed", function()
        local vel = Vector3.new(100, 0, 0)
        local result = MathUtils:CapVelocity(vel, 10)
        expect(result.Magnitude).toBeCloseTo(10)
    end)

    it("does not change velocity already under maxSpeed", function()
        local vel = Vector3.new(3, 0, 4) -- magnitude = 5
        local result = MathUtils:CapVelocity(vel, 10)
        expect(result.Magnitude).toBeCloseTo(5)
    end)

    it("returns zero vector for near-zero velocity", function()
        local vel = Vector3.new(0.001, 0, 0)
        local result = MathUtils:CapVelocity(vel, 10)
        expect(result.Magnitude).toBeCloseTo(0, 0.01)
    end)
end)

describe("MathUtils.ClipVelocity", function()
    it("removes velocity component along the normal", function()
        local vel = Vector3.new(5, -5, 0)
        local normal = Vector3.new(0, 1, 0)
        local result = MathUtils:ClipVelocity(vel, normal, 1)
        expect(result.X).toBeCloseTo(5)
        expect(result.Y).toBeCloseTo(0, 0.01)
        expect(result.Z).toBeCloseTo(0)
    end)

    it("preserves velocity perpendicular to normal", function()
        local vel = Vector3.new(10, 0, 0)
        local normal = Vector3.new(0, 1, 0)
        local result = MathUtils:ClipVelocity(vel, normal, 1)
        expect(result.X).toBeCloseTo(10)
    end)
end)

describe("MathUtils.GroundAccelerate", function()
    it("accelerates toward wish direction", function()
        local wishDir = Vector3.new(1, 0, 0)
        local velocity = Vector3.new(0, 0, 0)
        local result = MathUtils:GroundAccelerate(wishDir, 16, 10, velocity, 1 / 60)
        expect(result.X).toBeGreaterThan(0)
    end)

    it("caps velocity at wishSpeed", function()
        local wishDir = Vector3.new(1, 0, 0)
        local velocity = Vector3.new(20, 0, 0) -- already over wishSpeed
        local result = MathUtils:GroundAccelerate(wishDir, 16, 10, velocity, 1 / 60)
        expect(result.Magnitude).toBeCloseTo(16, 0.1)
    end)
end)

describe("MathUtils.Accelerate", function()
    it("accelerates from rest", function()
        local wishDir = Vector3.new(1, 0, 0)
        local velocity = Vector3.new(0, 0, 0)
        local result = MathUtils:Accelerate(wishDir, 16, 10, velocity, 1 / 60)
        expect(result.X).toBeGreaterThan(0)
    end)

    it("does not exceed wishSpeed from rest", function()
        local wishDir = Vector3.new(1, 0, 0)
        local velocity = Vector3.new(0, 0, 0)
        local result = MathUtils:Accelerate(wishDir, 16, 10, velocity, 1)
        expect(result.Magnitude).toBeLessThan(16.01)
    end)
end)

describe("MathUtils.SmoothLerp", function()
    it("works with numbers", function()
        local result = MathUtils:SmoothLerp(0, 10, 0.5, 1)
        expect(result).toBeGreaterThan(0)
        expect(result).toBeLessThan(10)
    end)

    it("returns start when fraction is 0", function()
        local result = MathUtils:SmoothLerp(5, 10, 0, 1)
        expect(result).toBeCloseTo(5)
    end)

    it("works with Vector3 values", function()
        local a = Vector3.new(0, 0, 0)
        local b = Vector3.new(10, 10, 10)
        local result = MathUtils:SmoothLerp(a, b, 0.5, 1)
        expect(result.X).toBeGreaterThan(0)
        expect(result.X).toBeLessThan(10)
    end)
end)
