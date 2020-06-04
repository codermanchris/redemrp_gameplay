-- Start Gameplay Thread
if (GameplayConfig.UseVehicleRental) then
    Helpers.StartGameplay(VehicleRental)
end

-- Packet Handlers
Helpers.PacketHandler('vehiclerental:Spawn', function(data)
    VehicleRental.SpawnWagon(data.VehicleId)
end)

-- Nui Callbacks
RegisterNUICallback('vehiclerental:Select', function(data, cb)
    VehicleRental.RentVehicle(data.vehicleId)
end)

-- Class Functions
function VehicleRental.Initialize()
    VehicleRental.SetupBlips()
    VehicleRental.SetupPrompts()
end

function VehicleRental.SetupBlips()
    Citizen.CreateThread(function()
        for k, v in pairs(VehicleRental.Locations) do
            if (v.Blip) then
                RemoveBlip(v.Blip)
            end
            v.Blip = Helpers.AddBlip(BlipSpriteType.AmbientCoach, v.Coords, 'Vehicle Rental')
        end        
    end)
end

function VehicleRental.SetupPrompts()
    VehicleRental.RentPrompt = Helpers.RegisterPrompt('Get Rental', Controls.MultiplayerInfo, nil)
    VehicleRental.DropOffVehiclePrompt = Helpers.RegisterPrompt('Return Vehicle', Controls.MultiplayerInfo, nil)
    VehicleRental.LoadPrompt = Helpers.RegisterPrompt('Load Animal', Controls.MultiplayerInfo, nil)
    VehicleRental.UnloadPrompt = Helpers.RegisterPrompt('Unload Animal', Controls.MultiplayerInfo, nil)
end

function VehicleRental.Tick()
    -- validate ped and get coords
    local playerPed, playerCoords = Helpers.GetLocalPed()
    if (LocalPlayer.IsDead or not DoesEntityExist(playerPed)) then
        return
    end

    -- get closest location
    VehicleRental.Closest = Helpers.GetClosestLocation(playerCoords, VehicleRental.Locations)
    VehicleRental.CurrentLocation = VehicleRental.Locations[VehicleRental.Closest.Index]

    -- handle a vehicle or not
    if (VehicleRental.HasRental) then
        VehicleRental.HandleVehicle(playerPed, playerCoords)
    end

    VehicleRental.HandleCustomer(playerPed, playerCoords)
end

function VehicleRental.HandleVehicle(playerPed, playerCoords)
    -- todo other stuff before this
    if (not DoesEntityExist(VehicleRental.WagonEntity)) then
        VehicleRental.HasRental = false
        return
    end

    -- test: disable collision from animals to wagon
    for k, v in pairs(VehicleRental.AttachedPeds) do
        SetEntityNoCollisionEntity(v.Ped, VehicleRental.WagonEntity, true)
    end

    -- load/unload animal into cart
    local vehicleCoords = GetOffsetFromEntityInWorldCoords(VehicleRental.WagonEntity, VehicleRental.VehicleData.ActionOffset.x, VehicleRental.VehicleData.ActionOffset.y, VehicleRental.VehicleData.ActionOffset.z)
    local distanceToVehicle = Helpers.GetDistance(playerCoords, vehicleCoords)
    if (distanceToVehicle < 5.0) then
        local holdingPed = Citizen.InvokeNative(0xD806CD2A4F2C2996, playerPed)
        local quality = Citizen.InvokeNative(0x31FEF6A20F00B963, holdingPed)
        local model = GetEntityModel(holdingPed)
        local type = GetPedType(holdingPed)

        if (DoesEntityExist(holdingPed) and type == 28) then
            Helpers.DrawMarker(vehicleCoords, Colors.Marker)

            if (distanceToVehicle < 1.0) then
                Helpers.DrawText3d(vehicleCoords, string.format('Load Animal [%d/%d]', VehicleRental.WagonSupplyCount, VehicleRental.WagonSupplyMaxCount), 1, 1)

                Helpers.Prompt(VehicleRental.LoadPrompt, function()
                    -- attach the animal to the cart
                    SetEntityCollision(holdingPed, false, false)
                    SetEntityVisible(holdingPed, false)
                    SetEntityAlpha(holdingPed, 0, false)
                    
                    AttachEntityToEntity(holdingPed, VehicleRental.WagonEntity, 0, 0.0, 0.0, 0.2, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                    

                    -- insert for later usage
                    table.insert(VehicleRental.AttachedPeds, { Ped = holdingPed, Quality = quality, Model = model, Type = type })
                    VehicleRental.WagonSupplyCount = VehicleRental.WagonSupplyCount + 1
                end)
            else
                if (distanceToVehicle > 1.5) then
                    Helpers.CancelPrompt(VehicleRental.LoadPrompt)
                end
            end
        else
            if (VehicleRental.WagonSupplyCount > 0 and not IsPedInAnyVehicle(playerPed, false)) then
                Helpers.DrawMarker(vehicleCoords, Colors.Marker)

                if (distanceToVehicle < 1.0) then
                    
                    Helpers.DrawText3d(vehicleCoords, string.format('Unload Animal [%d/%d]', VehicleRental.WagonSupplyCount, VehicleRental.WagonSupplyMaxCount), 1, 1)

                    Helpers.Prompt(VehicleRental.UnloadPrompt, function()
                        -- get ped from attached table
                        local ped = VehicleRental.AttachedPeds[1].Ped

                        -- detach and place behind vehicle
                        -- todo: figure out how to directly put it in carry on
                        DetachEntity(ped, true, false)
                        SetEntityVisible(ped, true)
                        SetEntityAlpha(ped, 255, false)
                        SetEntityCoords(ped, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5)
                        SetEntityCollision(ped, true, true)
                        
                        -- remove from table
                        table.remove(VehicleRental.AttachedPeds, 1)

                        VehicleRental.WagonSupplyCount = VehicleRental.WagonSupplyCount - 1
                    end)
                else
                    if (distanceToVehicle > 1.5) then
                        Helpers.CancelPrompt(VehicleRental.UnloadPrompt)
                    end
                end
            end
        end
    end

    -- if we're near the rental place
    if (VehicleRental.Closest.Distance > 25.0) then
        return
    end

    if (IsPedSittingInVehicle(playerPed, VehicleRental.WagonEntity)) then
        local distanceToDropOff = Helpers.GetDistance(playerCoords, VehicleRental.CurrentLocation.VehicleCoords)
        if (distanceToDropOff < 10.0) then
            Helpers.DrawMarker(VehicleRental.CurrentLocation.VehicleCoords, Colors.Marker)

            if (distanceToDropOff < 1.0) then
                Helpers.Prompt(VehicleRental.DropOffVehiclePrompt, function()
                    Helpers.Packet('vehiclerental:Return', nil)
                    VehicleRental.DespawnWagon()
                end)
            else
                if (distanceToDropOff > 1.5) then
                    Helpers.CancelPrompt(VehicleRental.DropOffVehiclePrompt)
                end
            end
        end
    end
end

function VehicleRental.HandleCustomer(playerPed, playerCoords)
    if (VehicleRental.Closest.Distance > 25.0) then
        return
    end

    if (VehicleRental.Closest.Distance < 5.0) then
        Helpers.DrawMarker(VehicleRental.CurrentLocation.Coords, Colors.Marker)

        if (VehicleRental.Closest.Distance < 1.0) then
            Helpers.Prompt(VehicleRental.RentPrompt, function()
                Helpers.OpenUI('vehiclerental', nil)
            end)
        else
            if (VehicleRental.Closest.Distance > 1.5) then
                Helpers.CancelPrompt(VehicleRental.RentPrompt)
            end
        end
    end
end

function VehicleRental.SpawnWagon(vehicleId)
    local playerPed = PlayerPedId()
    if (not DoesEntityExist(playerPed)) then
        return
    end

    local vehicle = VehicleRental.CurrentLocation.Vehicles[vehicleId]
    local spawnCoords = VehicleRental.CurrentLocation.VehicleCoords

    -- load model
    RequestModel(vehicle.Hash)
    while not HasModelLoaded(vehicle.Hash) do
        Citizen.Wait(0)
    end

    -- clean up maybe
    if (VehicleRental.WagonEntity) then
        DeleteEntity(VehicleRental.WagonEntity)
    end

    -- create wagon
    VehicleRental.WagonEntity = CreateVehicle(vehicle.Hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetVehicleOnGroundProperly(VehicleRental.WagonEntity)
    --SetPedIntoVehicle(playerPed, VehicleRental.WagonEntity, -1)
    SetModelAsNoLongerNeeded(vehicle.Hash)

    -- set datas    
    VehicleRental.WagonSupplyCount = 0
    VehicleRental.WagonSupplyMaxCount = vehicle.MaxCapacity
    VehicleRental.WagonCountText = string.format('0/%d', vehicle.MaxCapacity)
    VehicleRental.VehicleData = vehicle

    VehicleRental.HasRental = true
end

function VehicleRental.DespawnWagon()
    if (DoesEntityExist(VehicleRental.WagonEntity)) then
        DeleteEntity(VehicleRental.WagonEntity)
    end

    VehicleRental.HasRental = false
end

function VehicleRental.RentVehicle(vehicleId)
    Helpers.Packet('vehiclerental:Rent', { LocationId = VehicleRental.Closest.Index, VehicleId = vehicleId })
    Helpers.CloseUI(true)
end