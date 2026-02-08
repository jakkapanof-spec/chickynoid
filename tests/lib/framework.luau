local stdio = require("@lune/stdio")
local process = require("@lune/process")

local Framework = {}
Framework._currentSuite = nil :: string?
Framework._results = { passed = 0, failed = 0 }

function Framework.describe(name: string, fn: () -> ())
    Framework._currentSuite = name
    local ok, err = pcall(fn)
    if not ok then
        Framework._results.failed += 1
        print(stdio.color("red") .. "  FAIL " .. stdio.color("reset") .. name .. " > (suite error)")
        print(stdio.color("red") .. "       " .. tostring(err) .. stdio.color("reset"))
    end
    Framework._currentSuite = nil
end

function Framework.it(name: string, fn: () -> ())
    local fullName = (Framework._currentSuite or "?") .. " > " .. name
    local ok, err = pcall(fn)
    if ok then
        Framework._results.passed += 1
        print(stdio.color("green") .. "  PASS " .. stdio.color("reset") .. fullName)
    else
        Framework._results.failed += 1
        print(stdio.color("red") .. "  FAIL " .. stdio.color("reset") .. fullName)
        print(stdio.color("red") .. "       " .. tostring(err) .. stdio.color("reset"))
    end
end

function Framework.expect(value: any)
    local expectObj = {}

    function expectObj.toBe(expected: any)
        if value ~= expected then
            error(string.format("Expected %s but got %s", tostring(expected), tostring(value)), 2)
        end
    end

    function expectObj.toBeCloseTo(expected: number, tolerance: number?)
        local tol = tolerance or 0.0001
        if math.abs(value - expected) > tol then
            error(string.format("Expected ~%s but got %s (tolerance %s)", tostring(expected), tostring(value), tostring(tol)), 2)
        end
    end

    function expectObj.toBeTruthy()
        if not value then
            error(string.format("Expected truthy but got %s", tostring(value)), 2)
        end
    end

    function expectObj.toBeFalsy()
        if value then
            error(string.format("Expected falsy but got %s", tostring(value)), 2)
        end
    end

    function expectObj.toBeNil()
        if value ~= nil then
            error(string.format("Expected nil but got %s", tostring(value)), 2)
        end
    end

    function expectObj.toBeGreaterThan(expected: number)
        if value <= expected then
            error(string.format("Expected > %s but got %s", tostring(expected), tostring(value)), 2)
        end
    end

    function expectObj.toBeLessThan(expected: number)
        if value >= expected then
            error(string.format("Expected < %s but got %s", tostring(expected), tostring(value)), 2)
        end
    end

    function expectObj.toThrow()
        if type(value) ~= "function" then
            error("toThrow() expects a function", 2)
        end
        local ok, _ = pcall(value)
        if ok then
            error("Expected function to throw but it did not", 2)
        end
    end

    return expectObj
end

function Framework.summary()
    print("")
    local total = Framework._results.passed + Framework._results.failed
    print(string.format("Results: %d passed, %d failed, %d total", Framework._results.passed, Framework._results.failed, total))

    if Framework._results.failed > 0 then
        print(stdio.color("red") .. "TESTS FAILED" .. stdio.color("reset"))
        process.exit(1)
    else
        print(stdio.color("green") .. "ALL TESTS PASSED" .. stdio.color("reset"))
    end
end

return Framework
