local tools = require('lib/tools')
local d_r = require('dataraw')
global.grid = {}

commands.add_command("grid",
                     "draw a grid pattern.\n/grid 32\nwould make a 32x32 grid (snapped to 0, 0)",
                     function(command)
    local player = game.players[command.player_index]
    if global.grid[1] then
        for __, line in pairs(global.grid) do line.destroy() end
    end
    if not command.parameter then
        player.print("Invalid parameter. Please give a size.")
        return
    else
        range = tools.round(1000 / command.parameter)
        for a = -(range * command.parameter), range * command.parameter, command.parameter do
            local line = rendering.draw_line {
                color = {r=1, g=0.5, b=0},
                width = 3,
                gap_length = 1,
                dash_length = 3,
                from = {x = a, y = -(range * command.parameter)},
                to = {x = a, y = range * command.parameter},
                surface = player.surface
            }
            table.insert(global.grid, line)
        end
        for a = -(range * command.parameter), range * command.parameter, command.parameter do
            local line = rendering.draw_line {
                color = {r=1, g=0.5, b=0},
                width = 3,
                gap_length = 1,
                dash_length = 3,
                from = {x = -(range * command.parameter), y = a},
                to = {x = (range * command.parameter), y = a},
                surface = player.surface
            }
            table.insert(global.grid, line)
        end
    end
end)

local function kind_of(obj)
    if type(obj) ~= 'table' then return type(obj) end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return 'table'
        end
    end
    if i == 1 then
        return 'table'
    else
        return 'array'
    end
end

local function escape_str(s)
    local in_char = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/', 'b', 'f', 'n', 'r', 't'}
    for i, c in ipairs(in_char) do s = s:gsub(c, '\\' .. out_char[i]) end
    return s
end

local function num_tostring(num)
    if num ~= num then return 'NaN' end
    if num == 1 / 0 then return 'Infinity' end
    if num == -1 / 0 then return '-Infinity' end
    return tostring(num)
end

local function stringify(obj, as_key)
    local s = {} -- We'll build the string as an array of strings to be concatenated.
    local kind = kind_of(obj) -- This is 'array' if it's an array or type(obj) otherwise.
    if kind == 'array' then
        if as_key then error('Can\'t encode array as key.') end
        s[#s + 1] = '['
        for i, val in ipairs(obj) do
            if i > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = stringify(val)
        end
        s[#s + 1] = ']'
    elseif kind == 'table' then
        if as_key then error('Can\'t encode table as key.') end
        s[#s + 1] = '{'
        for k, v in pairs(obj) do
            if #s > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = stringify(k, true)
            s[#s + 1] = ':'
            s[#s + 1] = stringify(v)
        end
        s[#s + 1] = '}'
    elseif kind == 'string' then
        return '"' .. escape_str(obj) .. '"'
    elseif kind == 'number' then
        if as_key then return '"' .. num_tostring(obj) .. '"' end
        return num_tostring(obj)
    elseif kind == 'boolean' then
        return tostring(obj)
    elseif kind == 'nil' then
        return 'null'
    else
        error('Unjsonifiable type: ' .. kind .. '.')
    end
    return table.concat(s)
end

commands.add_command("data2json", "writes data.raw to json", function(command)
    game.write_file("data_raw.json", stringify(d_r))
    game.print("data.raw written to data_raw.json")
end)

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
        player.print {
            sprite, tools.round(output * amountOfMachines, 3), product.name
        } -- full string
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
    table.insert(global.markers, tools.drawCircle(
                     tools.fixCoords(player.position.x, player.position.y)))
end)

commands.add_command("group",
                     "handle a unit group\nhover over an entity with your cursor while using /group to specify\n/group spawner :: creates a friendly spawner near your player\n/group new :: initializes a unit group for this surface\n/group add :: add entity under cursor to unit group (must be an entity of type: unit)\n/group attack (while hovering)\n/group go_to_location (while hovering)\n/group attack_area <radius> (while hovering)\n/group wander\n/group stop\n/group flee (while hovering)\n/group build_base (while hovering)>",
                     function(command)
    local player = game.players[command.player_index]
    if not command.parameter then
        player.print("Need help? Try /help group")
        return
    end
    if player.selected then sel = player.selected end
    local args = tools.split(command.parameter)

    if args[1] == "spawner" then
        player.surface.create_entity {
            name = "biter-spawner",
            force = player.force,
            position = player.surface.find_non_colliding_position(
                "biter-spawner", player.position, 8, 1)
        }

    elseif args[1] == "new" then
        my_group = tools.newGroup(player)

    elseif args[1] == "add" then
        if not sel then
            local units = game.player.surface.find_units({
                area = {
                    {player.position.x - 16, player.position.y - 16},
                    {player.position.x + 16, player.position.y + 16}
                },
                force = player.force,
                condition = "same"
            })
            for _, o in pairs(units) do tools.addToGroup(player, o) end
        else
            local entity = player.selected
            tools.addToGroup(player, entity)
        end

    else
        if args[1] == "attack" then
            my_group:command(defines.command.attack, sel)
        elseif args[1] == "go_to_location" then
            my_group:command(defines.command.go_to_location, sel)
        elseif args[1] == "attack_area" then
            local r = args[2] or 8
            my_group:command(defines.command.attack_area, sel, r)
        elseif args[1] == "flee" then
            my_group:command(defines.command.flee, sel)
        elseif args[1] == "build_base" then
            my_group:command(defines.command.build_base, sel)
        elseif args[1] == "wander" then
            my_group:command(defines.command.wander)
        elseif args[1] == "stop" then
            my_group:command(defines.command.stop)
        end
    end
end)
