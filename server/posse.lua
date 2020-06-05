-- Slash Commands
RegisterCommand('newposse', function(source, args, rawCommand)
    local playerId = source
    Helpers.Packet(playerId, 'posse:OpenCreate', nil)
end, false)

RegisterCommand('posse', function(source, args, rawCommand)
    local playerId = source
    Helpers.Packet(playerId, 'posse:Open', nil)
end, false)

RegisterCommand('posseinv', function(source, args, rawCommand)
    local playerId = source
    local targetId = tonumber(args[1])
    if (targetId == nil) then
        Helpers.Respond(playerId, '^5You need to specify a valid target id to send the invite to. /posseinv [playerid]')
        return
    end
    Posse.SendInvite(playerId, targetId)
end, false)

RegisterCommand('posseleave', function(source, args, rawCommand)
    local playerId = source
    Posse.Leave(playerId)
end, false)

-- Packet Handlers
Helpers.PacketHandler('posse:Create', function(playerId, data)
    Posse.Create(playerId, data.PosseName)
end)

Helpers.PacketHandler('posse:AcceptInvite', function(playerId, data)
    Posse.AcceptInvite(playerId)
end)

-- We need to tie into the redemrp:playerLoaded event so we can properly get this players posse information on character select
AddEventHandler('redemrp:playerLoaded', function(character)
    local _source = source
    Posse.OnPlayerLoaded(character)
end)

-- Class Functions
function Posse.Create(playerId, name)
    if (not Posse.IsNameValid(name)) then
        Helpers.Packet(playerId, 'posse:OnCreate', { Success = false })
        Helpers.Respond(playerId, '^1That name is invalid. Please try another.')
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        local realId = character.getSessionVar('realcharid')
        local query = 'insert into `posses` (Name, OwnerId) values (@Name, @OwnerId);'
        local params = {
            ['@Name'] = name,
            ['@OwnerId'] = realId
        }

        MySQL.Async.insert(query, params, function(posseId)
            if (posseId <= 0) then
                Helpers.Packet(playerId, 'posse:OnCreate', { Success = false })
                return
            end
            
            Helpers.Packet(playerId, 'posse:OnCreate', { Success = true })

            -- set session var
            character.setSessionVar('PosseId', posseId)

            -- add this member
            Posse.AddMember(playerId, realId, posseId)

            -- recache posse datas
            Posse.GetDatas()
        end)
    end)    
end

function Posse.IsNameValid(name)
    local query = 'select Id from `posses` where Name=@Name'
    local params = {
       ['@Name'] = name
    }
    local results = MySQL.Sync.fetchScalar(query, params)
    return results == nil or results == 0
end

function Posse.AddMember(playerId, characterId, posseId)
    local query = 'insert into `possemembers` (PosseId, CharacterId, Rank) values (@PosseId, @CharacterId, 0);'
    local params = {
        ['@PosseId'] = posseId,
        ['@CharacterId'] = characterId,
    }

    --
    MySQL.Async.insert(query, params, function(newId)
        Posse.GetPosseData(playerId)
    end)
end

function Posse.OnPlayerLoaded(playerId)
    Posse.GetPosseData(playerId)
end

function Posse.Leave(playerId)
    Helpers.GetCharacter(playerId, function(character)
        if (character == nil) then
            return
        end

        character.setSessionVar('PosseId', nil)
    
        Helpers.Packet(playerId, 'posse:Leave')

        local query = 'delete from `possemembers` where CharacterId=@CharacterId'
        local params = {
            ['@CharacterId'] = character.getSessionVar('realcharid')
        }
        MySQL.Async.execute(query, params, function(rowsChanged)
            
        end)
    end)
end

-- note: this required a modification to redem_roleplay to sv_main.lua line 55ish. the code is commented below
-- it's possible the actual db id was exposed somewhere, but i don't know redem that well yet.
    -- NOTE:
    -- This is a custom redemrp_gameplay modification
    -- Users[_source].setSessionVar("realcharid", _user.id)
-- todo
-- the following code is pretty ugly, but functional. still, clean it up.
function Posse.GetPosseData(playerId)
    Helpers.GetCharacter(playerId, function(character)
        local realId = character.getSessionVar('realcharid')
        local query = 'select Id, PosseId, Rank from `possemembers` where CharacterId=@CharacterId'
        local params = {
            ['@CharacterId'] = realId
        }
    
        -- get posse member data
        MySQL.Async.fetchAll(query, params, function(results)
            if (results == nil or results[1] == nil) then
                return
            end

            -- if we're in a posse, get the posse datas
            local q2 = 'select Id, Name, OwnerId from `posses` where Id=@PosseId'
            local p2 = {
                ['@PosseId'] = results[1].PosseId
            }
            MySQL.Async.fetchAll(q2, p2, function(r2)
                if (r2 == nil or r2[1] == nil) then
                    return
                end

                -- set posseid on character session var
                character.setSessionVar('PosseId', tonumber(r2[1].Id))
                print(tostring(character.getSessionVar('PosseId')))
                
                local q3 = 'select pm.Id, pm.CharacterId, pm.Rank, c.firstname, c.lastname from `possemembers` as pm inner join `characters` as c on c.Id = pm.CharacterId where pm.PosseId = @PosseId'
                local p3 = {
                    ['@PosseId'] = character.getSessionVar('PosseId')
                }

                -- if we have a posse, get the members list and then send it all to the player
                MySQL.Async.fetchAll(q3, p3, function(r3)
                    Helpers.Packet(playerId, 'posse:SetMembers', { Posse = r2[1], Rank = results[1].Rank, Members = r3 })
                end)
            end)
        end)
    end)    
end

function Posse.SendInvite(playerId, targetId)
    -- get player character
    Helpers.GetCharacter(playerId, function(character)
        if (character == nil) then
            return
        end

        -- get posse information
        local posseId = character.getSessionVar('PosseId')
        local posse = Posse.Posses[posseId]
        if (posse == nil) then
            print('Invalid Posse Id.')
            return
        end

        -- get target character
        Helpers.GetCharacter(targetId, function(target)
            if (target == nil) then
                return
            end

            -- make sure this person isn't in another posse
            --[[local posseId = target.getSessionVar('PosseId') or 0
            if (posseId > 0) then
                Helpers.Respond(playerId, '^1This person belongs to another posse.')
                return
            end]]

            -- set the target up to accept the request
            Posse.PosseInvites[targetId] = posseId

            -- send invite to player
            Helpers.Packet(playerId, 'posse:Invite', { Id = posse.Id, Name = posse.Name, InvitedBy = character.getFirstname() .. ' ' .. character.getLastname() })
        end)
    end)
end

function Posse.AcceptInvite(playerId)
    local posseId = Posse.PosseInvites[playerId] or 0
    if (posseId == 0) then
        print('No posse invite for ' .. playerId)
        return
    end

    -- get player character
    Helpers.GetCharacter(playerId, function(character)
        if (character == nil) then
            return
        end
        character.setSessionVar('PosseId', posseId)
        Posse.AddMember(playerId, character.getSessionVar('realcharid'), posseId)
        Posse.PosseInvites[playerId] = nil

        Helpers.Respond(playerId, '^2You have joined the posse.')
    end)
end

-- Load Posse datas and cache the infos
function Posse.GetDatas()
    local query = 'select * from `posses`'

    MySQL.Async.fetchAll(query, nil, function(results)
        if (results == nil or results[1] == nil) then
            return
        end
        for k, v in pairs(results) do
            Posse.Posses[v.Id] = v
        end
    end)
end
Posse.GetDatas()