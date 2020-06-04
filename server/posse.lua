-- Slash Commands
RegisterCommand('posse', function(source, args, rawCommand)
    local playerId = source
    Helpers.Packet(playerId, 'posse:Open', nil)
end, false)