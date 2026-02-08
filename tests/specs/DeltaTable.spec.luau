local framework = require("../lib/framework")
local Loader = require("../lib/loader")

local describe = framework.describe
local it = framework.it
local expect = framework.expect

local DeltaTable = Loader.load("src/ReplicatedFirst/Packages/Chickynoid/Shared/Vendor/DeltaTable.lua")

describe("DeltaTable.DeepCopy", function()
    it("creates an independent copy of a flat table", function()
        local original = { a = 1, b = "hello", c = true }
        local copy = DeltaTable:DeepCopy(original)
        expect(copy.a).toBe(1)
        expect(copy.b).toBe("hello")
        expect(copy.c).toBe(true)
    end)

    it("creates an independent copy of a nested table", function()
        local original = { a = 1, nested = { x = 10, y = 20 } }
        local copy = DeltaTable:DeepCopy(original)
        expect(copy.nested.x).toBe(10)
        expect(copy.nested.y).toBe(20)
    end)

    it("mutating the copy does not affect the original", function()
        local original = { a = 1, nested = { x = 10 } }
        local copy = DeltaTable:DeepCopy(original)
        copy.a = 999
        copy.nested.x = 999
        expect(original.a).toBe(1)
        expect(original.nested.x).toBe(10)
    end)
end)

describe("DeltaTable.MakeDeltaTable", function()
    it("returns a full copy when oldTable is nil", function()
        local newTable = { a = 1, b = 2 }
        local delta, changes = DeltaTable:MakeDeltaTable(nil, newTable)
        expect(delta.a).toBe(1)
        expect(delta.b).toBe(2)
    end)

    it("returns empty delta when tables are identical", function()
        local t = { a = 1, b = 2 }
        local delta, changes = DeltaTable:MakeDeltaTable(t, t)
        expect(changes).toBe(0)
    end)

    it("detects changed values", function()
        local old = { a = 1, b = 2 }
        local new = { a = 1, b = 99 }
        local delta, changes = DeltaTable:MakeDeltaTable(old, new)
        expect(changes).toBe(1)
        expect(delta.b).toBe(99)
    end)

    it("detects added keys", function()
        local old = { a = 1 }
        local new = { a = 1, b = 2 }
        local delta, _ = DeltaTable:MakeDeltaTable(old, new)
        expect(delta.b).toBe(2)
    end)

    it("detects deleted keys via __deletions", function()
        local old = { a = 1, b = 2 }
        local new = { a = 1 }
        local delta, _ = DeltaTable:MakeDeltaTable(old, new)
        expect(delta.__deletions).toBeTruthy()
        expect(delta.__deletions[1]).toBe("b")
    end)

    it("handles nested table changes", function()
        local old = { nested = { x = 1, y = 2 } }
        local new = { nested = { x = 1, y = 99 } }
        local delta, changes = DeltaTable:MakeDeltaTable(old, new)
        expect(changes).toBe(1)
        expect(delta.nested.y).toBe(99)
    end)
end)

describe("DeltaTable.ApplyDeltaTable", function()
    it("applies changed values to target", function()
        local target = { a = 1, b = 2 }
        local delta = { b = 99 }
        local result = DeltaTable:ApplyDeltaTable(target, delta)
        expect(result.a).toBe(1)
        expect(result.b).toBe(99)
    end)

    it("applies additions to target", function()
        local target = { a = 1 }
        local delta = { b = 2 }
        local result = DeltaTable:ApplyDeltaTable(target, delta)
        expect(result.a).toBe(1)
        expect(result.b).toBe(2)
    end)

    it("applies deletions (removes keys)", function()
        local target = { a = 1, b = 2 }
        local delta = { __deletions = { "b" } }
        local result = DeltaTable:ApplyDeltaTable(target, delta)
        expect(result.a).toBe(1)
        expect(result.b).toBeNil()
    end)

    it("handles nil target gracefully", function()
        local delta = { a = 1 }
        local result = DeltaTable:ApplyDeltaTable(nil, delta)
        expect(result.a).toBe(1)
    end)

    it("roundtrips: make delta then apply produces the new table", function()
        local old = { a = 1, b = 2, c = 3 }
        local new = { a = 1, b = 99, d = 4 }
        local delta, _ = DeltaTable:MakeDeltaTable(old, new)
        local result = DeltaTable:ApplyDeltaTable(old, delta)
        expect(result.a).toBe(1)
        expect(result.b).toBe(99)
        expect(result.d).toBe(4)
        expect(result.c).toBeNil()
    end)
end)
