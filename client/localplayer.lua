-- Start Gameplay Thread
Helpers.StartGameplay(LocalPlayer)

-- Packet Handlers
Helpers.PacketHandler('player:Restrain', function(data)
    if (data.RestraintType == 0) then -- cuffs
        LocalPlayer.ToggleCuffs()
    elseif (data.RestraintType == 1) then -- ankle cuffs
        LocalPlayer.ToggleAnkleCuffs()
    end
end)

Helpers.PacketHandler('player:FeedHorse', function(data)
    LocalPlayer.FeedHorse(data.Health, data.Stamina)
end)

Helpers.PacketHandler('player:UseBandage', function(data)
    LocalPlayer.UseBandage(data.HealAmount)
end)

Helpers.PacketHandler('player:SpawnPigeon', function(data)
    LocalPlayer.SpawnPigeon(data.IsSender)
end)

Helpers.PacketHandler('player:OpenPigeonEditor', function(data)
    -- todo: come up with a better plan for finding target id
    if (data.TargetId ~= nil) then        
        LocalPlayer.PigeonTargetId = data.TargetId
    end

    -- open pigeon carrier ui
    Helpers.OpenUI('pigeoncarrier', data)
end)

-- Nui Callbacks
RegisterNUICallback('player:SendPigeon', function(data, cb)
    Helpers.Packet('player:SendPigeon', { TargetId = LocalPlayer.PigeonTargetId, Message = data.Message })  
end)

-- Class Functions
function LocalPlayer.Initialize()
    LocalPlayer.NextBonusAt = GetGameTimer()

    -- hide reticule
    -- note: this also causes the blue circle, gold bars and money icons on top-right of screen to appear
    Citizen.InvokeNative(0x4CC5F2FC1332577F, HudHashes.Reticule)

    -- this shows reticule
    --Citizen.InvokeNative(0x8BC7C1F929D07BF3, HudHashes.Reticule)

    AddRelationshipGroup('PigeonCarrier')
    SetRelationshipBetweenGroups(1, 'PigeonCarrier', 'PLAYER')
end

function LocalPlayer.Tick()
    -- get player ped and coords
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed)) then
        return
    end

    -- if the player is dead, just return
    if (LocalPlayer.IsDead) then
        return
    end

    -- if the player is restrained, handle it
    if (LocalPlayer.IsCuffed or LocalPlayer.IsHogtied) then
        LocalPlayer.HandleRestrained(playerPed, playerCoords)
        return
    end

    -- handle prompts
    LocalPlayer.HandlePrompts(playerPed, playerCoords)

    -- handle bonus xp
    LocalPlayer.HandleBonusXP()

    -- toggle hands up
    if (IsControlJustPressed(0, Controls.GameMenuTabRightSecondary))  then
        LocalPlayer.ToggleHandsUp()
    end
end

function LocalPlayer.HandleBonusXP()
    if (LocalPlayer.NextBonusAt < GetGameTimer()) then
        LocalPlayer.NextBonusAt = GetGameTimer() + (60000 * 2)

        Helpers.Packet('player:BonusXP')
    end
end

function LocalPlayer.HandlePrompts(playerPed, playerCoords)
    -- get aiming target
    local isAiming, aimTarget = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if (isAiming and DoesEntityExist(aimTarget)) then                
        -- get aiming handle and make sure its a player
        local targetPlayerId = NetworkGetPlayerIndexFromPed(aimTarget)    
        if (NetworkIsPlayerActive(targetPlayerId)) then
            -- get target ped and coords
            local targetPed = GetPlayerPed(targetPlayerId)
            local targetCoords = GetEntityCoords(targetPed)
            local targetNetworkId = GetPlayerServerId(targetPlayerId)

            -- if we're standing close enough, do it
            if (Helpers.GetDistance(playerCoords, targetCoords) < 3.0) then
                -- make prompt
                if (not LocalPlayer.GiveMoneyPrompt) then
                    local groupId = PromptGetGroupIdForTargetEntity(aimTarget)
                    LocalPlayer.GiveMoneyPrompt = Helpers.RegisterPrompt('Give Money', Controls.MultiplayerInfo, groupId)
                end

                -- handle prompt for paying
                Helpers.Prompt(LocalPlayer.GiveMoneyPrompt, function()
                    -- open ui to get amount
                    Helpers.OpenUI('givemoney', nil)
                    
                    -- we need the target id for later
                    LocalPlayer.GiveMoneyTargetId = targetNetworkId
                end)
            end
        else
            -- its a local
        end
    else
        if (Doctor.TargetPrompt ~= nil) then
            Helpers.RemovePrompt(Doctor.TargetPrompt)
            Doctor.TargetPrompt = nil
        end            
    end
end

function LocalPlayer.GiveMoney(amount)
    -- return if no money target id
    if (LocalPlayer.GiveMoneyTargetId == nil) then
        return
    end

    -- notify server to give the money
    Helpers.Packet('player:GiveMoney', { TargetId = LocalPlayer.GiveMoneyTargetId, Amount = amount })
    LocalPlayer.GiveMoneyTargetId = nil

    -- close the ui
    Helpers.CloseUI(true)
end

function LocalPlayer.HandleRestrained(playerPed, playerCoords)
    DisableControlAction(0, Controls.MeleeAttack, true)
    DisableControlAction(0, Controls.QuickUseItem, true)
    DisableControlAction(0, Controls.Attack, true)
    DisableControlAction(0, Controls.Aim, true)
    DisableControlAction(0, Controls.SpecialAbility, true)
    DisableControlAction(0, Controls.Sprint, true)
    DisableControlAction(0, Controls.Jump, true)
    DisableControlAction(0, Controls.Enter, true)
    DisableControlAction(0, Controls.OpenJournal, true)
    DisableControlAction(0, Controls.PlayerMenu, true)
    DisableControlAction(0, Controls.Duck, true)
    DisableControlAction(0, Controls.Reload, true)
end

function LocalPlayer.ToggleCuffs()
    LocalPlayer.IsCuffed = not LocalPlayer.IsCuffed

    local playerPed = PlayerPedId()
    if (LocalPlayer.IsCuffed) then
        SetEnableHandcuffs(playerPed, true)
        DisablePlayerFiring(playerPed, true)
        SetCurrentPedWeapon(playerPed, WeaponHashes.Unarmed, true)
        SetPedCanPlayGestureAnims(playerPed, false)
        DisplayRadar(false)
    else
        ClearPedSecondaryTask(playerPed)
        SetEnableHandcuffs(playerPed, false)
        DisablePlayerFiring(playerPed, false)
        SetPedCanPlayGestureAnims(playerPed, true)
        DisplayRadar(true)
    end
end

function LocalPlayer.ToggleAnkleCuffs()
    LocalPlayer = not LocalPlayer.IsAnklesRestrained

    if (LocalPlayer.IsAnklesRestrained) then
        
    else

    end
end

function LocalPlayer.ToggleHogtied()
    LocalPlayer = not LocalPlayer.IsHogtied

    if (LocalPlayer.IsHogtied) then
        
    else

    end
end

function LocalPlayer.FeedHorse(healAmount, staminaAmount)
    -- todo:
    -- make it so you can feed your horse through right click selection and not just while riding it

    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 })
    SetTimeout(5000, function()
        local horse = GetMount(PlayerPedId())
        if (not DoesEntityExist(horse)) then
            return
        end

        -- get core values
        local health = Citizen.InvokeNative(0x36731AC041289BB1, horse, 0, Citizen.ResultAsInteger())
        local stamina = Citizen.InvokeNative(0x36731AC041289BB1, horse, 1, Citizen.ResultAsInteger())        

        -- set core values
        Citizen.InvokeNative(0xC6258F41D86676E0, horse, 0, math.clamp(health + healAmount, 0, 100))
        Citizen.InvokeNative(0xC6258F41D86676E0, horse, 1, math.clamp(stamina + staminaAmount, 0, 100))
    end)
end

function LocalPlayer.CreateCampfire()
    -- delete existing entity if we must
    if (DoesEntityExist(LocalPlayer.CampfireEntity)) then
        DeleteEntity(LocalPlayer.CampfireEntity)
    end

    -- create the campfire entity in front of player

end

function LocalPlayer.HandleCampfire()
    -- get player ped and player coords then validate things
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed) or not DoesEntityExist(LocalPlayer.CampfireEntity)) then
        return
    end

    -- get closest campfire to us, if it exists, do things
    local campfireEntity = GetClosestObjectOfType(playerCoords, 2.0, EntityHashes.Campfire, false, false, false)
    if (DoesEntityExist(campfireEntity)) then
        -- get campfire coords
        local campfireCoords = GetEntityCoords(campfireEntity)

        -- get distance to campfire 
        local distance = Helpers.GetDistance(playerCoords, campfireCoords)        
        if (distance < 2.5) then
            -- set a bool here so we don't spam the go away stuffs
            LocalPlayer.HasCampfirePrompt = true

            -- handle our prompt and open cooking UI on completion
            Helpers.Prompt(LocalPlayer.CampfirePrompt, function()
                Helpers.OpenUI('cooking', nil)
            end)
        else
            -- clear prompt if we need to - 
            -- note: this is always ticking, so no need to keep re-doing things.
            if (distance > 2.5 and LocalPlayer.HasCampfirePrompt) then
                -- no more!
                LocalPlayer.HasCampfirePrompt = false
    
                -- clear the prompt
                Helpers.CancelPrompt(LocalPlayer.CampfirePrompt)                    
            end
        end
    end
end

function LocalPlayer.PickupBucket()
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed)) then
        return
    end

    if (DoesEntityExist(LocalPlayer.HoldingEntity)) then
        DeleteEntity(LocalPlayer.HoldingEntity)
    end

    Citizen.CreateThread(function()
        local animDict = "script_rc@cldn@ig@rsc2_ig1_questionshopkeeper"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(10)
        end

        local boneIndex = GetEntityBoneIndexByName(playerPed, "SKEL_R_HAND")
        local entityHash = GetHashKey("P_CS_BUCKET01X") -- "P_CS_MININGPAN01X")

        while not HasModelLoaded(entityHash) do
            Citizen.Wait(0)
            RequestModel(entityHash)
        end

        LocalPlayer.HoldingEntity = CreateObject(entityHash, 0.0, 0.0, 0.0, true, false, false)
        SetEntityVisible(LocalPlayer.HoldingEntity, true)
        SetEntityAlpha(LocalPlayer.HoldingEntity, 255, false)
        Citizen.InvokeNative(0x283978A15512B2FE, LocalPlayer.HoldingEntity, true)
        SetModelAsNoLongerNeeded(entityHash)
        AttachEntityToEntity(LocalPlayer.HoldingEntity, playerPed, boneIndex, 0.2, 0.0, -0.2, -100.0, -50.0, 0.0, false, false, false, true, 2, true)

        --
        TaskPlayAnim(playerPed, animDict, "inspectfloor_player", 1.0, 8.0, -1, 1, 0, false, false, false)
    end)
end

function LocalPlayer.DropOffBucket()
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed)) then
        return
    end

    Citizen.CreateThread(function()
        local animDict = "script_rc@cldn@ig@rsc2_ig1_questionshopkeeper"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(10)
        end
        TaskPlayAnim(playerPed, animDict, "inspectfloor_player", 1.0, 8.0, -1, 1, 0, false, false, false)
    end)
end

function LocalPlayer.DeleteBucket()
    if (DoesEntityExist(LocalPlayer.HoldingEntity)) then
        DeleteEntity(LocalPlayer.HoldingEntity)
    end
    ClearPedTasks(PlayerPedId())
end

function LocalPlayer.StartScenario(scenarioHash)
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed)) then
        return
    end
    local heading = GetEntityHeading(playerPed)

    Citizen.InvokeNative(0x4D1F61FC34AF3CD1, playerPed, scenarioHash, playerCoords.x, playerCoords.y, playerCoords.z, heading, 0, false)
end

function LocalPlayer.UseBandage(healAmount)
    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks
    
    -- wait 5 seconds and then heal the player a little bit
    SetTimeout(5000, function()
        local playerPed = PlayerPedId()

        -- get core values
        local health = Citizen.InvokeNative(0x36731AC041289BB1, playerPed, 0, Citizen.ResultAsInteger())
        local stamina = Citizen.InvokeNative(0x36731AC041289BB1, playerPed, 1, Citizen.ResultAsInteger())        

        -- set core values
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 0, math.clamp(health + 50, 0, 100))
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 1, math.clamp(stamina + 5, 0, 100))
    end)        
end

function LocalPlayer.ToggleHandsUp()
    -- validate player ped
    local playerPed = PlayerPedId()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed)) then
        return
    end

    -- load the animation stuffs
    local anim = "mech_loco_m@generic@reaction@handsup@unarmed@normal"
    RequestAnimDict(anim)
    while (not HasAnimDictLoaded(anim)) do
        Citizen.Wait(10)
    end

    -- stop or start
    if (IsEntityPlayingAnim(playerPed, anim, "loop", 3)) then
        ClearPedSecondaryTask(playerPed)
    else
        TaskPlayAnim(playerPed, anim, "loop", 1.0, 8.0, 10000, 31, 0, true, 0, false, 0, false)
    end
end

function LocalPlayer.GetCurrentZone()
    -- return the current zone that our player is in
    return Citizen.InvokeNative(0x43AD8FC02B429D33, GetEntityCoords(PlayerPedId()), 1)    
end

function LocalPlayer.SpawnPigeon(isSender)
    if (isSender) then
        Citizen.CreateThread(function()
            local animDict = "script_rc@cldn@ig@rsc2_ig1_questionshopkeeper"
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Citizen.Wait(10)
            end
            TaskPlayAnim(PlayerPedId(), animDict, "inspectfloor_player", 1.0, 8.0, -1, 1, 0, false, false, false)
            
            SetTimeout(4000, function()
                ClearPedTasks(PlayerPedId())
                local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 2.0, 0.05)
                LocalPlayer.PigeonEntity = Helpers.SpawnNPC('A_C_Pigeon', coords.x, coords.y, coords.z)

                -- clean it up after a bit
                SetTimeout(15000, function()
                    if (DoesEntityExist(LocalPlayer.PigeonEntity)) then
                        DeleteEntity(LocalPlayer.PigeonEntity)
                    end
                end)
            end)
        end)
    else
        if (DoesEntityExist(LocalPlayer.PigeonEntity)) then
            DeleteEntity(LocalPlayer.PigeonEntity)
        end

        Citizen.CreateThread(function()    
            local playerCoords = GetEntityCoords(PlayerPedId())
            local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 5.0, 2.0)
            LocalPlayer.PigeonEntity = Helpers.SpawnNPC('A_C_Pigeon', coords.x, coords.y, coords.z)                        
            SetPedRelationshipGroupHash(LocalPlayer.PigeonEntity, 'PigeonCarrier')                        

            ClearPedTasks(LocalPlayer.PigeonEntity)
            ClearPedSecondaryTask(LocalPlayer.PigeonEntity)
            Citizen.InvokeNative(0x971D38760FBC02EF, LocalPlayer.PigeonEntity, true) --SetPedKeepTask            
            Citizen.InvokeNative(0x6A071245EB0D1882, LocalPlayer.PigeonEntity, PlayerPedId(), -1, 1.0, 2.0, 0, 0) -- TaskGoToEntity          

            -- clean it up after a bit
            SetTimeout(30000, function()    
                if (DoesEntityExist(LocalPlayer.PigeonEntity)) then
                    DeleteEntity(LocalPlayer.PigeonEntity)
                end
            end)
        end)        
    end
end