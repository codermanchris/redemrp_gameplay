-- Packet Handler
RegisterServerEvent('redemrp_jobs:Packet')
AddEventHandler('redemrp_jobs:Packet', function(playerId, packetName, data)
	if (not Helpers.IsPlayerIdValid(source, playerId)) then
		return
	end

	local packetHandler = Helpers.PacketHandlers[packetName]
	if (packetHandler ~= nil) then
		packetHandler(playerId, data)
	end
end)

function Helpers.Packet(playerId, packetName, data)
	TriggerClientEvent('redemrp_jobs:Packet', playerId, packetName, data)
end

function Helpers.PacketHandler(packetName, callback)
	if (packetName == nil or packetName == '') then
		print('Invalid packet.')
		return
	elseif (callback == nil) then
		print(string.format('Invalid callback for event %s.', packetName))
		return
	elseif (Helpers.PacketHandlers[packetName] ~= nil) then
		print(string.format('Duplicate event ignored: %s', packetName))
		return
	end

	Helpers.PacketHandlers[packetName] = callback
end
-- End Packet Handler

function Helpers.GetInventory(cb)
	TriggerEvent("redemrp_inventory:getData", function(data)
    	cb(data)
	end)
end

function Helpers.IsPlayerIdValid(source, playerId)
	if (tonumber(source) == nil or source == 65535 or source == -1 or playerId ~= source) then
		return false
	end	
	return true	
end

function Helpers.Respond(playerId, message)
	TriggerClientEvent('chatMessage', playerId, '', {0,0,0}, message)
end

function Helpers.GetDistance(coords1, coords2)
	return math.sqrt((coords2.x-coords1.x)^2 + (coords2.y-coords1.y)^2 + (coords2.z-coords1.z)^2)
end

function Helpers.GetCharacter(playerId, cb)
	TriggerEvent('redemrp:getPlayerFromId', playerId, function(user)
		cb(user)
	end)
end