local ServerMods = nil

local module = {}

function module:Setup(server)
    self.server = server

    --Give spawning players 100 hp
    server.OnPlayerSpawn:Connect(function(playerRecord)
        playerRecord.hitPoints = 100
        playerRecord.lastAttacker = nil
    end)
end

function module:Step(server, _deltaTime)
    local playerRecords = server:GetPlayers()

    for _, playerRecord in pairs(playerRecords) do
        --No character at the moment
        if playerRecord.chickynoid == nil then
            continue
        end

        if playerRecord.hitPoints <= 0 then
            -- Reward the killer
            if playerRecord.lastAttacker then
                if ServerMods == nil then
                    ServerMods = require(game.ServerScriptService.Packages.Chickynoid.Server.ServerMods)
                end
                local CurrencyManager = ServerMods:GetMod("servermods", "CurrencyManager")
                if CurrencyManager then
                    CurrencyManager:AddCoins(playerRecord.lastAttacker, CurrencyManager.KILL_REWARD)
                end
                playerRecord.lastAttacker = nil
            end
            playerRecord:Despawn()
        end
    end
end

function module:DamagePlayer(playerRecord, damage, attackerRecord)
    playerRecord.hitPoints -= damage
    if attackerRecord then
        playerRecord.lastAttacker = attackerRecord
    end
end

function module:GetPlayerHitPoints(playerRecord)
    return playerRecord.hitPoints
end

function module:SetPlayerHitPoints(playerRecord, hp)
    playerRecord.hitPoints = hp
end

return module