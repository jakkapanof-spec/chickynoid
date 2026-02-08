local framework = require("../lib/framework")
local Loader = require("../lib/loader")

local describe = framework.describe
local it = framework.it
local expect = framework.expect

local Vector3 = Loader.Vector3

local CrunchTable = Loader.load("src/ReplicatedFirst/Packages/Chickynoid/Shared/Vendor/CrunchTable.lua")

describe("CrunchTable.Enum", function()
    it("has the correct enum values", function()
        expect(CrunchTable.Enum.FLOAT).toBe(1)
        expect(CrunchTable.Enum.VECTOR3).toBe(2)
        expect(CrunchTable.Enum.INT32).toBe(3)
        expect(CrunchTable.Enum.UBYTE).toBe(4)
    end)
end)

describe("CrunchTable.CreateLayout", function()
    it("creates a layout with empty pairTable", function()
        local layout = CrunchTable:CreateLayout()
        expect(#layout.pairTable).toBe(0)
    end)

    it("calculates totalBytes correctly for one FLOAT field", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT)
        -- FLOAT = 4 bytes + 2 index bytes = 6
        expect(layout.totalBytes).toBe(6)
    end)

    it("calculates totalBytes correctly for mixed fields", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT) -- 4
        layout:Add("pos", CrunchTable.Enum.VECTOR3) -- 12
        layout:Add("count", CrunchTable.Enum.INT32) -- 4
        layout:Add("flags", CrunchTable.Enum.UBYTE) -- 1
        -- Total = 4 + 12 + 4 + 1 + 2 (index) = 23
        expect(layout.totalBytes).toBe(23)
    end)
end)

describe("CrunchTable.BinaryEncodeTable / BinaryDecodeTable", function()
    it("roundtrips a table with FLOAT fields", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT)

        local original = { speed = 3.14 }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.speed).toBeCloseTo(3.14, 0.001)
    end)

    it("roundtrips a table with INT32 fields", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("count", CrunchTable.Enum.INT32)

        local original = { count = 42 }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.count).toBe(42)
    end)

    it("roundtrips a table with negative INT32", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("value", CrunchTable.Enum.INT32)

        local original = { value = -1000 }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.value).toBe(-1000)
    end)

    it("roundtrips a table with UBYTE fields", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("flags", CrunchTable.Enum.UBYTE)

        local original = { flags = 200 }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.flags).toBe(200)
    end)

    it("roundtrips a table with VECTOR3 fields", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("pos", CrunchTable.Enum.VECTOR3)

        local original = { pos = Vector3.new(1.5, 2.5, 3.5) }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.pos.X).toBeCloseTo(1.5)
        expect(decoded.pos.Y).toBeCloseTo(2.5)
        expect(decoded.pos.Z).toBeCloseTo(3.5)
    end)

    it("handles zero values (uses content bits to skip)", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT)
        layout:Add("count", CrunchTable.Enum.INT32)

        local original = { speed = 0, count = 0 }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.speed).toBe(0)
        expect(decoded.count).toBe(0)
    end)

    it("handles nil values (defaults to 0)", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT)

        local original = {} -- speed is nil
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.speed).toBe(0)
    end)

    it("preserves non-layout fields in the packet", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT)

        local original = { speed = 5.0, extraField = "hello" }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        -- extraField should remain in the encoded packet
        expect(encoded.extraField).toBe("hello")

        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)
        expect(decoded.extraField).toBe("hello")
        expect(decoded.speed).toBeCloseTo(5.0)
    end)

    it("handles mixed layout with all types", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("speed", CrunchTable.Enum.FLOAT)
        layout:Add("pos", CrunchTable.Enum.VECTOR3)
        layout:Add("count", CrunchTable.Enum.INT32)
        layout:Add("flags", CrunchTable.Enum.UBYTE)

        local original = {
            speed = 10.5,
            pos = Vector3.new(100, 200, 300),
            count = 7,
            flags = 128,
        }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.speed).toBeCloseTo(10.5)
        expect(decoded.pos.X).toBeCloseTo(100)
        expect(decoded.pos.Y).toBeCloseTo(200)
        expect(decoded.pos.Z).toBeCloseTo(300)
        expect(decoded.count).toBe(7)
        expect(decoded.flags).toBe(128)
    end)

    it("zero Vector3 decodes to Vector3.zero", function()
        local layout = CrunchTable:CreateLayout()
        layout:Add("pos", CrunchTable.Enum.VECTOR3)

        local original = { pos = Vector3.new(0, 0, 0) }
        local encoded = CrunchTable:BinaryEncodeTable(original, layout)
        local decoded = CrunchTable:BinaryDecodeTable(encoded, layout)

        expect(decoded.pos.X).toBeCloseTo(0)
        expect(decoded.pos.Y).toBeCloseTo(0)
        expect(decoded.pos.Z).toBeCloseTo(0)
    end)
end)
