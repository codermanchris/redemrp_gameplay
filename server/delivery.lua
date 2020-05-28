-- Packet Handlers
Helpers.PacketHandler('delivery:GoOnDuty', function(playerId, data)
    Delivery.GoOnDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('delivery:GoOffDuty', function(playerId, data)
    Delivery.GoOffDuty(playerId)
end)

Helpers.PacketHandler('delivery:Complete', function(playerId, data)
    Delivery.CompleteDelivery(playerId, data.LocationId)
end)

-- Class Functions
function Delivery.GoOnDuty(playerId, locationId)
    local location = Delivery.Locations[locationId]
    if (location == nil) then
        return
    end

    --
    local deliveryIndex = math.random(1, #location.DropOffCoords)

    --
    Delivery.Drivers[playerId] = true
    Helpers.Respond(playerId, '^2You went on duty, Driver.')
    Helpers.Packet(playerId, 'delivery:SetDuty', { Value = true, DeliveryIndex = deliveryIndex })
end

function Delivery.GoOffDuty(playerId, locationId)
    Delivery.Drivers[playerId] = nil
    Helpers.Respond(playerId, '^2You went off duty, Driver.')
    Helpers.Packet(playerId, 'delivery:SetDuty', { Value = false })
end

function Delivery.OnPlayerDropped(playerId)
    if (Delivery.Drivers[playerId]) then
        Delivery.Drivers[playerId] = nil
    end
end

function Delivery.CompleteDelivery(playerId, locationId)
    local location = Delivery.Locations[locationId]
    if (location == nil) then
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        character.addXP(15)
        character.addMoney(math.random(1, 3))

        Helpers.Respond(playerId, '^2Thank you for my delivery. Here\'s a tip!')
        
        -- start new delivery
        local deliveryIndex = math.random(1, #location.DropOffCoords)
        Helpers.Packet(playerId, 'delivery:Start', { DeliveryIndex = deliveryIndex })
    end)
end

-- Payment Timer
function Delivery.PayTimer()
    SetTimeout(60000*5, function()
        for k, v in pairs(Delivery.Drivers) do
            Helpers.GetCharacter(k, function(character)
                character.addXP(5)
                character.addMoney(2)

                Helpers.Respond(k, '^2You have been paid $2.00 and received 5 xp for your work, Driver.')
            end) 
        end

        Delivery.PayTimer()
    end)
end
Delivery.PayTimer()