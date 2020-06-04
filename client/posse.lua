-- Start Gameplay Thread
if (GameplayConfig.UsePosse) then
    Helpers.StartGameplay(Posse)
end

-- Packet Handlers
Helpers.PacketHandler('posse:Open', function(data)
    Helpers.OpenUI('posse', nil)
end)

-- Class Functions
function Posse.Initialize()
    Posse.SetupPrompts()    
end

function Posse.Tick()
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed)) then
        return
    end

    Posse.Closest = Helpers.GetClosestLocation(playerCoords, Posse.Locations)
    Posse.CurrentLocation = Posse.Locations[Posse.Closest.Index]

    if (Posse.IsPlayerMember) then
        Posse.HandleMember()
    else
        Posse.HandleCivilian()
    end
end

function Posse.HandleMember()

end

function Posse.HandleCivilian()

end
