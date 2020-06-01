-- Packet Handlers
Helpers.PacketHandler('hunter:GoOnDuty', function(playerId, data)
    Hunter.GoOnDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('hunter:GoOffDuty', function(playerId, data)
    Hunter.GoOffDuty(playerId)
end)

Helpers.PacketHandler('hunter:GotKill', function(playerId, data)
    Hunter.GotKill(playerId, data.AnimalId)
end)

-- Class Functions
function Hunter.GoOnDuty(playerId, locationId)
    -- validate/get this location
    local location = Hunter.Locations[locationId]
    if (location == nil) then
        return
    end

    -- get character
    Helpers.GetCharacter(playerId, function(character)
        Hunter.Hunters[playerId] = locationId

        -- notify the player that she went on duty
        Helpers.Respond(playerId, '^2You went on duty, Hunter.')
        Helpers.Packet(playerId, 'hunter:SetDuty', { Value = true })
    end)
end

function Hunter.GoOffDuty(playerId)
    Helpers.Packet(playerId, 'hunter:SetDuty', { Value = false })
    Helpers.Respond(playerId, '^2You went off duty, Hunter.')
    Hunter.Hunters[playerId] = nil
end

function Hunter.OnPlayerDropped(playerId)
    if (Hunter.Hunters[playerId] ~= nil) then
        Hunter.Hunters[playerId] = nil
    end
end

function Hunter.GotKill(playerId, animalId)
    -- add money and xp
    Helpers.GetCharacter(playerId, function(character)
        local money = animalId * 1
        character.addMoney(money)

        Helpers.Respond(playerId, '^2You have been paid $' .. money .. ' for this kill. The pelt is yours.')
    end)
end

-- Payment Timer
function Hunter.PayTimer()
    SetTimeout(60000*5, function()
        for k, v in pairs(Hunter.Hunters) do
            Helpers.GetCharacter(k, function(character)
                character.addXP(5)
                character.addMoney(1)

                Helpers.Respond(k, '^2You have been paid $1.00 and received 5 xp for your work, Hunter.')
            end) 
        end

        Hunter.PayTimer()
    end)
end
Hunter.PayTimer()