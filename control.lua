tools = require('lib/tools')
market = require('lib/market')
require('lib/group')
require('lib/buildTree')
require('lib/commands')
local production_score = require("production-score")
local item_values = {}
s = {}

script.on_init(function(event)
    s = tools.createLabSurface()
    for k, v in pairs(production_score.generate_price_list()) do
        if game.item_prototypes[k] then item_values[k]=v end
    end
    my_group = {}
    markets = {}
end)

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
    markets[player.name]=market:new{player=player}
    markets[player.name]:init(item_values)
    tools.safeTeleport(player, s, {x = 0, y = 0})
    tools.givePowerArmorMK2(player)
    tools.giveTestKit(player)
    tools.givePlayerLongReach(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    if event.element == markets[player.name].market_button then
        markets[player.name]:toggle_market_gui()
    end
    if markets[player.name].items[event.element.name] then
        local button = markets[player.name].items[event.element.name]
        markets[player.name]:purchase(button.name)
    end
end)