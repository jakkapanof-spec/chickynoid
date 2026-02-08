local module = {}

function module:Setup(server)

    --Give spawning players their owned weapons
    server.OnPlayerSpawn:Connect(function(playerRecord)
        local ownedWeapons = playerRecord.ownedWeapons or { "Pistol" }
        for i, weaponName in ipairs(ownedWeapons) do
            playerRecord:AddWeaponByName(weaponName, i == 1)
        end
    end)

    server.OnBeforePlayerSpawn:Connect(function(playerRecord)

        playerRecord.chickynoid.simulation:SetAngle(math.rad(90), true)

    end)


    server.OnPlayerDespawn:Connect(function(playerRecord)
        --Remove all guns
        playerRecord:ClearWeapons()
    end)
end

function module:Step(_server, _deltaTime) end

return module