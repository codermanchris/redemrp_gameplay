-- Start Gameplay Thread
if (GameplayConfig.UseDoctor) then
    Helpers.StartGameplay(Doctor)
end

-- Packet Handlers

-- The server will tell us when we are on or off duty
Helpers.PacketHandler('doctor:SetDuty', function(data)
    Doctor.IsOnDuty = data.IsOnDuty
    Doctor.ClearPrompts()
end)

-- The server will release us after we're checked in, at which time we're healed
Helpers.PacketHandler('doctor:Release', function(data)
    Doctor.HealPlayer()
    Doctor.IsCheckedIn = false
end)

-- The server says you fail at checking in
Helpers.PacketHandler('doctor:ClearRequest', function(data)
    Doctor.IsCheckedIn = false
end)

-- The player has used a bandage and we need to heal
Helpers.PacketHandler('doctor:UseBandage', function (data) -- { HealAmount = 50 })
    Doctor.UseBandage(data.HealAmount)
end)

-- Class Functions

-- We need to initialize the blips and the prompts
function Doctor.Initialize()
    Doctor.SetupBlips()
    Doctor.SetupPrompts()
end

-- Setup the blips used on the maps
function Doctor.SetupBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(Doctor.Locations) do
            if (v.Blip) then
                RemoveBlip(v.Blip)
            end
            v.Blip = Helpers.AddBlip(BlipSpriteType.ShopDoctor, v.Coords, 'Doctor')
        end        
    end)    
end

-- Setup the prompts used for this job
function Doctor.SetupPrompts()
    Doctor.CheckInPrompt = Helpers.RegisterPrompt('Check In')        
    Doctor.BuyBandagePrompt = Helpers.RegisterPrompt('Buy Bandage (1$)')
    Doctor.OnDutyPrompt = Helpers.RegisterPrompt('Go On Duty')
    Doctor.OffDutyPrompt = Helpers.RegisterPrompt('Go Off Duty')
end

-- Clear all the prompts used for this job
function Doctor.ClearPrompts()
    if (Doctor.IsBuyPromptActive or Doctor.IsCheckInPromptActive or Doctor.IsDutyPromptActive or Doctor.IsOffDutyPromptActive) then
        Doctor.IsBuyPromptActive = false
        Doctor.IsCheckInPromptActive = false
        Doctor.IsDutyPromptActive = false
        Doctor.IsOffDutyPromptActive = false
        Helpers.SetPromptActive(Doctor.BuyBandagePrompt, false)
        Helpers.SetPromptActive(Doctor.CheckInPrompt, false)
        Helpers.SetPromptActive(Doctor.OnDutyPrompt, false)
        Helpers.SetPromptActive(Doctor.OffDutyPrompt, false)
    end
end

-- Tick tock
function Doctor.Tick()
    -- get player ped
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (not DoesEntityExist(playerPed) or IsPedFatallyInjured(playerPed)) then
        Doctor.ClearPrompts()
        return
    end

    -- get closest doctor location
    -- if it's too far away, just return
    Doctor.Closest = Helpers.GetClosestLocation(playerCoords, Doctor.Locations)
    if (Doctor.Closest.Distance > 25.0) then
        Doctor.ClearPrompts()

        -- if the player was on duty, they will go off duty
        if (Doctor.IsOnDuty) then
            Helpers.Packet('doctor:GoOffDuty')
            Doctor.IsOnDuty = false
        end

        return
    end

    -- get our location 
    Doctor.CurrentLocation = Doctor.Locations[Doctor.Closest.Index]

    -- are we on duty or off?
    if (not Doctor.IsOnDuty) then
        Doctor.HandleOffDuty(playerPed, playerCoords)
    else
        Doctor.HandleOnDuty(playerPed, playerCoords)
    end
end

-- If the player is off duty, let's handle it here
function Doctor.HandleOffDuty(playerPed, playerCoords)
    -- handle duty marker
    if (Doctor.Closest.Distance < 5.0) then
        -- draw duty marker
        Helpers.DrawMarker(Doctor.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to buy marker, let's show the prompt
        if (Doctor.Closest.Distance < 1.0) then
            Helpers.Prompt(Doctor.OnDutyPrompt, function()
                Helpers.Packet('doctor:GoOnDuty', { LocationId = Doctor.Closest.Index })
                Doctor.IsOnDuty = true                
            end)
        else
            -- cancel prompt if we ran too far away
            if (Doctor.Closest.Distance > 1.5) then
                Helpers.CancelPrompt(Doctor.OnDutyPrompt)
            end
        end 
    end

    -- handle buy bandage marker
    local distanceToBuy = Helpers.GetDistance(playerCoords, Doctor.CurrentLocation.BuyCoords)
    if (distanceToBuy < 5.0) then
        -- draw buy marker
        Helpers.DrawMarker(Doctor.CurrentLocation.BuyCoords, Colors.Marker)

        -- if we're close enough to buy marker, let's show the prompt
        if (distanceToBuy < 1.0) then
            Helpers.Prompt(Doctor.BuyBandagePrompt, function()
                Helpers.Packet('doctor:BuyBandage')
            end)
        else
            -- cancel prompt if we ran too far away
            if (distanceToBuy > 1.5) then
                Helpers.CancelPrompt(Doctor.BuyBandagePrompt)
            end
        end     
    end

    -- handle check in marker
    local distanceToCheckIn = Helpers.GetDistance(playerCoords, Doctor.CurrentLocation.CheckInCoords)
    if (distanceToCheckIn < 5.0) then
        -- draw the place where we need to stand in order to check in
        Helpers.DrawMarker(Doctor.CurrentLocation.CheckInCoords, Colors.Marker)

        -- if we're close enough to the prompt let's do stuff
        if (distanceToCheckIn < 1.0) then
            -- if we're not currently a patient, let's try to be a patient
            if (not Doctor.IsCheckedIn) then
                -- complete the prompt and check in
                Helpers.Prompt(Doctor.CheckInPrompt, function()
                    -- notify server we want to check in
                    Helpers.Packet('doctor:CheckIn', { LocationId = Doctor.Closest.Index })
                    Doctor.IsCheckedIn = true
                end)
            else
                -- draw text about being helped to inform the uninformed player
                Helpers.DrawText3d(Doctor.CurrentLocation.CheckInCoords, 'YOU ARE BEING HELPED', 1, 1)
            end
        else
            -- cancel prompt if we ran too far away
            if (distanceToCheckIn > 1.5) then
                Helpers.CancelPrompt(Doctor.CheckInPrompt)
            end
        end
    end
end

function Doctor.HandleOnDuty(playerPed, playerCoords)
    --[[ if we're close enough to duty marker..
    if (Doctor.Closest.Distance < 5.0) then
        -- draw duty marker
        Helpers.DrawMarker(Doctor.CurrentLocation.Coords, Colors.Marker)

        -- if we're close enough to buy marker, let's show the prompt
        if (Doctor.Closest.Distance < 1.0) then
            Helpers.Prompt(Doctor.OffDutyPrompt, function()
                Helpers.Packet('doctor:GoOffDuty', { LocationId = Doctor.Closest.Index })
            end)
        else
            -- cancel prompt if we ran too far away
            if (Doctor.Closest.Distance > 1.5) then
                Helpers.CancelPrompt(Doctor.OffDutyPrompt)
            end
        end
    end]]
end

function Doctor.HealPlayer()
    local playerPed = PlayerPedId()

    -- note:
    -- this will not bring a player back from death
    -- the doctor must be on duty to perform that action, for now.

    -- set health to max
    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 0, 100)  
    -- set stamina to max
    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 1, 100)      
end

function Doctor.UseBandage(healAmount)
    -- todo
    -- add some progress bar on the ui 
    
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