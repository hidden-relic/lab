local tools = require('lib/tools')

function Modules(moduleInventory) -- returns the multiplier of the modules
    local effect1 = moduleInventory.get_item_count("productivity-module") -- type 1
    local effect2 = moduleInventory.get_item_count("productivity-module-2") -- type 2
    local effect3 = moduleInventory.get_item_count("productivity-module-3") -- type 3

    local multi = effect1 * 4 + effect2 * 6 + effect3 * 10
    return multi / 100 + 1
end

function AmountOfMachines(itemsPerSecond, output)
    if (itemsPerSecond) then return itemsPerSecond / output end
end

commands.add_command("ratio",
                     "gives ratio info on the selected machine and its recipe. provide a number for items/sec",
                     function(command)
    local player = game.players[command.player_index]
    local machine = player.selected -- selected machine
    local itemsPerSecond
    if not machine then -- nil check
        return player.print("[color=red]No valid machine selected..[/color]")
    end

    if machine.type ~= "assembling-machine" and machine.type ~= "furnace" then
        return player.print("[color=red]Invalid machine..[/color]")
    end

    local recipe = machine.get_recipe() -- recipe

    if not recipe then -- nil check
        return player.print("[color=red]No recipe set..[/color]")
    end

    local items = recipe.ingredients -- items in that recipe
    local products = recipe.products -- output items
    local amountOfMachines
    local moduleInventory = machine.get_module_inventory() -- the module Inventory of the machine
    local multi = Modules(moduleInventory) -- function for the productively modules
    if (command.parameter ~= nil) then
        itemsPerSecond = tonumber(command.parameter)
    end
    if itemsPerSecond then
        amountOfMachines = math.ceil(AmountOfMachines(itemsPerSecond, 1 /
                                                          recipe.energy *
                                                          machine.crafting_speed *
                                                          products[1].amount *
                                                          multi)) -- amount of machines
    end
    if not amountOfMachines then
        amountOfMachines = 1 -- set to 1 to make it not nil
    end
    ----------------------------items----------------------------
    for i, item in ipairs(items) do
        local sprite -- string to make the icon work either fluid ore item
        if item.type == "item" then
            sprite = 'ratio.item-in'
        else
            sprite = 'ratio.fluid-in'
        end
        local ips = item.amount / recipe.energy * machine.crafting_speed *
                        amountOfMachines -- math on the items/fluids per second
        player.print {sprite, tools.round(ips, 3), item.name} -- full string
    end
    ----------------------------products----------------------------
    for i, product in ipairs(products) do
        local sprite -- string to make the icon work either fluid ore item
        if product.type == "item" then
            sprite = 'ratio.item-out'
        else
            sprite = 'ratio.fluid-out'
        end
        local output = 1 / recipe.energy * machine.crafting_speed *
                           product.amount * multi -- math on the outputs per second
        player.print {sprite, tools.round(output * amountOfMachines, 3), product.name} -- full string
    end

    if amountOfMachines ~= 1 then
        player.print {'ratio.machines', amountOfMachines}
    end
end)

commands.add_command("get", "get item", function(command)
    local player = game.players[command.player_index]
    if game.item_prototypes[command.parameter] then
        player.insert {
            name = command.parameter,
            count = game.item_prototypes[command.parameter].stack_size
        }
    end
end)

commands.add_command("mark", "mark a position", function(command)
    local player = game.players[command.player_index]
    if not global.markers then global.markers = {} end
        table.insert(global.markers, tools.drawCircle(tools.fixCoords(player.position.x, player.position.y)))
end)
