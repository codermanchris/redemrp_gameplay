-- RedM Events

AddEventHandler('playerDropped', function()
    -- cache player id for dumb reasons
    local playerId = source
    
    -- we need to notify managers of this player dropping in case she is doing something there
    BountyHunter.OnPlayerDropped(playerId)
    Delivery.OnPlayerDropped(playerId)
    Doctor.OnPlayerDropped(playerId)
    Fisher.OnPlayerDropped(playerId)
    Hunter.OnPlayerDropped(playerId)
    Lawman.OnPlayerDropped(playerId)
    Moonshiner.OnPlayerDropped(playerId)
end)

-- Packet Handlers
Helpers.PacketHandler('player:GiveMoney', function(playerId, data)
    Players.GiveMoney(playerId, data.TargetId, data.Amount)
end)

-- Class Functions
function Players.GiveMoney(playerId, targetId, amount)
    -- get from character
    Helpers.GetCharacter(playerId, function(character)
        -- validate from character has the money
        if (character.getMoney() < amount) then
            Helpers.Respond(playerId, '^1You don\'t have enough money to cover that, partner.')
            return
        end

        -- get the to character 
        Helpers.GetCharacter(targetId, function(targetCharacter)
            -- make the transfer
            targetCharacter.addMoney(amount)
            character.removeMoney(amount)

            -- notify players involved it happened
            Helpers.Respond(playerId, '^2You gave that person $' .. amount)
            Helpers.Respond(targetId, '^2You received $' .. amount)
        end)
    end)
end