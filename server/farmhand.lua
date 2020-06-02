-- Packet Handlers
Helpers.PacketHandler('farmhand:GoOnDuty', function(playerId, data)
    Farmhand.GoOnDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('farmhand:GoOffDuty', function(playerId, data)
    Farmhand.GoOffDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('farmhand:DropOff', function(playerId, data)
    Farmhand.DropOff(playerId, data.LocationId, data.ItemId)
end)

-- Class Functions
function Farmhand.GoOnDuty(playerId, locationId)
    local location = Farmhand.Locations[locationId]
    if (location == nil) then
        return
    end

    if (location.FarmerId ~= nil) then
        Helpers.Respond(playerId, '^1We already have a hand, sorry, partner.')
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        location.FarmerId = playerId

        -- notify player's chat
        Helpers.Respond(playerId, '^2You went on duty as a Farmhand.')

        -- notify client of duty status
        Helpers.Packet(playerId, 'farmhand:SetDuty', { Value = true })
    end)
end

function Farmhand.GoOffDuty(playerId, locationId)
    local location = Farmhand.Locations[locationId]
    if (location == nil) then
        return
    end

    if (location.FarmerId ~= playerId) then
        Helpers.Respond(playerId, '^1You don\'t work for us, get out of here.')
        return
    end

    location.FarmerId = nil

    Helpers.GetCharacter(playerId, function(character)    
        -- notify player's chat
        Helpers.Respond(playerId, '^2You went off duty, Farmhand.')

        -- notify client of duty status
        Helpers.Packet(playerId, 'farmhand:SetDuty', { Value = false })
    end)
end

function Farmhand.OnPlayerDropped(playerId)
    for k, v in pairs(Farmhand.Locations) do
        if (v.FarmerId == playerId) then
            v.FarmerId = nil
            break
        end
    end
end

function Farmhand.DropOff(playerId, locationId, itemId)
    local location = Farmhand.Locations[locationId]
    if (location == nil) then
        return
    end
    if (location.FarmerId ~= playerId) then
        return
    end
    
    Helpers.GetCharacter(playerId, function(character)    
        character.addXP(1)
    end)
end

-- Payment Timer
function Farmhand.PayTimer()
    SetTimeout(60000*5, function()
        for k, v in pairs(Farmhand.Locations) do
            if (v.FarmerId ~= nil) then
                Helpers.GetCharacter(v.FarmerId, function(character)
                    character.addXP(5)
                    character.addMoney(2)

                    Helpers.Respond(v.FarmerId, '^2You have been paid $2.00 and received 5 xp for your work, Farmhand.')
                end) 
            end
        end

        Farmhand.PayTimer()
    end)
end
Farmhand.PayTimer()