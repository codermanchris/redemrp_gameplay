-- Start Gameplay Thread
if (GameplayConfig.UseDelivery) then
    Helpers.StartGameplay(Delivery)
end

-- Packet Handlers
Helpers.PacketHandler('delivery:SetDuty', function(data)
    Delivery.IsOnDuty = data.Value
    if (not Delivery.IsOnDuty) then
        Delivery.DespawnWagon()
        Delivery.ClearDelivery()
    else
        Delivery.SpawnWagon()
        Delivery.StartDelivery(data.DeliveryIndex)
    end
    Delivery.ClearPrompts()
end)

Helpers.PacketHandler('delivery:Start', function(data)
    Delivery.StartDelivery(data.DeliveryIndex)
end)

-- Class Functions
function Delivery.Initialize()
    Delivery.SetupPrompts()
    Delivery.SetupBlips()
end

function Delivery.SetupPrompts()
    Delivery.OnDutyPrompt = Helpers.RegisterPrompt('Go On Duty', Controls.MultiplayerInfo, nil)
    Delivery.OffDutyPrompt = Helpers.RegisterPrompt('Go Off Duty', Controls.MultiplayerInfo, nil)
    Delivery.DropOffPrompt = Helpers.RegisterPrompt('Drop Off Supplies', Controls.MultiplayerInfo, nil)
    Delivery.LoadPrompt = Helpers.RegisterPrompt('Load', Controls.MultiplayerInfo, nil)
    Delivery.UnloadPrompt = Helpers.RegisterPrompt('Unload', Controls.MultiplayerInfo, nil)
    Delivery.PickupPrompt = Helpers.RegisterPrompt('Pickup Supplies', Controls.MultiplayerInfo, nil)
end

function Delivery.SetupBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(Delivery.Locations) do
            if (v.Blip) then
                RemoveBlip(v.Blip)
            end
            v.Blip = Helpers.AddBlip(BlipSpriteType.AmbientCoach, v.Coords, 'Delivery')
        end        
    end)  
end

function Delivery.Tick()
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed) or LocalPlayer.IsDead) then
        return
    end
    
    Delivery.Closest = Helpers.GetClosestLocation(playerCoords, Delivery.Locations)
    Delivery.CurrentLocation = Delivery.Locations[Delivery.Closest.Index]

    if (Delivery.IsOnDuty) then
        Delivery.HandleOnDuty(playerPed, playerCoords)
    else
        Delivery.HandleOffDuty(playerPed, playerCoords)
    end
end

function Delivery.HandleOnDuty(playerPed, playerCoords)
    if (Delivery.Closest.Distance < 25.0) then
        Delivery.ProcessOffDutyMarker(playerCoords)
        Delivery.ProcessPickupMarker(playerCoords)
    end

    Delivery.ProcessDropOffMarker(playerCoords)

    -- if we have a wagon - let's do some stuffs
    if (DoesEntityExist(Delivery.WagonEntity)) then
        local wagonCoords = GetEntityCoords(Delivery.WagonEntity)
        local distanceToWagon = Helpers.GetDistance(playerCoords, wagonCoords)

        -- if we move too far away from our wagon, assume we should go off duty
        if (distanceToWagon > 50.0) then
            Helpers.Packet('delivery:GoOffDuty', { LocationId = Delivery.CurrentLocation.Id })
            Delivery.IsOnDuty = false
        end

        -- if we're not in the wagon, show the load supplies stuffs
        if (not IsPedInVehicle(playerPed, Delivery.WagonEntity, false)) then
            local loadCoords = GetOffsetFromEntityInWorldCoords(Delivery.WagonEntity, 0.0, -2.0, 0.25)
            Delivery.ProcessLoadPrompt(loadCoords, playerCoords)
            Delivery.ProcessUnloadPrompt(loadCoords, playerCoords)            
        end
    end
end

function Delivery.HandleOffDuty(playerPed, playerCoords)
    if (Delivery.Closest.Distance > 25.0) then
        return
    end

    Delivery.ProcessOnDutyMarker(playerCoords)
end

-- prompt processors
function Delivery.ClearPrompts()
    Helpers.CancelPrompt(Delivery.OnDutyPrompt)
    Helpers.CancelPrompt(Delivery.OffDutyPrompt)
    Helpers.CancelPrompt(Delivery.DropOffPrompt)
    Helpers.CancelPrompt(Delivery.LoadPrompt)
    Helpers.CancelPrompt(Delivery.UnloadPrompt)
    Helpers.CancelPrompt(Delivery.PickupPrompt)
end

function Delivery.ProcessOnDutyMarker(playerCoords)
    if (Delivery.BlockInput) then
        return
    end

    local distance = Helpers.GetDistance(playerCoords, Delivery.CurrentLocation.Coords)
    if (distance < 5.0) then
        Helpers.DrawMarker(Delivery.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distance < 1.0) then
            Delivery.HasDutyPrompt = true
            -- process prompt and request duty from server
            Helpers.Prompt(Delivery.OnDutyPrompt, function()
                Helpers.Packet('delivery:GoOnDuty', { LocationId = Delivery.CurrentLocation.Id })
            end)
        else
            -- clear duty prompt
            if (distance > 1.5 and Delivery.HasDutyPrompt) then                
                Delivery.HasDutyPrompt = false
                Helpers.CancelPrompt(Delivery.OnDutyPrompt)
            end
        end            
    end
end

function Delivery.ProcessOffDutyMarker(playerCoords)
    if (Delivery.BlockInput) then
        return
    end

    local distance = Helpers.GetDistance(playerCoords, Delivery.CurrentLocation.Coords)
    if (distance < 5.0) then
        -- draw marker for armory
        Helpers.DrawMarker(Delivery.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to handle some promptness, do it
        if (distance < 1.0) then
            Delivery.HasOffDutyPrompt = true

            -- process prompt and request armory from server
            Helpers.Prompt(Delivery.OffDutyPrompt, function()
                Helpers.Packet('delivery:GoOffDuty', { LocationId = Delivery.CurrentLocation.Id })
            end)
        else
            -- clear armory prompt
            if (distance > 1.5 and Delivery.HasOffDutyPrompt) then
                Delivery.HasOffDutyPrompt = false
                Helpers.CancelPrompt(Delivery.OffDutyPrompt)                    
            end
        end
    end
end

function Delivery.ProcessPickupMarker(playerCoords)
    if (Delivery.BlockInput) then
        return
    end

    local distance = Helpers.GetDistance(playerCoords, Delivery.CurrentLocation.PickupCoords)
    if (distance < 10.0) then
        Helpers.DrawMarker(Delivery.CurrentLocation.PickupCoords, Colors.Marker)

        if (distance < 1.0) then
            Delivery.HasPickupPrompt = true
            Helpers.Prompt(Delivery.PickupPrompt, function()
                if (not Delivery.IsCarryingWagonSupplies) then
                    Delivery.BlockInput = true

                    -- show progress bar
                    Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.33 })
                    SetTimeout(3000, function()
                        Delivery.BlockInput = false
                        Delivery.IsCarryingWagonSupplies = true

                        TriggerEvent('chatMessage', '', {0,0,0}, '^2You picked up supplies.')
                    end)                    
                end
            end)
        else
            if (distance > 1.5 and Delivery.HasPickupPrompt) then                
                Delivery.HasPickupPrompt = false
                Helpers.CancelPrompt(Delivery.PickupPrompt)
            end
        end            
    end
end

function Delivery.ProcessDropOffMarker(playerCoords)
    if (Delivery.BlockInput or not Delivery.IsCarryingWagonSupplies) then
        return
    end

    local distance = Helpers.GetDistance(playerCoords, Delivery.CurrentDropOff.Coords)
    if (distance < 10.0) then
        Helpers.DrawMarker(Delivery.CurrentDropOff.Coords, Colors.Marker)

        if (distance < 1.0) then
            Delivery.HasDropoffPrompt = true
            Helpers.Prompt(Delivery.DropOffPrompt, function()                
                Delivery.BlockInput = true

                Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.33 })

                SetTimeout(3000, function()
                    Delivery.BlockInput = false
                    Delivery.IsCarryingWagonSupplies = false
                    Delivery.HasDropoffPrompt = false
                    Helpers.CancelPrompt(Delivery.DropOffPrompt)    
                    Delivery.CompleteDelivery()
                end) 
            end)
        else
            if (distance > 1.5 and Delivery.HasDropoffPrompt) then                
                Delivery.HasDropoffPrompt = false
                Helpers.CancelPrompt(Delivery.DropOffPrompt)
            end
        end            
    end    
end

function Delivery.ProcessLoadPrompt(loadCoords, playerCoords)
    -- return if the player is not carrying anything
    if (Delivery.BlockInput or not Delivery.IsCarryingWagonSupplies) then
        return
    end

    -- deal with promptness
    local distance = Helpers.GetDistance(playerCoords, loadCoords)
    if (distance < 5.0) then
        Helpers.DrawMarker(loadCoords, Colors.Marker)
        Helpers.DrawText3d(loadCoords, Delivery.WagonCountText, 1, 1)

        if (distance < 1.0) then
            Delivery.HasLoadPrompt = true
            Helpers.Prompt(Delivery.LoadPrompt, function()
                Delivery.BlockInput = true
                Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.33 })
                SetTimeout(3000, function()
                    Delivery.BlockInput = false
                    if (Delivery.AddWagonSupplies(1)) then
                        Delivery.IsCarryingWagonSupplies = false
                    end    
                end) 
            end)
        else
            if (distance > 1.5 and Delivery.HasLoadPrompt) then                
                Delivery.HasLoadPrompt = false
                Helpers.CancelPrompt(Delivery.LoadPrompt)
            end
        end            
    end    
end

function Delivery.ProcessUnloadPrompt(loadCoords, playerCoords)
    -- return if the player is carrying something
    if (Delivery.BlockInput or Delivery.IsCarryingWagonSupplies) then
        return
    end

    -- deal with promptness
    local distance = Helpers.GetDistance(playerCoords, loadCoords)
    if (distance < 5.0) then
        Helpers.DrawMarker(loadCoords, Colors.Marker)
        Helpers.DrawText3d(loadCoords, Delivery.WagonCountText, 1, 1)

        if (distance < 1.0) then
            Delivery.HasUnloadPrompt = true
            Helpers.Prompt(Delivery.UnloadPrompt, function()
                Delivery.BlockInput = true
                Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.33 })
                SetTimeout(3000, function()
                    Delivery.BlockInput = false
                    if (Delivery.RemoveWagonSupplies(1)) then
                        Delivery.IsCarryingWagonSupplies = true
                    end
                end)
            end)
        else
            if (distance > 1.5 and Delivery.HasUnloadPrompt) then                
                Delivery.HasUnloadPrompt = false
                Helpers.CancelPrompt(Delivery.UnloadPrompt)
            end
        end            
    end    
end
-- end prompts

function Delivery.SpawnWagon()
    local playerPed = PlayerPedId()
    if (not DoesEntityExist(playerPed)) then
        return
    end
    
    local spawnCoords = Delivery.CurrentLocation.VehicleCoords
    local wagonHash = GetHashKey("CART01")

    -- load model
    RequestModel(wagonHash)
    while not HasModelLoaded(wagonHash) do
        Citizen.Wait(0)
    end

    -- clean up maybe
    if (Delivery.WagonEntity) then
        DeleteEntity(Delivery.WagonEntity)
    end

    -- create wagon
    Delivery.WagonEntity = CreateVehicle(wagonHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetVehicleOnGroundProperly(Delivery.WagonEntity)
    --SetPedIntoVehicle(playerPed, Delivery.WagonEntity, -1)
    SetModelAsNoLongerNeeded(wagonHash)

    -- set datas
    Delivery.WagonCountText = '0/3'
    Delivery.WagonSupplyCount = 0
    Delivery.WagonSupplyMaxCount = 3
end

function Delivery.DespawnWagon()
    if (DoesEntityExist(Delivery.WagonEntity)) then
        DeleteEntity(Delivery.WagonEntity)
    end
end

function Delivery.AddWagonSupplies(amount)
    if (Delivery.WagonSupplyCount >= Delivery.WagonSupplyMaxCount) then
        return false
    end

    Delivery.WagonSupplyCount = Delivery.WagonSupplyCount + amount
    Delivery.WagonCountText = string.format('%d/%d', Delivery.WagonSupplyCount, Delivery.WagonSupplyMaxCount)

    return true
end

function Delivery.RemoveWagonSupplies(amount)
    if (Delivery.WagonSupplyCount <= 0) then
        return false
    end
    
    Delivery.WagonSupplyCount = Delivery.WagonSupplyCount - amount
    Delivery.WagonCountText = string.format('%d/%d', Delivery.WagonSupplyCount, Delivery.WagonSupplyMaxCount)
    return true
end

function Delivery.StartDelivery(deliveryIndex)
    Delivery.CurrentDropOff = Delivery.CurrentLocation.DropOffCoords[deliveryIndex]
    if (Delivery.CurrentDropOff == nil) then
        return
    end

    if (Delivery.DeliveryBlip) then
        RemoveBlip(Delivery.DeliveryBlip)
    end
    Delivery.DeliveryBlip = Helpers.AddBlip(BlipSpriteType.AmbientCrate, Delivery.CurrentDropOff.Coords, 'Delivery Drop Off')
end

function Delivery.ClearDelivery()
    if (Delivery.CurrentDropOff ~= nil) then
        Delivery.CurrentDropOff = nil
        if (Delivery.DeliveryBlip) then
            RemoveBlip(Delivery.DeliveryBlip)
        end
    end
end

function Delivery.CompleteDelivery()
    if (Delivery.DeliveryBlip) then
        RemoveBlip(Delivery.DeliveryBlip)
    end
    Delivery.CurrentDropOff = nil

    -- this might lead to getting locations from other delivery yards :)
    Helpers.Packet('delivery:Complete', { LocationId = Delivery.CurrentLocation.Id })
end
