-- Packet Handler stuffs
RegisterNetEvent('redemrp_jobs:Packet')
AddEventHandler('redemrp_jobs:Packet', function(packetName, data)
	local packetHandler = Helpers.PacketHandlers[packetName]
	if (packetHandler ~= nil) then
		packetHandler(data)
	end
end)

function Helpers.Packet(packetName, data)
	TriggerServerEvent('redemrp_jobs:Packet', GetPlayerServerId(PlayerId()), packetName, data)
end

function Helpers.PacketHandler(packetName, callback)
	if (packetName == nil or packetName == '') then
		print('Invalid packet.')
		return
	elseif (callback == nil) then
		print(string.format('Invalid callback for packet %s.', packetName))
		return
	elseif (Helpers.PacketHandlers[packetName] ~= nil) then
		print(string.format('Duplicate packet ignored: %s', packetName))
		return
	end

	Helpers.PacketHandlers[packetName] = callback
end
-- End Packet Handler

-- Deal with blips
function Helpers.AddBlip(blipSpriteType, coords, name)
	local resultPromise = promise:new()	
	Citizen.CreateThread(function()
		local blip = N_0x554d9d53f696d002(1664425300, coords)
		SetBlipSprite(blip, blipSpriteType, 1)
		SetBlipScale(blip, 0.01)
		Citizen.InvokeNative(0x9CB1A1623062F402, blip, name)	
		resultPromise:resolve(blip)
	end)
	return Citizen.Await(resultPromise)
end

-- Handle Prompts
function Helpers.RegisterPrompt(text, actionKey, promptGroup)
	local handle = PromptRegisterBegin()
	PromptSetControlAction(handle, actionKey) --0xE8342FF2)
	PromptSetText(handle, CreateVarString(10, 'LITERAL_STRING', text))
	PromptSetEnabled(handle, false)
	PromptSetVisible(handle, false)
	PromptSetHoldMode(handle, true)
	PromptRegisterEnd(handle)

	if (promptGroup) then
		PromptSetGroup(handle, promptGroup)
	end

	Helpers.Prompts[handle] = false
	return handle	
end

function Helpers.RemovePrompt(handle)
	PromptDelete(handle)
end

function Helpers.SetPromptActive(handle, value)
	PromptSetEnabled(handle, value)
	PromptSetVisible(handle, value)
end

function Helpers.Prompt(promptHandle, cb)
    -- if there is no active prompt, activate!
	if (not Helpers.Prompts[promptHandle]) then
        Helpers.Prompts[promptHandle] = true
		Helpers.SetPromptActive(promptHandle, true)
	else
        -- did we complete prompt?
		if (PromptHasHoldModeCompleted(promptHandle)) then
            Helpers.CancelPrompt(promptHandle)
            -- notify the caller! HELLO SIR WE HAVE A PROMPT COMPLETION!
			cb()
        end
    end
end

function Helpers.CancelPrompt(promptHandle)
	if (Helpers.Prompts[promptHandle]) then
    	Helpers.SetPromptActive(promptHandle, false)
		Helpers.Prompts[promptHandle] = false
	end
end
-- End Handle Prompts

-- Get the local ped and coords
function Helpers.GetLocalPed()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)	
	return playerPed, playerCoords
end

-- Start a gameplay object that will initialize and tick
function Helpers.StartGameplay(object)
    Citizen.CreateThread(function()
        object.Initialize()
        while true do
            Citizen.Wait(0)
            object.Tick()
        end
    end)
end

-- Maybe not used because of prompts?
function Helpers.IsActionKeyPressed()
	if (IsControlJustPressed(0, Controls.Jump)) then
		if (Helpers.NextActionAt ~= nil and Helpers.NextActionAt > GetGameTimer()) then			
			return false
		end
		Helpers.NextActionAt = GetGameTimer() + 1000
		return true
	end
	return false
end

function Helpers.IsControlPressed(controlId)
	if (IsControlJustPressed(0, controlId)) then
		if (Helpers.NextControlAt ~= nil and Helpers.NextControlAt > GetGameTimer()) then			
			return false
		end
		Helpers.NextControlAt = GetGameTimer() + 1000
		return true
	end
	return false
end

-- Get Distance and Closest locations
function Helpers.GetDistance(coords1, coords2)
    return GetDistanceBetweenCoords(coords1, coords2.x, coords2.y, coords2.z, true)
end

function Helpers.GetClosestLocation(coords, locations)
    local maxDistance = 999999
    local val = {
        Index = -1,
        Distance = maxDistance
    }

    for i = 1, #locations do
        local distance = Helpers.GetDistance(coords, locations[i].Coords)
        if (distance < maxDistance) then
            maxDistance = distance
            val.Distance = distance
            val.Index = i
        end
    end

    return val
end
--

-- Draw Markers and 3D Text
function Helpers.DrawMarker(coords, color)
	Citizen.InvokeNative(0x2A32FAA57B937173, Markers.Cylinder, coords.x, coords.y, coords.z-0.95, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.25, color.r, color.g, color.b, color.a, 0, 0, 2, 0, 0, 0, 0)	
end

function Helpers.DrawText3d(coords, text, size, font)
	local camCoords = Citizen.InvokeNative(0x595320200B98596E, Citizen.ReturnResultAnyway(), Citizen.ResultAsVector())
	local distance = Helpers.GetDistance(coords, camCoords)
	local fov = (1 / GetGameplayCamFov()) * 100
	local scale = ((size / distance) * 2) * fov	
	local visible, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

	if (visible) then
		SetTextScale(0.0 * scale, 0.55 * scale)
		SetTextColor(255, 255, 255, 255)

		if (font ~= nil) then
			SetTextFontForCurrentCommand(font)
		end

		SetTextDropshadow(0, 0, 0, 255)
		SetTextCentre(true)
		DisplayText(CreateVarString(10, 'LITERAL_STRING', text), x, y)
	end
end

-- UI functions
function Helpers.OpenUI(uiName, data)
	if (Helpers.CurrentUI) then
		Helpers.CloseUI(true)
	end

	Helpers.CurrentUI = uiName

	-- send message to nui and focus ui
	SendNUIMessage({ target = uiName, method = 'open', data = data })
	SetNuiFocus(true, true)
end

function Helpers.CloseUI(callNui)
	if (Helpers.CurrentUI) then
		if (callNui) then
			SendNUIMessage({ target = Helpers.CurrentUI, method = 'close' })
		end
		SetNuiFocus(false, false)
		Helpers.CurrentUI = nil
	end
end

function Helpers.MessageUI(target, method, data)
	SendNUIMessage({ target = target, method = method, data = data })
end

function Helpers.LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)        
        Citizen.Wait(1)
    end
end

function Helpers.SpawnNPC(hash, x, y, z)
    local hash = GetHashKey(hash)
    Helpers.LoadModel(hash)
    local result = Citizen.InvokeNative(0xD49F9B0955C367DE, hash, x, y, z, 0, 0, 0, 0, Citizen.ResultAsInteger())
    Citizen.InvokeNative(0x1794B4FCC84D812F, result, 1) -- SetEntityVisible
    Citizen.InvokeNative(0x0DF7692B1D9E7BA7, result, 255, false) -- SetEntityAlpha
    Citizen.InvokeNative(0x283978A15512B2FE, result, true) -- Invisible without
    Citizen.InvokeNative(0x4AD96EF928BD4F9A, hash) -- SetModelAsNoLongerNeeded

    return result
end

-- NUI Callbacks
RegisterNUICallback('CloseMenu', function(data, cb)
	Helpers.CloseUI(false)
end)