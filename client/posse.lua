-- Start Gameplay Thread
if (GameplayConfig.UsePosse) then
    Helpers.StartGameplay(Posse)
end

-- Packet Handlers
Helpers.PacketHandler('posse:OpenCreate', function(data)
    if (Posse.PosseInfo ~= nil) then
        return
    end
    
    Helpers.MessageUI('posse', 'showCreate', nil)
    Helpers.SetUIFocus(true)
end)

Helpers.PacketHandler('posse:Open', function(data)
    if (Posse.PosseInfo == nil) then
        return
    end
    Helpers.OpenUI('posse', { Posse = Posse.PosseInfo, Members = Posse.PosseMembers, Rank = Posse.PosseRank })
end)

Helpers.PacketHandler('posse:OnCreate', function(data)
    Posse.OnCreate(data.Success)
end)

Helpers.PacketHandler('posse:SetMember', function(data)
    print('set member in posse ' .. data.PosseId)
end)

Helpers.PacketHandler('posse:SetMembers', function(data)
    Posse.PosseInfo = data.Posse
    Posse.PosseMembers = data.Members
    Posse.PosseRank = data.Rank
end)

-- Nui Callbacks
RegisterNUICallback('posse:Create', function(data, cb)
    Helpers.Packet('posse:Create', { PosseName = data.posseName })
    Helpers.CloseUI(true)
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

function Posse.OnCreate(success)
    if (success) then
        Helpers.CloseUI()
    else
        print('failed to create')
    end
end