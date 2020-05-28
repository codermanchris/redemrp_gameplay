Helpers.StartGameplay(LocalPlayer)

function LocalPlayer.Initialize()
    LocalPlayer.NextBonusAt = GetGameTimer()
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
    end

    -- handle prompts
    LocalPlayer.HandlePrompts(playerPed, playerCoords)

    -- handle bonus xp
    LocalPlayer.HandleBonusXP()
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

            -- if we're standing close enough, do it
            if (Helpers.GetDistance(playerCoords, targetCoords) < 5.0) then
                -- make prompt
                if (not LocalPlayer.GiveMoneyPrompt) then
                    local groupId = PromptGetGroupIdForTargetEntity(aimTarget)
                    LocalPlayer.GiveMoneyPrompt = Helpers.RegisterPrompt('Give Money', Controls.MultiplayerInfo, groupId)
                end

                -- handle prompt for paying
                Helpers.Prompt(LocalPlayer.GiveMoneyPrompt, function()
                    -- open ui to get amount
                    --Helpers.OpenUI('givemoney', nil)
                    
                    LocalPlayer.GiveMoneyTargetId = targetPlayerId

                    -- for testing
                    LocalPlayer.GiveMoney(1)
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
    Helpers.CloseUI()
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
    LocalPlayer = not LocalPlayer.IsCuffed

    if (LocalPlayer.IsCuffed) then

    else

    end
end

function LocalPlayer.ToggleAnkleRestraints()
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