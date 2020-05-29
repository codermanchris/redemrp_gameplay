Helpers.PacketHandler('store:BuyCheese', function(playerId, data)
    GeneralStore.BuyCheese(playerId)
end)

function GeneralStore.BuyCheese(playerId)
    Helpers.GetCharacter(playerId, function(character)
        -- validate we have enough money
        if (character.getMoney() < 1.0) then
            Helpers.Respond(playerId, '^1You don\'t have enough money for that!')
            return
        end

        character.removeMoney(1)

        -- get inventory data and add item
        Helpers.GetInventory(function(inventory)
            inventory.addItem(playerId, 'Cheese', 2, 1)
        end)

        Helpers.Respond(playerId, '^2You purchased 2x Cheese for $1.00.')
    end)    
end
