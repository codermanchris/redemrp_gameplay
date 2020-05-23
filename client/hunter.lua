-- Start Gameplay Thread
if (GameplayConfig.UseHunter) then
    Helpers.StartGameplay(Hunter)
end

-- Packet Handlers
Helpers.PacketHandler('hunter:SetDuty', function(data)
    Hunter.SetDuty(data.Value)
    Helpers.CancelPrompt(Hunter.OnDutyPrompt)
    Helpers.CancelPrompt(Hunter.OffDutyPrompt)
end)

-- Class Functions
function Hunter.Initialize()
    Hunter.SetupBlips()
    Hunter.SetupPrompts()
end

function Hunter.SetupBlips()
    for k, v in pairs(Hunter.Locations) do
        if (v.Blip) then
            RemoveBlip(v.Blip)
        end
        v.Blip = Helpers.AddBlip(BlipSpriteType.AmbientHunter, v.Coords, 'Hunter')
    end
end

function Hunter.SetupPrompts()
    -- register hunter prompts
    Hunter.OnDutyPrompt = Helpers.RegisterPrompt('Go On Duty', Controls.MultiplayerInfo, nil)
    Hunter.OffDutyPrompt = Helpers.RegisterPrompt('Go Off Duty', Controls.MultiplayerInfo, nil)
end

function Hunter.Tick()
    -- get player ped and coords
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed)) then
        return
    end

    -- get closest location
    Hunter.Closest = Helpers.GetClosestLocation(playerCoords, Hunter.Locations)
    Hunter.CurrentLocation = Hunter.Locations[Hunter.Closest.Index]

    -- 
    if (Hunter.IsOnDuty) then
        Hunter.HandleOnDuty(playerPed, playerCoords)
    else
        Hunter.HandleOffDuty(playerPed, playerCoords)
    end
end

function Hunter.SetDuty(value)
    Hunter.IsOnDuty = value
    if (value) then
        Hunter.CurrentDutyLocation = Hunter.CurrentLocation
        Hunter.NextPredatorSpawn = GetGameTimer()
    else
        Hunter.CurrentDutyLocation = nil
        Hunter.NextPredatorSpawn = nil
    end
end

function Hunter.HandleOffDuty(playerPed, playerCoords)
    if (Hunter.Closest.Distance > 25.0) then
        return
    end

    -- draw duty marker
    local distanceToDuty = Helpers.GetDistance(playerCoords, Hunter.CurrentLocation.Coords)
    if (distanceToDuty < 5.0) then
        Helpers.DrawMarker(Hunter.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distanceToDuty < 1.0) then
            Hunter.HasDutyPrompt = true
            -- handle prompt for duty
            Helpers.Prompt(Hunter.OnDutyPrompt, function()
                -- ask the server to go on duty
                Helpers.Packet('hunter:GoOnDuty', { LocationId = Hunter.CurrentLocation.Id })
            end)
        else
            -- clear duty prompt
            if (distanceToDuty > 1.5 and Hunter.HasDutyPrompt) then                
                Hunter.HasDutyPrompt = false
                Helpers.CancelPrompt(Hunter.OnDutyPrompt)
            end
        end            
    end
end

function Hunter.HandleOnDuty(playerPed, playerCoords)
    -- go off duty if too far away
    if (Hunter.Closest.Distance > 250.0) then
        Helpers.Packet('hunter:GoOffDuty')
        return
    end

    -- deal with spawning predators
    Hunter.HandlePredators(playerPed, playerCoords)
end

function Hunter.HandlePredators(playerPed, playerCoords)
    -- deal with spawning predators
    if (Hunter.NextPredatorSpawn <= GetGameTimer()) then
        Hunter.NextPredatorSpawn = GetGameTimer() + Hunter.PredatorRespawnRate

        if (Hunter.PredatorCount < 5) then
            local coords = Hunter.CurrentDutyLocation.PredatorCoords[math.random(1, #Hunter.CurrentDutyLocation.PredatorCoords)]
            Hunter.SpawnPredator(coords)
        end
    end

    -- figure out if our predators have been killed yet
    for k, v in pairs(Hunter.Predators) do
        if (IsPedFatallyInjured(v.Ped) and not v.IsDead) then
            v.IsDead = true

            -- get killer information and notify server
            local killerPed = GetPedSourceOfDeath(v.Ped)
            local causeOfDeath = GetPedCauseOfDeath(v.Ped)
            local killerIndex = NetworkGetPlayerIndexFromPed(v.Ped)

            if (killerPed == PlayerPedId()) then
                Helpers.Packet('hunter:GotKill', { AnimalId = v.AnimalId })
                Hunter.PredatorCount = Hunter.PredatorCount - 1

                RemoveBlip(v.Blip)
            end
        end
    end
end

function Hunter.SpawnPredator(coords)
    Hunter.PredatorCount = Hunter.PredatorCount + 1
    Hunter.TotalPredatorCount = Hunter.TotalPredatorCount + 1    

    local data = {}
    data.AnimalId = math.random(1, 3)
    data.Ped = Helpers.SpawnNPC(Hunter.PredatorHashes[data.AnimalId], coords.x, coords.y, coords.z)
    data.IsDead = false
    data.Blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 953018525, data.Ped)

    Hunter.Predators[Hunter.TotalPredatorCount] = data    
end