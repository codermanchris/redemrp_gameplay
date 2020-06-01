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

Helpers.PacketHandler('lawman:SearchPersons', function(playerId, data)
    Lawman.SearchPersons(playerId, data.FirstName, data.LastName)
end)

Helpers.PacketHandler('lawman:SearchArrests', function(playerId, data)
    Lawman.SearchArrests(playerId, data.CaseNumber, data.FirstName, data.LastName)
end)

Helpers.PacketHandler('lawman:SearchWarrants', function(playerId, data)
    Lawman.SearchWarrants(playerId, data.CaseNumber, data.FirstName, data.LastName)
end)

Helpers.PacketHandler('lawman:AddNote', function(playerId, data)
    Lawman.AddNote(playerId, data.LocationId, data.TargetId, data.Message)
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

function Lawman.SearchPersons(playerId, firstName, lastName)
    -- note:
    -- i am forced to use the LOWER function here because case sensitivty matters on the `characters` table apparently.
    -- this table is created with the redemrp_identity script so i don't want to change it as this will affect everyone
    -- that uses that resource.
    local query = 'select * from `characters` where ' 
    local queryAdds = ''
    if (firstName ~= nil and #firstName > 0) then
        queryAdds = queryAdds .. 'lower(FirstName) like @FirstName'
    end
    if (lastName ~= nil and #lastName > 0) then
        if (#queryAdds > 0) then
            queryAdds = queryAdds .. ' or ' 
        end
        queryAdds = queryAdds .. 'lower(LastName) like @LastName'
    end
    query = query .. queryAdds

    print(query)
    local params = {
        ['@FirstName'] = string.lower('%' .. firstName .. '%'),
        ['@LastName'] = string.lower('%' .. lastName .. '%')
    }
    
    -- perform query
    MySQL.Async.fetchAll(query, params, function(results)
        if (results == nil or results[1] == nil) then
            print('no results')
        end
        Helpers.Packet(playerId, 'lawman:OnSearchPersons', { Results = results })
    end)
end

function Lawman.SearchArrests(playerId, caseNumber, firstName, lastName)    
    local query = 'select * from `arrests` as a inner join `characters` as c on a.CharacterId = c.Id where a.CaseNumber like @CaseNumber or c.FirstName like @FirstName or c.LastName like @LastName'
    local params = {
        ['@CaseNumber'] = '%' .. caseNumber .. '%',
        ['@FirstName'] = '%' .. firstName .. '%',
        ['@LastName'] = '%' .. lastName .. '%',
    }
    
    -- perform query
    MySQL.Async.fetchAll(query, params, function(results)
        Helpers.Packet(playerId, 'lawman:OnSearchArrests', { Results = results })
    end)
end

function Lawman.SearchWarrants(playerId, caseNumber, firstName, lastName)  
    local query = 'select * from `warrants` as a inner join `characters` as c on a.CharacterId = c.Id where a.CaseNumber like @CaseNumber or c.FirstName like @FirstName or c.LastName like @LastName'
    local params = {
        ['@CaseNumber'] = '%' .. caseNumber .. '%',
        ['@FirstName'] = '%' .. firstName .. '%',
        ['@LastName'] = '%' .. lastName .. '%',
    }
    
    -- perform query
    MySQL.Async.fetchAll(query, params, function(results)
        Helpers.Packet(playerId, 'lawman:OnSearchWarrants', { Results = results })
    end) 
end

function Lawman.AddNote(playerId, locationId, targetId, message)
    if (#message > 255) then
        message = string.sub(message, 0, 254)
    end

    Helpers.GetCharacter(playerId, function(sheriff)
        Helpers.GetCharacter(targetId, function(target)
            local query = 'insert into `characternotes` set (CharacterId, SheriffId, LocationId, Message) values (@CharacterId, @SheriffId, @LocationId, @Message); select LAST_INSERT_ID();'
            local params = {
                ['@CharacterId'] = target.Id,
                ['@SheriffId'] = sheriff.Id,
                ['@LocationId'] = locationId,
                ['@Message'] = message
            }
            
            -- perform query
            MySQL.Async.fetchScalar(query, params, function(returnId)
                --
            end)            
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