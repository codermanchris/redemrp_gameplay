Helpers.StartGameplay(LocalPlayer)

function LocalPlayer.Initialize()
    
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
    if (LocalPlayer.IsRestrained) then
        LocalPlayer.HandleRestrained(playerPed, playerCoords)
    end

    -- handle prompts
    LocalPlayer.HandlePrompts()
end


function LocalPlayer.HandlePrompts()
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
            if (not LocalPlayer.GiveMoneyPrompt) then
                local groupId = PromptGetGroupIdForTargetEntity(aimTarget)
                LocalPlayer.GiveMoneyPrompt = Helpers.RegisterPrompt('Give Money', Controls.MultiplayerInfo, groupId)
            end

            -- handle prompt for paying
            Helpers.Prompt(LocalPlayer.GiveMoneyPrompt, function()
                -- open ui to get amount
                Helpers.OpenUI('givemoney', nil)
                LocalPlayer.GiveMoneyTargetId = targetPlayerId
            end)
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
    DisableControlAction(0, 0xB2F377E8, true) -- attack
    DisableControlAction(0, 0xC1989F95, true) -- attack 2
    DisableControlAction(0, 0x07CE1E61, true) -- melee attack
    DisableControlAction(0, 0xF84FA74F, true) -- mouse 2
    DisableControlAction(0, 0xCEE12B50, true) -- mouse 3
    DisableControlAction(0, 0x8FFC75D6, true) -- shift
    DisableControlAction(0, 0xD9D0E1C0, true) -- space
    DisableControlAction(0, 0xCEFD9220, true) -- e
    DisableControlAction(0, 0xF3830D8E, true) -- j
    DisableControlAction(0, 0x80F28E95, true) -- l
    DisableControlAction(0, 0xDB096B85, true) -- ctrl
    DisableControlAction(0, 0xE30CD707, true) -- r
end

function LocalPlayer.Cuff()
    LocalPlayer = not LocalPlayer.IsCuffed

    if (LocalPlayer.IsCuffed) then

    else

    end
end
