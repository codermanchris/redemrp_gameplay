-- Start Gameplay Thread
if (GameplayConfig.UseBountyHunter) then
    Helpers.StartGameplay(BountyHunter)
end

-- Packet Handlers

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
    BountyHunter.BoardPrompt = Helpers.RegisterPrompt('Bounty Board')  
end

function BountyHunter.Tick()

    -- we need to get our player ped and coords
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed) or IsPedFatallyInjured(playerPed)) then
        -- if the player has no ped or is dead, clear prompts and get out
        Doctor.ClearPrompts()
        return
    end

    -- we need to find the closest bounty board
    BountyHunter.Closest = Helpers.GetClosestLocation(playerCoords, BountyHunter.Locations)

    -- if we're further than 35 units from a bounty board, only worry about about handling active missions
    if (BountyHunter.Closest.Distance > 35.0) then        
        if (BountyHunter.IsPlayerOnMission) then
            BountyHunter.HandleMission(playerPed, playerCoords)
        end
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