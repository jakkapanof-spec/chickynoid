local fs = require("@lune/fs")
local framework = require("./lib/framework")

local specsDir = "tests/specs"
local entries = fs.readDir(specsDir)

local specFiles = {}
for _, entry in entries do
    if string.match(entry, "%.spec%.luau$") then
        table.insert(specFiles, entry)
    end
end

table.sort(specFiles)
print(string.format("Found %d spec files\n", #specFiles))

for _, entry in specFiles do
    print("--- " .. entry .. " ---")
    require("./specs/" .. string.gsub(entry, "%.luau$", ""))
end

framework.summary()
