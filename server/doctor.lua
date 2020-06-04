-- Packet Handlers
Helpers.PacketHandler('doctor:GoOnDuty', function(playerId, data)
    Doctor.GoOnDuty(playerId, data.LocationId)
end)

Helpers.PacketHandler('doctor:GoOffDuty', function(playerId, data)
    Doctor.GoOffDuty(playerId)
end)

Helpers.PacketHandler('doctor:BuyBandage', function(playerId, data)
    Doctor.BuyBandage(playerId)
end)

Helpers.PacketHandler('doctor:CheckIn', function(playerId, data)
    Doctor.CheckIn(playerId, data.LocationId)
end)

Helpers.PacketHandler('doctor:TreatPlayer', function(playerId, data)
    Doctor.TreatPlayer(playerId, data.PatientId, data.Revive, data.Coords)
end)

-- Class Functions
function Doctor.GoOnDuty(playerId, locationId)
    -- get the requested location
    local location = Doctor.Locations[locationId]
    if (location == nil) then
        return
    end

    -- make sure this place doesn't already have a doctor on duty
    if (location.DoctorId ~= nil) then
        Helpers.Respond(playerId, '^1This location already has a Doctor.')
        return
    end

    -- get the character and do stuffs
    Helpers.GetCharacter(playerId, function(character)
        -- set this location's doctor
        location.DoctorId = playerId        

        -- we need this location id for when we go off duty
        Doctor.OnDuty[playerId] = locationId

        -- notify player's chat
        Helpers.Respond(playerId, '^2You went on duty as a Doctor.')

        -- notify client of duty status
        Helpers.Packet(playerId, 'doctor:SetDuty', { IsOnDuty = true })
    end)
end

function Doctor.GoOffDuty(playerId)
    Helpers.GetCharacter(playerId, function(character)
        -- get the doctor's location
        local location = Doctor.Locations[Doctor.OnDuty[playerId]]
        if (location ~= nil and location.DoctorId ~= playerId) then
            Helpers.Respond(playerId, '^1You are not our Doctor!')
            return
        end

        -- clear doctor from the below
        location.DoctorId = nil
        Doctor.OnDuty[playerId] = nil

        -- notify player's chat
        Helpers.Respond(playerId, '^2You went off duty.')

        -- notify client of duty status
        Helpers.Packet(playerId, 'doctor:SetDuty', { IsOnDuty = false })        
    end)  
end

function Doctor.BuyBandage(playerId)
    Helpers.GetCharacter(playerId, function(character)
        -- validate we have enough money
        if (character.getMoney() < 1.0) then
            Helpers.Respond(playerId, '^1You don\'t have enough money for that!')
            return
        end

        character.removeMoney(1)

        -- get inventory data and add item
        Helpers.GetInventory(function(inventory)
            inventory.addItem(playerId, 'Bandage', 1, 1)
        end)

        --TriggerEvent("item:add", playerId, {'Bandage', 1, 1}, character.getIdentifier(), character.getSessionVar("charid"))
        --TriggerClientEvent('gui:ReloadMenu', playerId)

        Helpers.Respond(playerId, '^2You purchased a Bandage for $1.00.')
    end)
end

function Doctor.CheckIn(playerId, locationId)
    local location = Doctor.Locations[locationId]
    if (location == nil) then
        return
    end

    Helpers.GetCharacter(playerId, function(character)
        if (character.getMoney() < 1.0) then
            Helpers.Packet(playerId, 'doctor:ClearRequest')
            Helpers.Respond(playerId, '^1You don\'t have enough money to be seen by a doctor, partner!')
            return
        end

        character.removeMoney(1)
        Helpers.Respond(playerId, '^2You are being helped by the doctor. Hang \'round here for a second, partner. You paid $1.00.')

        SetTimeout(10000, function()
            Helpers.Packet(playerId, 'doctor:Release')
        end)
    end)
end

function Doctor.TreatPlayer(playerId, patientId, revive, coords)
    -- give the doctor some xp
    Helpers.GetCharacter(playerId, function(doctor)
        doctor.addXP(5)
        doctor.addMoney(1)

        -- charge the patient a dollar
        Helpers.GetCharacter(patientId, function(patient)
            if (patient.getMoney() > 1) then
                patient.removeMoney(1)
            end
        end)

        -- notify doctor/patient the treatment happened
        Helpers.Respond(playerId, '^2You have treated a person. You have earned $1.')
        Helpers.Respond(patientId, '^2You have been treated by the doctor. If you could afford it, it cost you $1.')

        -- treat the patient
        Helpers.Packet(patientId, 'doctor:TreatPlayer', { Revive = revive, Coords = coords })        
    end)
end

function Doctor.OnPlayerDropped(playerId)
    for k, v in pairs(Doctor.Locations) do
        if (v.DoctorId == playerId) then
            v.DoctorId = nil
            break
        end
    end
end

-- Payment Timer
function Doctor.PayTimer()
    SetTimeout(60000*5, function()
        for k, v in pairs(Doctor.Locations) do
            if (v.DoctorId ~= nil) then
                Helpers.GetCharacter(v.DoctorId, function(character)
                    character.addXP(5)
                    character.addMoney(3)

                    Helpers.Respond(v.DoctorId, '^2You have been paid $3.00 and received 5 xp for your work, Doctor.')
                end) 
            end
        end

        Doctor.PayTimer()
    end)
end
Doctor.PayTimer()