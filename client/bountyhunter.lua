-- Start Gameplay Thread
if (GameplayConfig.UseBountyHunter) then
    Helpers.StartGameplay(BountyHunter)
end

-- Packet Handlers
Helpers.PacketHandler('bounty:SetBoard', function(data)
    BountyHunter.SetBoard(data.Bounties)
end)

Helpers.PacketHandler('bounty:StartMission', function(data)
    BountyHunter.StartMission(data.Bounty)
end)

-- UI Handlers
RegisterNUICallback('SelectBounty', function(data, cb)
    BountyHunter.SelectBounty(data.bountyId)
end)

-- Class Functions
function BountyHunter.Initialize()
    BountyHunter.SetupBlips()
    BountyHunter.SetupPrompts()
end

function BountyHunter.SetupBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(BountyHunter.Locations) do
            if (v.Blip ~= nil) then
                RemoveBlip(v.Blip)
            end
            v.Blip = Helpers.AddBlip(BlipSpriteType.ProcBountyPoster, v.Coords, 'Bounty Board')
        end        
    end)
end

function BountyHunter.SetupPrompts()
    BountyHunter.BoardPrompt = Helpers.RegisterPrompt('Bounty Board', Controls.MultiplayerInfo, nil)  
end

function BountyHunter.Tick()

    -- we need to get our player ped and coords
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed) or IsPedFatallyInjured(playerPed)) then
        -- if the player has no ped or is dead, clear prompts and get out
        Doctor.ClearPrompts()
        return
    end

    if (BountyHunter.CurrentBounty ~= nil) then
        BountyHunter.HandleMission(playerPed, playerCoords)
    end

    -- we need to find the closest bounty board
    BountyHunter.Closest = Helpers.GetClosestLocation(playerCoords, BountyHunter.Locations)

    -- if we're further than 35 units from a bounty board, only worry about about handling active missions
    if (BountyHunter.Closest.Distance > 35.0) then        
        return
    end

    -- cache our current location
    BountyHunter.CurrentLocation = BountyHunter.Locations[BountyHunter.Closest.Index]

    -- if we're close enough to a bounty board, show the marker to view it
    if (BountyHunter.Closest.Distance < 5.0) then
        Helpers.DrawMarker(BountyHunter.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to the prompt let's do stuff
        if (BountyHunter.Closest.Distance < 1.0) then
            -- complete the prompt and get bounty board
            Helpers.Prompt(BountyHunter.BoardPrompt, function()                
                Helpers.Packet('bounty:GetBoard', { LocationId = BountyHunter.Closest.Index })
                Helpers.OpenUI('bountyhunter', { LocationId = BountyHunter.Closest.Index })
            end)
        else
            -- cancel prompt if we ran too far away
            if (BountyHunter.Closest.Distance > 1.5) then
                Helpers.CancelPrompt(BountyHunter.BoardPrompt)
            end
        end
    end
end

function BountyHunter.SetBoard(bounties)
    Helpers.MessageUI('bountyhunter', 'setBoard', bounties)
end

function BountyHunter.SelectBounty(bountyId)    
    Helpers.Packet('bounty:SelectBounty', { LocationId = BountyHunter.CurrentLocation.Id, BountyId = bountyId })

    Helpers.CloseUI(true)
end

function BountyHunter.StartMission(bounty)
    -- setup cached data 
    BountyHunter.CurrentBounty = bounty
    BountyHunter.CurrentBounty.Location = BountyHunter.CurrentLocation
    BountyHunter.CurrentBounty.Coords = BountyHunter.Locations[bounty.LocationId].BountyCoords[bounty.BountyIndex].Coords

    -- add location blip
    if (BountyHunter.CurrentBounty.Blip ~= nil) then
        RemoveBlip(BountyHunter.CurrentBounty.Blip)
    end
    BountyHunter.CurrentBounty.Blip = Helpers.AddBlip(BlipSpriteType.MissionAreaBounty, BountyHunter.CurrentBounty.Coords, 'Bounty Location')

    -- spawn npcs
    BountyHunter.SpawnMissionPeds(bounty.Crime.MaxPedCount)
end

function BountyHunter.HandleMission(playerPed, playerCoords)
    -- return if no active bounty
    if (BountyHunter.CurrentBounty == nil) then
        return
    end

    -- let's get distance to the ped and handle some things if close enough
    local distanceToPed = Helpers.GetDistance(playerCoords, GetEntityCoords(BountyHunter.MissionPed, false))
    if (distanceToPed < 50.0) then
        -- we might have some prompts to deal with
        BountyHunter.HandlePrompts(playerPed, playerCoords)

        if (not BountyHunter.MissionPedAttacking) then
            -- make bounty attack player
            Citizen.InvokeNative(0xF166E48407BAC484, BountyHunter.MissionPed, PlayerPedId(), 0, 0)

            BountyHunter.MissionPedAttacking = true
        end
    else
        BountyHunter.MissionPedAttacking = false
    end

    -- let's try to drop off the bounty
    local distanceToDropOff = Helpers.GetDistance(playerCoords, BountyHunter.CurrentBounty.Location.DropOffCoords)
    if (distanceToDropOff < 25.0) then
        -- draw drop off marker
        Helpers.DrawMarker(BountyHunter.CurrentBounty.Location.DropOffCoords, Colors.Marker)

        -- if we have a mission ped
        if (BountyHunter.MissionPed ~= nil) then
            -- check distance from mission ped to drop off 
            local pedDistanceToDropOff = Helpers.GetDistance(GetEntityCoords(BountyHunter.MissionPed), BountyHunter.CurrentBounty.Location.DropOffCoords)            
            if (distanceToDropOff < 2.0 and pedDistanceToDropOff < 2.0) then
                -- if mission ped is close enough, let the player know
                Helpers.DrawText3d(BountyHunter.CurrentBounty.Location.DropOffCoords, 'DROP OFF BOUNTY', 1, 1)

                -- when the player drops the bounty notify server and complete the mission
                -- todo: make this allow dropping off of roped people too
                if (Helpers.IsControlPressed(Controls.Drop)) then
                    Helpers.Packet('bounty:DropOff')
                    SetTimeout(2000, function()
                        BountyHunter.CompleteMission()
                    end)
                end
            end
        end
    end
end

function BountyHunter.SpawnMissionPeds(maxPedCount)
    -- todo
    -- 1. make this spawn a group of peds
    -- 2. fine tune peds to match their crime
    --  2.a murders attack on sight
    --  2.b thieves cower
    --  2.c think about more.

    -- main mission ped
    local coords = BountyHunter.CurrentBounty.Coords
    BountyHunter.MissionPed = Helpers.SpawnNPC('A_M_M_UniGunslinger_01', coords.x, coords.y, coords.z)

    -- attach blip to ped
    if (BountyHunter.MissionPedBlip) then
        RemoveBlip(BountyHunter.MissionPedBlip)
    end    
    BountyHunter.MissionPedBlip = Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, BountyHunter.MissionPed)

    -- make this guy hate the player
    SetRelationshipBetweenGroups(5, 'A_M_M_UniGunslinger_01', 'PLAYER')

    -- give the guy a rifle perhaps
    if (math.random(1, 100) > 80) then
        GiveWeaponToPed_2(BountyHunter.MissionPed, WeaponHashes.RepeaterCarbine, 1, true, true, GetWeapontypeGroup(WeaponGroups.Repeater), true, 0.5, 1.0, 0, true, 0, 0)
    end

    -- spawn secondary peds
    if (maxPedCount > 1) then
        local pedCount = math.random(1, maxPedCount)

        print('spawning ' .. pedCount .. ' for bounty')
        for i = 1, pedCount do
            if (BountyHunter.MissionExtraPeds[i] ~= nil) then
                DeleteEntity(BountyHunter.MissionExtraPeds[i])
            end

            local pedCoords = GetOffsetFromEntityInWorldCoords(coords, -2.0 + i, -2.0, 0.0)
            BountyHunter.MissionExtraPeds[i] = Helpers.SpawnNPC('A_M_M_UniGunslinger_01', pedCoords.x, pedCoords.y, pedCoords.z)
            
            if (math.random(1, 100) > 80) then
                GiveWeaponToPed_2(BountyHunter.MissionExtraPeds[i], WeaponHashes.RepeaterCarbine, 1, true, true, GetWeapontypeGroup(WeaponGroups.Repeater), true, 0.5, 1.0, 0, true, 0, 0)
            end
        end    
    end
end

function BountyHunter.CompleteMission()
    if (BountyHunter.CurrentBounty.Blip ~= nil) then
        RemoveBlip(BountyHunter.CurrentBounty.Blip)
    end

    DeleteEntity(BountyHunter.MissionPed)
    
    if (BountyHunter.MissionPedBlip) then
        RemoveBlip(BountyHunter.MissionPedBlip)
    end

    BountyHunter.CurrentBounty = nil
end

function BountyHunter.HandlePrompts(playerPed, playerCoords)
    -- get aiming target
    local isAiming, aimTarget = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if (isAiming and DoesEntityExist(aimTarget)) then                
        -- make prompts
        if (not BountyHunter.CuffPrompt) then
            local groupId = PromptGetGroupIdForTargetEntity(aimTarget)
            BountyHunter.CuffPrompt = Helpers.RegisterPrompt('Cuff/Uncuff', Controls.Enter, groupId)
        end

        -- get aiming handle and make sure its a player
        local targetPlayerId = NetworkGetPlayerIndexFromPed(aimTarget)    
        local isNetworkPlayer = NetworkIsPlayerActive(targetPlayerId)
        -- handle prompt for cuffing
        Helpers.Prompt(BountyHunter.CuffPrompt, function()
            if (isNetworkPlayer) then
                -- notify server to cuff/uncuff this person
                Helpers.Packet('player:Cuff', { TargetId = targetPlayerId })
            end
        end)
    else
        if (BountyHunter.CuffPrompt ~= nil) then
            Helpers.RemovePrompt(BountyHunter.CuffPrompt)
            BountyHunter.CuffPrompt = nil
        end            
    end
end