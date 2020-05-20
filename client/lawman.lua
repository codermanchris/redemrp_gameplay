Helpers.StartGameplay(Lawman)

function Lawman.Initialize()
end

function Lawman.Tick()
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed)) then
        return
    end

    Lawman.Closest = Helpers.GetClosestLocation(playerCoords, Lawman.Locations)
    Lawman.ClosestLocation = Lawman.Locations[Lawman.Closest.Index]
    if (Lawman.Closest.Distance > 35.0) then
        if (Lawman.IsOnDuty) then
            Lawman.HandleOnDuty(playerPed, playerCoords)
        end
        return
    end
    
    if (Lawman.IsOnDuty) then
        Lawman.HandleOnDuty(playerPed, playerCoords)
    else
        Lawman.HandleOffDuty(playerPed, playerCoords)
    end
end

function Lawman.HandleOnDuty(playerPed, playerCoords)
end

function Lawman.HandleOffDuty(playerPed, playerCoords)
end