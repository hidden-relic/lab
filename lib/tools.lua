local tools = {}

tools.test_kit = {
    {name = "infinity-chest", count = 20}, {name = "infinity-pipe", count = 20},
    {name = "electric-energy-interface", count = 20},
    {name = "express-loader", count = 50},
    {name = "express-transport-belt", count = 50},
    {name = "express-underground-belt", count = 50},
    {name = "express-splitter", count = 50},
    {name = "stack-inserter", count = 50},
    {name = "medium-electric-pole", count = 50},
    {name = "big-electric-pole", count = 50}, {name = "substation", count = 50}
}

function tools.stockUp()
    if material_chest and material_chest.valid then
        local chest_inv = material_chest.get_inventory(defines.inventory.chest)
        chest_inv.clear()
        local list = s.find_entities_filtered {type = "entity-ghost"}
        for _, ghost in pairs(list) do
            if ghost.ghost_name == "curved-rail" or ghost.ghost_name ==
                "straight-rail" then
                if chest_inv.can_insert("rail") then
                    chest_inv.insert {name = "rail", count = 1}
                end
            else
                if chest_inv.can_insert(ghost.ghost_name) then
                    chest_inv.insert {name = ghost.ghost_name, count = 1}
                end
            end
        end
    end
end

function tools.makeSpawn()
    material_chest = s.create_entity {
        force = "player",
        name = "logistic-chest-passive-provider",
        position = {x = 1.5, y = -2.5}
    }
    local roboport = s.create_entity {
        force = "player",
        direction = 0,
        force = "player",
        name = "roboport",
        position = {x = -1, y = -3},
        control_behavior = {
            read_logistics = false,
            read_robot_stats = true,
            available_logistic_output_signal = {
                type = "item",
                name = "logistic-robot"
            },
            available_construction_output_signal = {
                type = "item",
                name = "construction-robot"
            }
        }
    }
    local substation = s.create_entity {
        force = "player",
        name = "substation",
        position = {x = -2, y = -6}
    }
    local power = s.create_entity {
        force = "player",
        name = "electric-energy-interface",
        position = {x = 0, y = -6}
    }
    local constant_combinator = s.create_entity {
        force = "player",
        control_behavior = {
            filters = {
                {
                    count = -1,
                    index = 1,
                    signal = {name = "logistic-robot", type = "item"}
                },
                {
                    count = -1,
                    index = 2,
                    signal = {name = "construction-robot", type = "item"}
                }
            }
        },
        direction = 4,
        name = "constant-combinator",
        position = {x = -3.5, y = -3.5}
    }
    local stack_inserter = s.create_entity {
        force = "player",
        control_behavior = {circuit_mode_of_operation = 1},
        direction = 6,
        name = "stack-filter-inserter",
        position = {x = -3.5, y = -1.5}
    }
    local decider_combinator = s.create_entity {
        force = "player",
        control_behavior = {
            decider_conditions = {
                comparator = "≤",
                constant = 0,
                copy_count_from_input = false,
                first_signal = {name = "signal-anything", type = "virtual"},
                output_signal = {name = "signal-anything", type = "virtual"}
            }
        },
        direction = 6,
        name = "decider-combinator",
        position = {x = -4, y = -2.5}
    }
    local infinity_chest = s.create_entity {
        force = "player",
        infinity_settings = {
            filters = {
                {
                    count = 50,
                    index = 1,
                    mode = "at-least",
                    name = "logistic-robot"
                },
                {
                    count = 50,
                    index = 2,
                    mode = "at-least",
                    name = "construction-robot"
                }
            },
            remove_unfiltered_items = false
        },
        name = "infinity-chest",
        position = {x = -4.5, y = -1.5}
    }
    s.create_entity {
        force = "player",
        name = "logistic-chest-storage",
        position = {x = 1.5, y = -3.5}
    }
    s.create_entity {
        force = "player",
        name = "logistic-chest-storage",
        position = {x = 1.5, y = -1.5}
    }
    local roboport_connection = roboport.connect_neighbour({
        wire = defines.wire_type.red,
        target_entity = decider_combinator,
        target_circuit_id = defines.circuit_connector_id.combinator_input
    })
    local combinator_connection = constant_combinator.connect_neighbour({
        wire = defines.wire_type.red,
        target_entity = decider_combinator,
        target_circuit_id = defines.circuit_connector_id.combinator_input
    })
    local inserter_connection = decider_combinator.connect_neighbour({
        wire = defines.wire_type.red,
        target_entity = stack_inserter,
        source_circuit_id = defines.circuit_connector_id.combinator_output
    })
    roboport.insert {name = "construction-robot", count = 1}
    roboport.insert {name = "logistic-robot", count = 1}
end

function tools.fixCoords(t, y)
    local flr = math.floor
    if y and type(t) == "number" then
        t = {
            x = t >= 0 and flr(t) + 0.5 or flr(t) - 0.5,
            y = y >= 0 and flr(y) + 0.5 or flr(y) - 0.5
        }
    elseif type(t) == "table" then
        t = {
            x = t[1] >= 0 and (flr(t[1]) + 0.5) or (flr(t[1]) - 0.5),
            y = t[2] >= 0 and (flr(t[2]) + 0.5) or (flr(t[2]) - 0.5)
        }
    end
    return t
end

function tools.round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function tools.sortByValue(t)
    local keys = {}

    for key, _ in pairs(t) do table.insert(keys, key) end

    table.sort(keys, function(keyLhs, keyRhs) return t[keyLhs] < t[keyRhs] end)
    local r = {}
    for _, key in ipairs(keys) do table.insert(r, {[key] = t[key]}) end
    return r
end

function tools.createLabSurface()
    s = game.create_surface("lab")
    s.generate_with_lab_tiles = true
    s.always_day = true
    return s
end

function tools.safeTeleport(player, surface, target_pos)
    local safe_pos = surface.find_non_colliding_position("character",
                                                         target_pos, 15, 1)
    if (not safe_pos) then
        player.teleport(target_pos, surface)
    else
        player.teleport(safe_pos, surface)
    end
end

function tools.givePowerArmorMK2(player)
    player.insert {name = "power-armor-mk2", count = 1}

    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and
        player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor =
            player.get_inventory(defines.inventory.character_armor)[1].grid
        if p_armor ~= nil then
            for i = 1, 2 do
                p_armor.put({name = "fusion-reactor-equipment"})
            end
            for i = 1, 2 do
                p_armor.put({name = "personal-laser-defense-equipment"})
            end
            for i = 1, 2 do
                p_armor.put({name = "exoskeleton-equipment"})
            end
            for i = 1, 2 do
                for j = 1, 2 do
                    p_armor.put({name = "personal-roboport-mk2-equipment"})
                end
                p_armor.put({name = "personal-laser-defense-equipment"})
            end
            for i = 1, 2 do
                p_armor.put({name = "energy-shield-mk2-equipment"})
            end
            for i = 1, 6 do
                p_armor.put({name = "battery-mk2-equipment"})
            end
        end
        player.insert {name = "construction-robot", count = 100}
        player.insert {name = "belt-immunity-equipment", count = 1}
    end
end

function tools.giveTestKit(player)
    for _, item in pairs(tools.test_kit) do player.insert(item) end
end

function tools.givePlayerLongReach(player)
    player.character.character_build_distance_bonus = 2500
    player.character.character_reach_distance_bonus = 2500
    player.character.character_resource_reach_distance_bonus = 2500
end

function tools.sel(n, ...) return arg[n] end

function tools.modules(moduleInventory) -- returns the multiplier of the modules
    local effect1 = moduleInventory.get_item_count("productivity-module") -- type 1
    local effect2 = moduleInventory.get_item_count("productivity-module-2") -- type 2
    local effect3 = moduleInventory.get_item_count("productivity-module-3") -- type 3

    local multi = effect1 * 4 + effect2 * 6 + effect3 * 10
    return multi / 100 + 1
end

function tools.amountOfMachines(itemsPerSecond, output)
    if (itemsPerSecond) then return itemsPerSecond / output end
end

function tools.drawCircle(position, radius, color, width, filled, TTL)
    local circle = rendering.draw_circle {
        color = color or
            {
                r = math.random(0, 255),
                g = math.random(0, 255),
                b = math.random(0, 255)
            },
        radius = radius or 0.5,
        width = width or 1,
        filled = filled or true,
        target = position,
        players = {game.player.index},
        surface = game.player.surface,
        time_to_live = TTL or 60 * 5 * 60
    }
    return circle
end

function tools.split(inputstr)
    local sep = "%s"
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function tools.newGroup(player)
    local player = player
    local ng = group:new(player)
    if ng then
        player.print(
            "Group successfully created. You should now add unit members with /group add")
        return ng
    else
        player.print("Couldn't make group..")
    end
end

function tools.addToGroup(player, entity)
    local player = player
    local entity = entity
    if entity.type ~= "unit" then return end
    if not my_group then
        my_group = tools.newGroup(player)
        player.print(
            "No Group was set so one was created. You can now add more unit members with /group add")
    end
    if my_group and entity.valid then
        my_group:add_member(entity)
        player.print(entity.name .. " successfully added")
    else
        player.print("Couldn't add")
    end
end

tools.drawText = {
    above = function(text, position, color, ttl)
        local text = text or ""
        local position = position
        local color = color or
                          {
                r = math.random(0, 255),
                g = math.random(0, 255),
                b = math.random(0, 255)
            }
        local ttl = ttl or 60 * 5 * 60
        local r = rendering.draw_text {
            text = text,
            surface = s,
            target = position,
            target_offset = {0, -1.5},
            color = color or {r = 1, g = 0.5, b = 1},
            time_to_live = ttl or 60 * 60 * 10
        }
        return r
    end,
    below = function(text, position, color, ttl)
        local text = text or ""
        local position = position
        local color = color or
                          {
                r = math.random(0, 255),
                g = math.random(0, 255),
                b = math.random(0, 255)
            }
        local ttl = ttl or 60 * 5 * 60
        local r = rendering.draw_text {
            text = text,
            surface = s,
            target = position,
            target_offset = {0, 1.5},
            color = color or {r = 1, g = 0.5, b = 1},
            time_to_live = ttl or 60 * 60 * 10
        }
        return r
    end,
    left = function(text, position, color, ttl)
        local text = text or ""
        local position = position
        local color = color or
                          {
                r = math.random(0, 255),
                g = math.random(0, 255),
                b = math.random(0, 255)
            }
        local ttl = ttl or 60 * 5 * 60
        local r = rendering.draw_text {
            text = text,
            surface = s,
            target = position,
            target_offset = {-1.5, 0},
            color = color or {r = 1, g = 0.5, b = 1},
            time_to_live = ttl or 60 * 60 * 10
        }
        return r
    end,
    right = function(text, position, color, ttl)
        local text = text or ""
        local position = position
        local color = color or
                          {
                r = math.random(0, 255),
                g = math.random(0, 255),
                b = math.random(0, 255)
            }
        local ttl = ttl or 60 * 5 * 60
        local r = rendering.draw_text {
            text = text,
            surface = s,
            target = position,
            target_offset = {1.5, 0},
            color = color or {r = 1, g = 0.5, b = 1},
            time_to_live = ttl or 60 * 60 * 10
        }
        return r
    end
}

-- commands.add_command("drawline",
--                      "draw a line\nusage: (use the semicolons to separate args)\n/drawline <position or entity 1>; <position or entity 2>; <table of players who can see>; <color>; <width>; <gap length>; <dash length>; <TTL>;",
--                      function(command)
--     local player = game.players[command.player_index]
--     local args = string.split(command.parameter, "; ")
--     local from = args[1] or player.character
--     local to = args[2] or player.selected
--     local players = args[3] or {player.index}
--     local color = args[4]
--     local width = args[5]
--     local gap_length = args[6]
--     local dash_length = args[7]
--     local time_to_live = args[8] * 60
--     local line = rendering.draw_line {
--         surface = player.surface,
--         from = args[1] or player.character,
--         to = args[2] or player.selected,
--         players = args[3] or {player},
--         color = args[4],
--         width = args[5],
--         gap_length = args[6],
--         dash_length = args[7],
--         time_to_live = args[8] * 60
--     }
-- end)

return tools
