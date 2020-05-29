-- Enable Lawman gameplay if wanted
if (GameplayConfig.UseLawman) then
    Helpers.StartGameplay(Lawman)
end

-- Packet Handlers
Helpers.PacketHandler('lawman:SetDuty', function(data)
    Lawman.IsOnDuty = data.Value
    Helpers.CancelPrompt(Lawman.OnDutyPrompt)
    Helpers.CancelPrompt(Lawman.OffDutyPrompt)
end)

-- Class Functions
function Lawman.Initialize()
    Lawman.SetupBlips()
    Lawman.SetupPrompts()
end

function Lawman.SetupBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(Lawman.Locations) do
            if (v.Blip ~= nil) then
                RemoveBlip(v.Blip)
            end
            v.Blip = Helpers.AddBlip(BlipSpriteType.AmbientSheriff, v.Coords, 'Sheriff\'s Office')
        end        
    end)
end

function Lawman.SetupPrompts()
    Lawman.OnDutyPrompt = Helpers.RegisterPrompt('Go On Duty', Controls.MultiplayerInfo, nil)
    Lawman.OffDutyPrompt = Helpers.RegisterPrompt('Go Off Duty', Controls.MultiplayerInfo, nil)
    Lawman.ArmoryPrompt = Helpers.RegisterPrompt('Armory', Controls.MultiplayerInfo, nil)
    Lawman.PaperworkPrompt = Helpers.RegisterPrompt('Paperwork', Controls.MultiplayerInfo, nil)

    -- cuff/uncuff prompt 
    -- escort
end

function Lawman.Tick()
    -- get player ped and coords
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed)) then
        return
    end

    -- get closest location and return at this point if too far away
    Lawman.Closest = Helpers.GetClosestLocation(playerCoords, Lawman.Locations)
    Lawman.ClosestLocation = Lawman.Locations[Lawman.Closest.Index]
    
    -- handle on duty anywhere
    if (Lawman.IsOnDuty) then
        Lawman.HandleOnDuty(playerPed, playerCoords)
    else
        Lawman.HandleOffDuty(playerPed, playerCoords)
    end
end

function Lawman.HandleOnDuty(playerPed, playerCoords)
    -- handle prompts
    Lawman.ProcessPrompts(playerPed, playerCoords)

    -- we're at a sheriff's office
    if (Lawman.Closest.Distance < 25.0) then
        Lawman.ProcessOffDutyMarker(playerCoords)
        Lawman.ProcessArmoryMarker(playerCoords)
        Lawman.ProcessPaperworkMarker(playerCoords)
    end
end

-- Off Duty Handling
function Lawman.HandleOffDuty(playerPed, playerCoords)
    if (Lawman.Closest.Distance > 25.0) then
        return
    end

    Lawman.ProcessOnDutyMarker(playerCoords)
end

function Lawman.ProcessOnDutyMarker(playerCoords)
    local distance = Helpers.GetDistance(playerCoords, Lawman.ClosestLocation.DutyCoords)
    if (distance < 5.0) then
        Helpers.DrawMarker(Lawman.ClosestLocation.DutyCoords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distance < 1.0) then
            Lawman.HasDutyPrompt = true
            -- process prompt and request duty from server
            Helpers.Prompt(Lawman.OnDutyPrompt, function()
                Helpers.Packet('lawman:GoOnDuty', { LocationId = Lawman.ClosestLocation.Id })
            end)
        else
            -- clear duty prompt
            if (distance > 1.5 and Lawman.HasDutyPrompt) then                
                Lawman.HasDutyPrompt = false
                Helpers.CancelPrompt(Lawman.OnDutyPrompt)
            end
        end            
    end
end

function Lawman.ProcessOffDutyMarker(playerCoords)
    local distance = Helpers.GetDistance(playerCoords, Lawman.ClosestLocation.DutyCoords)
    if (distance < 5.0) then
        -- draw marker for armory
        Helpers.DrawMarker(Lawman.ClosestLocation.DutyCoords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distance < 1.0) then
            Lawman.HasOffDutyPrompt = true

            -- process prompt and request armory from server
            Helpers.Prompt(Lawman.OffDutyPrompt, function()
                Helpers.Packet('lawman:GoOffDuty', { LocationId = Lawman.ClosestLocation.Id })
            end)
        else
            -- clear armory prompt
            if (distance > 1.5 and Lawman.HasOffDutyPrompt) then
                Lawman.HasOffDutyPrompt = false
                Helpers.CancelPrompt(Lawman.OffDutyPrompt)                    
            end
        end
    end
end

function Lawman.ProcessArmoryMarker(playerCoords)
    local distance = Helpers.GetDistance(playerCoords, Lawman.ClosestLocation.ArmoryCoords)
    if (distance < 5.0) then
        -- draw marker for armory
        Helpers.DrawMarker(Lawman.ClosestLocation.ArmoryCoords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distance < 1.0) then
            Lawman.HasArmoryPrompt = true

            -- process prompt and request armory from server
            Helpers.Prompt(Lawman.ArmoryPrompt, function()
                Helpers.Packet('lawman:GetArmory', { TargetId = targetPlayerId })
            end)
        else
            -- clear armory prompt
            if (distance > 1.5 and Lawman.HasArmoryPrompt) then
                Lawman.HasArmoryPrompt = false
                Helpers.CancelPrompt(Lawman.ArmoryPrompt)                    
            end
        end
    end
end

function Lawman.ProcessPaperworkMarker(playerCoords)
    -- if we're close enough to show this marker
    local distance = Helpers.GetDistance(playerCoords, Lawman.ClosestLocation.PaperworkCoords)
    if (distance < 5.0) then
        -- draw marker for paperwork
        Helpers.DrawMarker(Lawman.ClosestLocation.PaperworkCoords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distance < 1.0) then
            Lawman.HasPaperworkPrompt = true

            -- process prompt and open lawman ui
            Helpers.Prompt(Lawman.PaperworkPrompt, function()
                Helpers.OpenUI('lawman', nil)
            end)
        else
            -- clear paperwork prompt
            if (distance > 1.5 and Lawman.HasPaperworkPrompt) then
                Lawman.HasPaperworkPrompt = false
                Helpers.CancelPrompt(Lawman.PaperworkPrompt)                    
            end
        end
    end
end

function Lawman.ProcessPrompts(playerPed, playerCoords)
    -- get aiming target
    local isAiming, aimTarget = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if (isAiming and DoesEntityExist(aimTarget)) then                
        -- get aiming handle and make sure its a player
        local targetPlayerId = NetworkGetPlayerIndexFromPed(aimTarget)

        --GetPlayerServerId(aimTarget)
        if (NetworkIsPlayerActive(targetPlayerId)) then
            -- get target ped and coords
            local targetPed = GetPlayerPed(targetPlayerId)
            local targetCoords = GetEntityCoords(targetPed)
            local targetNetworkId = GetPlayerServerId(targetPlayerId)

            if (Helpers.GetDistance(playerCoords, targetCoords) > 3.0) then
                return
            end

            -- make prompt
            if (not Lawman.CuffPrompt) then
                local groupId = PromptGetGroupIdForTargetEntity(aimTarget)
                Lawman.CuffPrompt = Helpers.RegisterPrompt('Cuff/Uncuff', Controls.Enter, groupId)
            end
            
            -- handle prompt for cuffing
            Helpers.Prompt(Lawman.CuffPrompt, function()
                -- notify server to cuff/uncuff this person
                Helpers.Packet('lawman:Cuff', { TargetId = targetNetworkId })
            end)
        else
            -- its a local
        end
    else
        -- clear cuff prompt
        if (Lawman.CuffPrompt ~= nil) then
            Helpers.RemovePrompt(Lawman.CuffPrompt)
            Lawman.CuffPrompt = nil
        end            
    end
end