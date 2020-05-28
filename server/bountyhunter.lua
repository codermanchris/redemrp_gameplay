-- Packet Handlers
Helpers.PacketHandler('bounty:GetBoard', function(playerId, data)
    BountyHunter.GetBoard(playerId, data.LocationId)
end)

Helpers.PacketHandler('bounty:SelectBounty', function(playerId, data)
    BountyHunter.SelectBounty(playerId, data.LocationId, data.BountyId)
end)

Helpers.PacketHandler('bounty:DropOff', function(playerId, data)
    BountyHunter.CompleteBounty(playerId)
end)

-- Class Functions
function BountyHunter.Initialize()
    -- unlock bounty coords for every bounty board location
    for _, location in pairs(BountyHunter.Locations) do
        for _, bountyCoords in pairs(location.BountyCoords) do
            bountyCoords.AvailableAt = GetGameTimer()
            bountyCoords.IsUsedBy = -1
        end        
    end
end
BountyHunter.Initialize()

-- Loop every N seconds and generate local bounties if required
function BountyHunter.GenerateBounties()
    SetTimeout(BountyHunter.BountyGenerateWait, function()
        for k, location in pairs(BountyHunter.Locations) do
            if (location.BountyCount < 8) then
                BountyHunter.CreateLocalBounty(k)
            end
        end
        BountyHunter.GenerateBounties()
    end)
end
-- start generating bounties
BountyHunter.GenerateBounties()

function BountyHunter.CreateLocalBounty(locationId)
    -- validate the location is good
    local location = BountyHunter.Locations[locationId]
    if (location == nil) then
        return
    end

    -- figure out who commited what crime
    local firstName, lastName = BountyHunter.GetRandomName()
    local crime = BountyHunter.GetRandomCrime()
    local bountyLocation = BountyHunter.GetAvailableLocation(location)

    -- if we didn't find a bounty location then bounties are on cooldown for this location until one is available
    if (bountyLocation == nil) then
        return
    end

    -- increase our bounty counter 
    location.BountyCount = location.BountyCount + 1
    BountyHunter.NextAvailableBountyId = BountyHunter.NextAvailableBountyId + 1 

    print('added bounty ' .. BountyHunter.NextAvailableBountyId .. ' for ' .. firstName .. ' ' .. lastName .. ' charged with ' .. tostring(crime.Name) .. ' with $' .. tostring(crime.Reward) .. ' reward in ' .. tostring(location.Name) .. ' last known location index ' .. tostring(bountyLocation.Id))

    -- build the data table to store and store it
    local data = {
        Id = BountyHunter.NextAvailableBountyId,
        LocationId = location.Id,
        BountyIndex = bountyLocation.Id,
        FirstName = firstName,
        LastName = lastName,
        Crime = crime,
        IsUsedBy = -1
    }
    table.insert(location.Bounties, data)
end

function BountyHunter.GetAvailableLocation(location)
    for k, v in pairs(location.BountyCoords) do
        if (GetGameTimer() > v.AvailableAt) then
            v.IsUsedBy = -1
            v.AvailableAt = GetGameTimer() + BountyHunter.BountyCooldown
            return v
        end
    end
    return nil
end

function BountyHunter.GetRandomCrime()
    return Crimes[math.random(1, #Crimes)]
end

function BountyHunter.GetRandomName()
    local firstName = FirstNames[math.random(1, #FirstNames)]
    local lastName = LastNames[math.random(1, #LastNames)]
    --print('generated name ' .. firstName .. ' ' .. lastName)
    return firstName, lastName
end

function BountyHunter.GetBoard(playerId, locationId)
    local location = BountyHunter.Locations[locationId]
    if (location == nil) then
        return
    end

    Helpers.Packet(playerId, 'bounty:SetBoard', { Bounties = location.Bounties })
end

function BountyHunter.SelectBounty(playerId, locationId, bountyId)
    local location = BountyHunter.Locations[locationId]
    if (location == nil) then
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        --
        local bounty = location.Bounties[bountyId]
        if (bounty == nil) then
            return
        end
    
        --
        if (bounty.IsUsedBy ~= -1) then
            Helpers.Respond(playerId, '^1That bounty has already been claimed.')
            return
        end

        --
        if (character.getLevel() >= 2) then
            bounty.IsUsedBy = playerId
            bounty.StartedAt = GetGameTimer()

            Helpers.Packet(playerId, 'bounty:StartMission', { Bounty = bounty })

            BountyHunter.Datas[playerId] = {
                BountyId = bountyId,
                LocationId = locationId
            }
        else
            Helpers.Respond(playerId, '^1You have to be at least level 2 in order to be a bounty hunter.')
        end    
    end)
end

function BountyHunter.CompleteBounty(playerId)
    Helpers.GetCharacter(playerId, function(character)
        local bountyData = BountyHunter.Datas[playerId]
        local location = BountyHunter.Locations[bountyData.LocationId]
        local bounty = location.Bounties[bountyData.BountyId]

        Helpers.Respond(playerId, string.format('^2You have been paid $%s for the bounty and awarded %d xp.', bounty.Crime.Reward, bounty.Crime.XP))

        -- pay character and add xp
        character.addMoney(bounty.Crime.Reward)
        character.addXP(bounty.Crime.XP)

        BountyHunter.Datas[playerId] = nil
        location.Bounties[bountyData.BountyId] = nil
    end)
end

function BountyHunter.OnPlayerDropped(playerId)
end