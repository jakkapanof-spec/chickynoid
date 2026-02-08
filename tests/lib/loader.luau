local luau = require("@lune/luau")
local roblox = require("@lune/roblox") :: any
local fs = require("@lune/fs")

-- Lune's Vector3 lacks Roblox's lowercase aliases (.x, .y, .z, .magnitude, .unit)
-- and doesn't support number * Vector3 (only Vector3 * number).
-- This wrapper adds full Roblox compatibility.
-- Properties are stored as direct keys so they survive table.DeepCopy (which uses pairs()).

local Vec3 = {}
Vec3.__index = function(self, key)
    if key == "unit" or key == "Unit" then
        local mag = self.magnitude
        if mag < 0.00001 then
            return Vec3._new(0, 0, 0)
        end
        return Vec3._new(self.X / mag, self.Y / mag, self.Z / mag)
    end
    return rawget(Vec3, key)
end

function Vec3._new(nx: number, ny: number, nz: number)
    local mag = math.sqrt(nx * nx + ny * ny + nz * nz)
    return setmetatable({
        X = nx, Y = ny, Z = nz,
        x = nx, y = ny, z = nz,
        magnitude = mag,
        Magnitude = mag,
    }, Vec3)
end

function Vec3.__add(a, b)
    return Vec3._new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vec3.__sub(a, b)
    return Vec3._new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vec3.__mul(a, b)
    if type(a) == "number" then
        return Vec3._new(a * b.X, a * b.Y, a * b.Z)
    elseif type(b) == "number" then
        return Vec3._new(a.X * b, a.Y * b, a.Z * b)
    end
    return Vec3._new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end

function Vec3.__div(a, b)
    if type(b) == "number" then
        return Vec3._new(a.X / b, a.Y / b, a.Z / b)
    end
    return Vec3._new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end

function Vec3.__unm(a)
    return Vec3._new(-a.X, -a.Y, -a.Z)
end

function Vec3.__eq(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end

function Vec3.__tostring(self)
    return string.format("%g, %g, %g", self.X, self.Y, self.Z)
end

function Vec3:Dot(other)
    return self.X * other.X + self.Y * other.Y + self.Z * other.Z
end

function Vec3:Lerp(other, alpha: number)
    return Vec3._new(
        self.X + (other.X - self.X) * alpha,
        self.Y + (other.Y - self.Y) * alpha,
        self.Z + (other.Z - self.Z) * alpha
    )
end

function Vec3:Cross(other)
    return Vec3._new(
        self.Y * other.Z - self.Z * other.Y,
        self.Z * other.X - self.X * other.Z,
        self.X * other.Y - self.Y * other.X
    )
end

-- Construct the Vector3 namespace
local Vector3Compat = {
    new = function(x: number?, y: number?, z: number?)
        return Vec3._new(x or 0, y or 0, z or 0)
    end,
    zero = Vec3._new(0, 0, 0),
    one = Vec3._new(1, 1, 1),
    xAxis = Vec3._new(1, 0, 0),
    yAxis = Vec3._new(0, 1, 0),
    zAxis = Vec3._new(0, 0, 1),
}

local Loader = {}

function Loader.load(filePath: string): any
    local source = fs.readFile(filePath)

    local fn = luau.load(source, {
        debugName = filePath,
        environment = {
            Vector3 = Vector3Compat,
            CFrame = roblox.CFrame,
            Color3 = roblox.Color3,
        },
    })

    return fn()
end

-- Export Vector3Compat for use in test files
Loader.Vector3 = Vector3Compat

return Loader
