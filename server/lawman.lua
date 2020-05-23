-- Packet Handlers
Helpers.PacketHandler('lawman:GoOnDuty', function(playerId, data)
    Lawman.GoOnDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('lawman:GoOffDuty', function(playerId, data)
    Lawman.GoOffDuty(playerId)
end)

-- Class Functions
function Lawman.GoOnDuty(playerId, locationId)
    -- validate/get this location
    local location = Lawman.Locations[locationId]
    if (location == nil) then
        return
    end

    -- get character
    Helpers.GetCharacter(playerId, function(character)
        -- validate that this person can do this
        if (character.getPermissions() < 5) then
            Helpers.Respond(playerId, '^1You can\'t do that.')
            return
        end

        -- set sheriff id for this location
        location.SheriffId = playerId

        -- notify the player that she went on duty
        Helpers.Respond(playerId, '^2You went on duty, Sheriff.')
    end)
end

function Lawman.GoOffDuty(playerId)
    for k, v in pairs(Lawman.Locations) do
        if (v.SheriffId == playerId) then
            v.SheriffId = nil
            break
        end
    end

    Helpers.Respond(playerId, '^2You went off duty, Sheriff.')
end

function Lawman.OnPlayerDropped(playerId)
    
end

-- Payment Timer
function Lawman.PayTimer()
    SetTimeout(60000*5, function()
        for k, v in pairs(Lawman.Locations) do
            if (v.SheriffId ~= nil) then
                Helpers.GetCharacter(v.SheriffId, function(character)
                    character.addXP(5)
                    character.addMoney(4)

                    Helpers.Respond(v.SheriffId, '^2You have been paid $4.00 and received 5 xp for your work, Sheriff.')
                end) 
            end
        end

        Lawman.PayTimer()
    end)
end
Lawman.PayTimer()