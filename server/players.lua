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

-- Slash Commands
RegisterCommand('pigeon', function(source, args, rawCommand)
    local playerId = source    
    local targetId = tonumber(args[1])
    if (targetId == nil) then
        Helpers.Respond(playerId, '^1Invalid target id. /pigeon [player id]')
        return
    end

    Helpers.Packet(playerId, 'player:OpenPigeonEditor', { IsSender = true, TargetId = targetId })
end, false)

-- Packet Handlers
Helpers.PacketHandler('player:GiveMoney', function(playerId, data)
    Players.GiveMoney(playerId, data.TargetId, data.Amount)
end)

Helpers.PacketHandler('player:BonusXP', function(playerId, data)
    Players.BonusXP(playerId)
end)

Helpers.PacketHandler('player:SendPigeon', function(playerId, data)
    Players.SendPigeon(playerId, data.TargetId, data.Message)
end)

-- redemrp_inventory Item Handlers
Helpers.ItemHandler('Cheese', function(playerId)
    Players.FeedHorse(playerId, 50, 50)
end)

Helpers.ItemHandler('Bandage', function(playerId)
    Players.Bandage(playerId)
end)

Helpers.ItemHandler('Pigeon', function(playerId)

end)

-- Class Functions
function Players.GiveMoney(playerId, targetId, amount)
    print('try and give money ' .. playerId .. ' ' .. tostring(targetId) .. ' ' .. tostring(amount))
    -- get from character
    Helpers.GetCharacter(playerId, function(character)
        -- validate from character has the money
        if (character.getMoney() < amount) then
            Helpers.Respond(playerId, '^1You don\'t have enough money to cover that, partner.')
            return
        end

        -- get the to character 
        Helpers.GetCharacter(targetId, function(targetCharacter)
            if (targetCharacter == nil) then
                print('invalid target for give money')
                return
            end

            -- make the transfer
            targetCharacter.addMoney(amount)
            character.removeMoney(amount)

            -- notify players involved it happened
            Helpers.Respond(playerId, '^2You gave that person $' .. amount)
            Helpers.Respond(targetId, '^2You received $' .. amount)
        end)
    end)
end

function Players.BonusXP(playerId)
    Helpers.GetCharacter(playerId, function(character)
        if (character == nil) then
            return
        end

        local nextBonusAt = character.getSessionVar('NextBonusXP') or GetGameTimer()
        if (nextBonusAt > GetGameTimer()) then
            return
        end

        character.addXP(5)
        character.setSessionVar('NextBonusXP', GetGameTimer()+119000)

        -- todo
        -- the message feels annoying.
        -- add some kind of less annoying ui popup to show xp bonus
        --Helpers.Respond(playerId, '^2You received your 5 bonus XP.')
    end)
end

function Players.FeedHorse(playerId, health, stamina)
    Helpers.Packet(playerId, 'player:FeedHorse', { Health = health, Stamina = stamina })
end

function Players.Bandage(playerId)
    Helpers.GetCharacter(playerId, function(character)
        Helpers.Packet(playerId, 'player:UseBandage', { HealAmount = 50 })
        Helpers.Respond(playerId, '^2A bandage has been applied to you.')
    end)
end

function Players.SendPigeon(playerId, targetId, message)
    if (message == nil or message == '') then
        return
    end

    -- notify sending player to spawn pigeon
    Helpers.Packet(playerId, 'player:SpawnPigeon', { IsSender = true })

    -- set a timer to make target receive message at a later time. it takes time for the pigeon to arrive.  
    SetTimeout(60000, function()
        Helpers.Packet(targetId, 'player:SpawnPigeon', { IsSender = false })
        SetTimeout(5000, function()
            Helpers.Packet(playerId, 'player:OpenPigeonEditor', { IsSender = false, Message = message })
        end)        
    end)    
end