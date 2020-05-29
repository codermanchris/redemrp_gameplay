-- Packet Handlers
Helpers.PacketHandler('lawman:GoOnDuty', function(playerId, data)
    Lawman.GoOnDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('lawman:GoOffDuty', function(playerId, data)
    Lawman.GoOffDuty(playerId)
end)

Helpers.PacketHandler('lawman:GetArmoryItem', function(playerId, data)
    Lawman.GetArmoryItem(playerId, data.ItemId)
end)

Helpers.PacketHandler('lawman:Cuff', function(playerId, data)
    Lawman.Cuff(playerId, data.TargetId)
end)

Helpers.PacketHandler('lawman:Escort', function(playerId, data)
    Lawman.Escort(playerId, data.TargetId)
end)

Helpers.PacketHandler('lawman:Hogtie', function(playerId, data)
    Lawman.Hogtie(playerId, data.TargetId)
end)

-- Class Functions
function Lawman.GoOnDuty(playerId, locationId)
    -- validate/get this location
    local location = Lawman.Locations[locationId]
    if (location == nil) then
        return
    end

    if (location.SheriffId ~= nil) then
        Helpers.Respond(playerId, '^1We already have a sheriff.')
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

        Helpers.Packet(playerId, 'lawman:SetDuty', { Value = true })
    end)
end

function Lawman.GoOffDuty(playerId)
    -- set this person as off duty if on duty
    for k, v in pairs(Lawman.Locations) do
        if (v.SheriffId == playerId) then
            v.SheriffId = nil
            break
        end
    end

    -- do stuffs
    Helpers.Respond(playerId, '^2You went off duty, Sheriff.')
    Helpers.Packet(playerId, 'lawman:SetDuty', { Value = false })
end

function Lawman.OnPlayerDropped(playerId)
    -- clear this person if they are a sheriff
    for k, v in pairs(Lawman.Locations) do
        if (v.SheriffId == playerId) then
            v.SheriffId = nil
            break
        end
    end    
end

function Lawman.GetArmoryItem(playerId, locationId, itemId)
    -- get location of this armory
    local location = Lawman.Locations[locationId]
    if (location == nil) then
        return
    end

    -- make sure this is the sheriff
    if (location.SheriffId ~= playerId) then
        Helpers.Respond(playerId, '^1You are not a lawman.')
        return
    end

    -- validate item data
    local itemData = location.Armory[itemId]
    if (itemData == nil) then
        return
    end
    
    -- get inventory data and add item
    Helpers.GetInventory(function(inventory)
        inventory.addItem(playerId, itemData.Name, itemData.Ammo, itemData.WeaponHash)
    end)    
end

function Lawman.Cuff(playerId, targetId)
    print('try to cuff ' .. playerId .. ' ' .. tostring(targetId))
    Helpers.GetCharacter(playerId, function(lawman) 
        -- validate lawman
        if (lawman == nil) then
            return
        end

        Helpers.GetCharacter(targetId, function(suspect)
            -- validate suspect
            if (suspect == nil) then
                print('no suspect in cuff')
                return
            end

            -- assign session var
            local isCuffed = suspect.getSessionVar('IsCuffed') or false
            suspect.setSessionVar('IsCuffed', not isCuffed)

            -- notify target that cuffs need to be put on
            Helpers.Packet(targetId, 'player:Restrain', { LawmanId = playerId, RestraintType = 0 })
        end)
    end)
end

function Lawman.Escort(playerId, targetId)
    Helpers.GetCharacter(playerId, function(lawman) 
        -- validate lawman
        if (lawman == nil) then
            return
        end

        Helpers.GetCharacter(targetId, function(suspect)
            -- validate suspect
            if (suspect == nil) then
                return
            end

            -- assign session var
            local isEscorted = suspect.getSessionVar('IsEscorted') or false
            suspect.setSessionVar('IsEscorted', not isEscorted)

            -- notify target that cuffs need to be put on
            Helpers.Packet(targetId, 'player:Escort', { LawmanId = playerId })
        end)
    end)
end

function Lawman.Hogtie(playerId, targetId)
    Helpers.GetCharacter(playerId, function(lawman) 
        -- validate lawman
        if (lawman == nil) then
            return
        end

        Helpers.GetCharacter(targetId, function(suspect)
            -- validate suspect
            if (suspect == nil) then
                return
            end

            -- assign session var
            local isHogtied = suspect.getSessionVar('IsHogtied') or false
            suspect.setSessionVar('IsHogtied', not isHogtied)

            -- notify target that cuffs need to be put on
            Helpers.Packet(targetId, 'player:Hogtie', { LawmanId = playerId })
        end)
    end)  
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