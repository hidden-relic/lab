tools = require('lib/tools')
require('lib/commands')
require('lib/buildTree')
s = {}
script.on_init(function(event) s = tools.createLabSurface() end)

script.on_event(defines.events.on_tick, function(event)
    if game.tick == (1 * 60) then tools.makeSpawn() end
    if (game.tick % 60) == 0 then tools.stockUp() end
    if global.markers then
        for _, marker in pairs(global.markers) do
            if not rendering.is_valid(marker) then marker = nil end
        end
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]

    tools.safeTeleport(player, s, {x = 0, y = 0})
    tools.givePowerArmorMK2(player)
    tools.giveTestKit(player)
    tools.givePlayerLongReach(player)
end)