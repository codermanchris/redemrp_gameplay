-- Enable Lawman gameplay if wanted
if (GameplayConfig.UseLawman) then
    Helpers.StartGameplay(Lawman)
end

-- Packet Handlers

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
    Lawman.HandlePrompts(playerPed, playerCoords)

    -- we're at a sheriff's office
    if (Lawman.Closest.Distance < 25.0) then
        local distanceToArmory = Helpers.GetDistance(playerCoords, Lawman.ClosestLocation.ArmoryCoords)
        if (distanceToArmory < 5.0) then
            -- draw marker for armory
            Helpers.DrawMarker(Lawman.ClosestLocation.ArmoryCoords, Colors.Marker)

            -- if we're close enough to handle some promptness, do it
            if (distanceToArmory < 1.0) then
                -- handle prompt for armory
                Helpers.Prompt(Lawman.ArmoryPrompt, function()
                    print('access armory person')

                    -- notify server to cuff/uncuff this person
                    Helpers.Packet('lawman:GetArmory', { TargetId = targetPlayerId })
                end)
            else
                -- clear armory prompt
                if (distanceToArmory > 1.5) then
                    if (Lawman.ArmoryPrompt ~= nil) then
                        Helpers.RemovePrompt(Lawman.ArmoryPrompt)
                        Lawman.ArmoryPrompt = nil
                    end  
                end
            end
        end        
    end
end

function Lawman.HandleOffDuty(playerPed, playerCoords)
    if (Lawman.Closest.Distance > 25.0) then
        return
    end

    -- draw duty marker
    local distanceToDuty = Helpers.GetDistance(playerCoords, Lawman.ClosestLocation.DutyCoords)
    if (distanceToDuty < 5.0) then
        Helpers.DrawMarker(Lawman.ClosestLocation.DutyCoords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distanceToDuty < 1.0) then
            Lawman.HasDutyPrompt = true
            -- handle prompt for duty
            Helpers.Prompt(Lawman.OnDutyPrompt, function()
                -- ask the server to go on duty
                Helpers.Packet('lawman:GoOnDuty', { LocationId = Lawman.ClosestLocation.Id })
            end)
        else
            -- clear duty prompt
            if (distanceToDuty > 1.5 and Lawman.HasDutyPrompt) then                
                Lawman.HasDutyPrompt = false
                Helpers.CancelPrompt(Lawman.OnDutyPrompt)
            end
        end            
    end
end

function Lawman.HandlePrompts(playerPed, playerCoords)
    -- get aiming target
    local isAiming, aimTarget = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if (isAiming and DoesEntityExist(aimTarget)) then                
        -- get aiming handle and make sure its a player
        local targetPlayerId = NetworkGetPlayerIndexFromPed(aimTarget)    
        if (NetworkIsPlayerActive(targetPlayerId)) then
            -- get target ped and coords
            local targetPed = GetPlayerPed(targetPlayerId)
            local targetCoords = GetEntityCoords(targetPed)

            -- make prompt
            if (not Lawman.CuffPrompt) then
                local groupId = PromptGetGroupIdForTargetEntity(aimTarget)
                Lawman.CuffPrompt = Helpers.RegisterPrompt('Cuff/Uncuff', Controls.Enter, groupId)
            end
            
            -- handle prompt for cuffing
            Helpers.Prompt(Lawman.CuffPrompt, function()
                print('cuff person')

                -- notify server to cuff/uncuff this person
                Helpers.Packet('lawman:Cuff', { TargetId = targetPlayerId })
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