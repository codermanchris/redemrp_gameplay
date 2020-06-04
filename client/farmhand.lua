-- Start Gameplay Thread
if (GameplayConfig.UseFarmhand) then
    Helpers.StartGameplay(Farmhand)
end

-- Packet Handlers
Helpers.PacketHandler('farmhand:SetDuty', function(data)
    Farmhand.IsOnDuty = data.Value

    if (data.Value and Farmhand.IsCarryingWater) then
        LocalPlayer.DeleteBucket()
        Farmhand.IsCarryingWater = false
    end

    Farmhand.ClearPrompts()
end)

-- Nui Callbacks
RegisterNUICallback('farmhand:Start', function(data, cb)
    Helpers.Packet('farmhand:GoOnDuty', { LocationId = Farmhand.Closest.Index })
end)

-- Class Functions
function Farmhand.Initialize()
    Farmhand.SetupBlips()
    Farmhand.SetupPrompts()
end

function Farmhand.SetupBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(Farmhand.Locations) do
            if (v.Blip) then
                RemoveBlip(v.Blip)
            end
            v.Blip = Helpers.AddBlip(BlipSpriteType.MpSupplies, v.Coords, 'Farmhand')
        end        
    end)  
end

function Farmhand.SetupPrompts()
    Farmhand.OnDutyPrompt = Helpers.RegisterPrompt('Go On Duty', Controls.MultiplayerInfo, nil)
    Farmhand.OffDutyPrompt = Helpers.RegisterPrompt('Go Off Duty', Controls.MultiplayerInfo, nil)
    Farmhand.GetWaterPrompt = Helpers.RegisterPrompt('Get Water', Controls.MultiplayerInfo, nil)
    Farmhand.DropOffWaterPrompt = Helpers.RegisterPrompt('Drop Off Water', Controls.MultiplayerInfo, nil)
    Farmhand.GetSuppliesPrompt = Helpers.RegisterPrompt('Get Supplies', Controls.MultiplayerInfo, nil)
    Farmhand.DropOffSuppliesPrompt = Helpers.RegisterPrompt('Drop Off Supplies', Controls.MultiplayerInfo, nil)
    Farmhand.GetHayPrompt = Helpers.RegisterPrompt('Get Hay', Controls.MultiplayerInfo, nil)
    Farmhand.DropOffHayPrompt = Helpers.RegisterPrompt('Drop Off Hay', Controls.MultiplayerInfo, nil)
end

function Farmhand.ClearPrompts()
    Helpers.CancelPrompt(Farmhand.OnDutyPrompt)
    Helpers.CancelPrompt(Farmhand.OffDutyPrompt)
end

function Farmhand.Tick()
    -- validate things and stuffs
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed) or Farmhand.BlockInput) then
        return
    end

    -- get closest location
    Farmhand.Closest = Helpers.GetClosestLocation(playerCoords, Farmhand.Locations)
    Farmhand.CurrentLocation = Farmhand.Locations[Farmhand.Closest.Index]

    -- handle duty
    if (Farmhand.IsOnDuty) then
        Farmhand.HandleOnDuty(playerPed, playerCoords)
    else
        Farmhand.HandleOffDuty(playerPed, playerCoords)
    end
end

function Farmhand.HandleOnDuty(playerPed, playerCoords)
    -- if the player ran too far a way, fire them!
    if (Farmhand.Closest.Distance > 100.0) then
        Farmhand.ForceQuit()
        return
    end

    -- process prompts
    Farmhand.ProcessOnDutyMarker(playerCoords)
    Farmhand.ProcessGetWaterMarker(playerCoords)
    Farmhand.ProcessDropOffWaterMarker(playerCoords)
    Farmhand.ProcessGetSuppliesMarker(playerCoords)
    Farmhand.ProcessDropOffSuppliesMarker(playerCoords)
    Farmhand.ProcessGetHayMarker(playerCoords)
    Farmhand.ProcessDropOffHayMarker(playerCoords)    
end

function Farmhand.HandleOffDuty(playerPed, playerCoords)
    -- if we're far away from duty marker, return
    if (Farmhand.Closest.Distance > 25.0) then
        return
    end

    -- process prompts
    Farmhand.ProcessOffDutyMarker(playerCoords)
end

-- Process Prompts
function Farmhand.ProcessOffDutyMarker(playerCoords)
    if (Farmhand.Closest.Distance < 5.0) then
        -- draw marker
        Helpers.DrawMarker(Farmhand.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to marker, let's show the prompt
        if (Farmhand.Closest.Distance < 1.0) then
            Helpers.Prompt(Farmhand.OnDutyPrompt, function()
                Helpers.OpenUI('farmhand', nil)
            end)
        else
            -- cancel prompt if we ran too far away
            if (Farmhand.Closest.Distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.OnDutyPrompt)
            end
        end     
    end
end
function Farmhand.ProcessOnDutyMarker(playerCoords)
    if (Farmhand.Closest.Distance < 5.0) then
        -- draw marker
        Helpers.DrawMarker(Farmhand.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to marker, let's show the prompt
        if (Farmhand.Closest.Distance < 1.0) then
            Helpers.Prompt(Farmhand.OffDutyPrompt, function()
                Helpers.Packet('farmhand:GoOffDuty', { LocationId = Farmhand.Closest.Index })
            end)
        else
            -- cancel prompt if we ran too far away
            if (Farmhand.Closest.Distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.OffDutyPrompt)
            end
        end     
    end
end

function Farmhand.ProcessGetWaterMarker(playerCoords)
    local distance = Helpers.GetDistance(playerCoords, Farmhand.CurrentLocation.WaterCoords)
    if (distance < 5.0) then
        -- draw marker
        Helpers.DrawMarker(Farmhand.CurrentLocation.WaterCoords, Colors.Marker)

        -- if we're close enough to marker, let's show the prompt
        if (distance < 1.0) then
            Helpers.Prompt(Farmhand.GetWaterPrompt, function()
                Farmhand.GetWaterBucket()
            end)
        else
            -- cancel prompt if we ran too far away
            if (distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.GetWaterPrompt)
            end
        end     
    end
end
function Farmhand.ProcessDropOffWaterMarker(playerCoords)
    local closest = Helpers.GetClosestLocation(playerCoords, Farmhand.CurrentLocation.WaterDropOffs)
    local location = Farmhand.CurrentLocation.WaterDropOffs[closest.Index]

    if (closest.Distance < 5.0) then
        Helpers.DrawMarker(location.Coords, Colors.Marker)        
        Helpers.DrawText3d(location.Coords, string.format('WATER [%d/%d]', location.Value, location.MaxValue), 1, 1)

        -- if we're close enough to marker, let's show the prompt
        if (closest.Distance < 1.0) then
            Helpers.Prompt(Farmhand.DropOffWaterPrompt, function()
                Farmhand.DropOffWater(location)
            end)
        else
            -- cancel prompt if we ran too far away
            if (closest.Distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.DropOffWaterPrompt)
            end
        end         
    end
end

function Farmhand.ProcessGetSuppliesMarker(playerCoords)
    local distance = Helpers.GetDistance(playerCoords, Farmhand.CurrentLocation.SuppliesCoords)
    if (distance < 5.0) then
        -- draw marker
        Helpers.DrawMarker(Farmhand.CurrentLocation.SuppliesCoords, Colors.Marker)

        -- if we're close enough to marker, let's show the prompt
        if (distance < 1.0) then
            Helpers.Prompt(Farmhand.GetSuppliesPrompt, function()
                Farmhand.PickupSupplies()
            end)
        else
            -- cancel prompt if we ran too far away
            if (distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.GetSuppliesPrompt)
            end
        end     
    end
end
function Farmhand.ProcessDropOffSuppliesMarker(playerCoords)
    local closest = Helpers.GetClosestLocation(playerCoords, Farmhand.CurrentLocation.SupplyDropOffs)
    local location = Farmhand.CurrentLocation.SupplyDropOffs[closest.Index]

    if (closest.Distance < 5.0) then
        Helpers.DrawMarker(location.Coords, Colors.Marker)        
        Helpers.DrawText3d(location.Coords, string.format('SUPPLIES [%d/%d]', location.Value, location.MaxValue), 1, 1)

        -- if we're close enough to marker, let's show the prompt
        if (closest.Distance < 1.0) then
            Helpers.Prompt(Farmhand.DropOffSuppliesPrompt, function()
                Farmhand.DropOffSupplies(location)
            end)
        else
            -- cancel prompt if we ran too far away
            if (closest.Distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.DropOffSuppliesPrompt)
            end
        end         
    end
end

function Farmhand.ProcessGetHayMarker(playerCoords)
    local distance = Helpers.GetDistance(playerCoords, Farmhand.CurrentLocation.HayCoords)
    if (distance < 5.0) then
        -- draw marker
        Helpers.DrawMarker(Farmhand.CurrentLocation.HayCoords, Colors.Marker)

        -- if we're close enough to marker, let's show the prompt
        if (distance < 1.0) then
            Helpers.Prompt(Farmhand.GetHayPrompt, function()
                Farmhand.PickupHay()
            end)
        else
            -- cancel prompt if we ran too far away
            if (distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.GetHayPrompt)
            end
        end     
    end
end
function Farmhand.ProcessDropOffHayMarker(playerCoords)
    local closest = Helpers.GetClosestLocation(playerCoords, Farmhand.CurrentLocation.HayDropOffs)
    local location = Farmhand.CurrentLocation.HayDropOffs[closest.Index]

    if (closest.Distance < 5.0) then
        Helpers.DrawMarker(location.Coords, Colors.Marker)        
        Helpers.DrawText3d(location.Coords, string.format('HAY BALES [%d/%d]', location.Value, location.MaxValue), 1, 1)

        -- if we're close enough to marker, let's show the prompt
        if (closest.Distance < 1.0) then
            Helpers.Prompt(Farmhand.DropOffHayPrompt, function()
                Farmhand.DropOffHay(location)
            end)
        else
            -- cancel prompt if we ran too far away
            if (closest.Distance > 1.5) then
                Helpers.CancelPrompt(Farmhand.DropOffHayPrompt)
            end
        end         
    end
end
-- End Prompts

function Farmhand.GetWaterBucket()
    if (Farmhand.IsCarryingWater) then
        print('you already have water.')
        return
    end

    -- block input
    Farmhand.BlockInput = true
    
    -- create bucket entity and start animation stuffs
    LocalPlayer.PickupBucket()

    -- ui progress
    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks

    -- 5 second timer then set as carrying water
    SetTimeout(5000, function()
        Farmhand.BlockInput = false
        Farmhand.IsCarryingWater = true
        ClearPedTasks(PlayerPedId())
    end)
end

function Farmhand.DropOffWater(location)
    if (not Farmhand.IsCarryingWater) then
        print('you are not carrying water.')
        return
    end

    -- block input
    Farmhand.BlockInput = true

    -- start the drop off animation stuffs
    LocalPlayer.DropOffBucket()

    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks
    SetTimeout(5000, function()
        -- notify server for reward
        Helpers.Packet('farmhand:DropOff', { LocationId = Farmhand.Closest.Index, ItemId = 1 })

        -- reset bools
        Farmhand.BlockInput = false
        Farmhand.IsCarryingWater = false

        -- todo
        -- this should be controlled server side so it syncs to all players
        location.Value = math.clamp(location.Value + 1, 0, location.MaxValue)

        -- cleanup
        LocalPlayer.DeleteBucket()
    end) 
end

function Farmhand.PickupSupplies()
    if (Farmhand.IsCarryingSupplies) then
        print('you already have supplies.')
        return
    end

    -- block input
    Farmhand.BlockInput = true
    
    -- ui progress
    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks

    -- 5 second timer then set as carrying water
    SetTimeout(5000, function()
        Farmhand.BlockInput = false
        Farmhand.IsCarryingSupplies = true
        ClearPedTasks(PlayerPedId())
    end)
end

function Farmhand.DropOffSupplies(location)
    if (not Farmhand.IsCarryingSupplies) then
        print('you are not carrying hay.')
        return
    end

    -- block input
    Farmhand.BlockInput = true

    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks
    SetTimeout(5000, function()
        -- notify server for reward
        Helpers.Packet('farmhand:DropOff', { LocationId = Farmhand.Closest.Index, ItemId = 2 })

        -- reset bools
        Farmhand.BlockInput = false
        Farmhand.IsCarryingSupplies = false

        -- todo
        -- this should be controlled server side so it syncs to all players
        location.Value = math.clamp(location.Value + 1, 0, location.MaxValue)
    end)
end

function Farmhand.PickupHay()
    if (Farmhand.IsCarryingHay) then
        print('you already have hay.')
        return
    end

    -- block input
    Farmhand.BlockInput = true
    
    -- ui progress
    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks

    LocalPlayer.StartScenario(GetHashKey('PROP_HUMAN_ABIGAIL_PIANO'))

    -- 5 second timer then set as carrying hay
    SetTimeout(5000, function()
        Farmhand.BlockInput = false
        Farmhand.IsCarryingHay = true
        ClearPedTasks(PlayerPedId())
    end)
end

function Farmhand.DropOffHay(location)
    if (not Farmhand.IsCarryingHay) then
        print('you are not carrying hay.')
        return
    end

    -- block input
    Farmhand.BlockInput = true

    LocalPlayer.StartScenario(GetHashKey('WORLD_PLAYER_CHORES_BALE_PUT_DOWN_1'))

    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.2 }) -- takes 5 seconds so 20 per ticks
    SetTimeout(5000, function()
        -- notify server for reward
        Helpers.Packet('farmhand:DropOff', { LocationId = Farmhand.Closest.Index, ItemId = 3 })

        -- reset bools
        Farmhand.BlockInput = false
        Farmhand.IsCarryingHay = false

        -- todo
        -- this should be controlled server side so it syncs to all players
        location.Value = math.clamp(location.Value + 1, 0, location.MaxValue)
    end)
end