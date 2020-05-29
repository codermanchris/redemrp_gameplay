-- Start Gameplay Thread
Helpers.StartGameplay(GeneralStore)


-- Class Functions
function GeneralStore.Initialize()
    GeneralStore.SetupPrompts()
end

function GeneralStore.SetupPrompts()
    GeneralStore.CheesePrompt = Helpers.RegisterPrompt('Buy Cheese', Controls.MultiplayerInfo, nil)
end

function GeneralStore.Tick()
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (playerPed == nil) then
        return
    end

    local closest = Helpers.GetClosestLocation(playerCoords, GeneralStore.Locations)
    if (closest.Distance < 10.0) then
        local location = GeneralStore.Locations[closest.Index]
        GeneralStore.ProcessCheesePrompt(closest.Distance, location.Coords, playerCoords)
    end
end

function GeneralStore.ProcessCheesePrompt(distance, cheeseCoords, playerCoords)
    if (GeneralStore.BlockInput) then
        return
    end

    -- deal with promptness
    Helpers.DrawMarker(cheeseCoords, Colors.Marker)
    Helpers.DrawText3d(cheeseCoords, Delivery.WagonCountText, 1, 1)

    if (distance < 1.0) then
        GeneralStore.HasCheesePrompt = true
        Helpers.Prompt(GeneralStore.CheesePrompt, function()
            GeneralStore.BlockInput = true
            Helpers.MessageUI('core', 'initProgressBar', { Rate = 0.33 })
            SetTimeout(3000, function()
                GeneralStore.BlockInput = false
                Helpers.Packet('store:BuyCheese')
            end) 
        end)
    else
        if (distance > 1.5 and GeneralStore.HasCheesePrompt) then                
            GeneralStore.HasCheesePrompt = false
            Helpers.CancelPrompt(GeneralStore.CheesePrompt)
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