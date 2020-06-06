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
    Posse.SetData(data.Posse, data.Members, data.Rank)
end)

Helpers.PacketHandler('posse:SetMembers', function(data)
    Posse.SetData(data.Posse, data.Members, data.Rank)
end)

Helpers.PacketHandler('posse:Invite', function(data)
    Posse.OnReceiveInvite(data.Id, data.Name, data.InvitedBy)
end)

Helpers.PacketHandler('posse:Leave', function(data)
    Posse.Leave()
end)

-- Nui Callbacks
RegisterNUICallback('posse:Create', function(data, cb)
    Helpers.Packet('posse:Create', { PosseName = data.posseName })
    Helpers.CloseUI(true)
end)

RegisterNUICallback('posse:AcceptInvite', function(data, cb)
    Helpers.Packet('posse:AcceptInvite')
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

function Posse.SetData(posse, members, rank)
    Posse.PosseInfo = posse
    Posse.PosseMembers = members
    Posse.PosseRank = rank

    -- setup relationship shiz
    AddRelationshipGroup(Posse.PosseInfo.Name)
    SetRelationshipBetweenGroups(1, 'PLAYER', Posse.PosseInfo.Name)
    SetRelationshipBetweenGroups(1, Posse.PosseInfo.Name, 'PLAYER')
    SetPedRelationshipGroupHash(PlayerPedId(), Posse.PosseInfo.Name)
end

function Posse.OnReceiveInvite(posseId, posseName, invitedBy)
    Helpers.MessageUI('posse', 'openInvite', { PosseId = posseId, PosseName = posseName, InvitedBy = invitedBy })
    Helpers.SetUIFocus(true)
end

function Posse.Leave()
    if (Posse.PosseInfo == nil) then
        return
    end

    -- set relationship stuffs just in case and then remove it
    SetRelationshipBetweenGroups(5, 'PLAYER', Posse.PosseInfo.Name)
    SetRelationshipBetweenGroups(5, Posse.PosseInfo.Name, 'PLAYER')    
    RemoveRelationshipGroup(Posse.PosseInfo.Name)

    -- clear datas
    Posse.PosseInfo = nil
    Posse.PosseMembers = nil
    Posse.PosseRank = nil    
end