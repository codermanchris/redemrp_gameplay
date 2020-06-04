-- Slash Commands
RegisterCommand('newposse', function(source, args, rawCommand)
    local playerId = source
    Helpers.Packet(playerId, 'posse:OpenCreate', nil)
end, false)
RegisterCommand('posse', function(source, args, rawCommand)
    local playerId = source
    Helpers.Packet(playerId, 'posse:Open', nil)
end, false)

-- Packet Handlers
Helpers.PacketHandler('posse:Create', function(playerId, data)
    Posse.Create(playerId, data.PosseName)
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
        Helpers.Packet(playerId, 'posse:SetMember', { PosseId = posseId, Rank = 0 })
    end)
end

-- note: this required a modification to redem_roleplay to sv_main.lua line 55ish. the code is commented below
-- it's possible the actual db id was exposed somewhere, but i don't know redem that well yet.
    -- NOTE:
    -- This is a custom redemrp_gameplay modification
    -- Users[_source].setSessionVar("realcharid", _user.id)
-- todo
-- this is pretty ugly, but functional. still, clean it up.
function Posse.OnPlayerLoaded(playerId)
    Citizen.CreateThread(function()
        Helpers.GetCharacter(playerId, function(character)
            local realId = character.getSessionVar('realcharid')
            local query = 'select Id, PosseId, Rank from `possemembers` where CharacterId=@CharacterId'
            local params = {
                ['@CharacterId'] = realId
            }
        
            MySQL.Async.fetchAll(query, params, function(results)
                if (results == nil or results[1] == nil) then
                    return
                end

                local q2 = 'select Id, Name, OwnerId from `posses` where Id=@PosseId'
                local p2 = {
                    ['@PosseId'] = results[1].PosseId
                }
                MySQL.Async.fetchAll(q2, p2, function(r2)
                    if (r2 == nil or r2[1] == nil) then
                        return
                    end

                    character.setSessionVar('PosseId', tonumber(r2[1].Id))
                    
                    local q3 = 'select pm.Id, pm.CharacterId, pm.Rank, c.firstname, c.lastname from `possemembers` as pm inner join `characters` as c on c.Id = pm.CharacterId where pm.PosseId = @PosseId'
                    local p3 = {
                        ['@PosseId'] = character.getSessionVar('PosseId')
                    }
    
                    MySQL.Async.fetchAll(q3, p3, function(r3)
                        Helpers.Packet(playerId, 'posse:SetMembers', { Posse = r2[1], Rank = results[1].Rank, Members = r3 })
                    end)                     
                end)           
            end)
        end)        
    end)
end