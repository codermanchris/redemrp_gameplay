-- Packet Handlers
Helpers.PacketHandler('vehiclerental:Rent', function(playerId, data)
    VehicleRental.Rent(playerId, data.LocationId, data.VehicleId)
end)

Helpers.PacketHandler('vehiclerental:Return', function(playerId, data)
    VehicleRental.Return(playerId)
end)

-- Class Functions
function VehicleRental.Rent(playerId, locationId, vehicleId)
    local location = VehicleRental.Locations[locationId]
    if (location == nil) then
        return
    end

    local vehicle = location.Vehicles[vehicleId]
    if (vehicle == nil) then
        return
    end

    if (VehicleRental.Rentals[playerId]) then
        Helpers.Respond(playerId, '^1You can only have one rental at a time.')
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        -- $10 deposit
        local cost = vehicle.Price + 10
        if (character.getMoney() < cost) then
            Helpers.Respond(playerId, '^1You cannot afford that.')
            return
        end

        -- charge customer
        character.removeMoney(cost)
        Helpers.Respond(playerId, string.format('^2You paid $%d for your rental. Bring it back in one piece and you\'ll get your deposit back.', cost))

        -- cache data
        VehicleRental.Rentals[playerId] = vehicle

        -- notify character to spawn
        Helpers.Packet(playerId, 'vehiclerental:Spawn', { VehicleId = vehicleId })
    end)
end

function VehicleRental.Return(playerId)
    if (not VehicleRental.Rentals[playerId]) then
        Helpers.Respond(playerId, '^1You don\'t have a vehicle to return.')
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        -- charge customer
        character.addMoney(10)
        Helpers.Respond(playerId, '^2You have received your $10 deposit back.')

        -- cache data
        VehicleRental.Rentals[playerId] = nil
    end)
end