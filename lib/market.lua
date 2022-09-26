local gui = require("mod-gui")
local tools = require("lib.tools")

local Market = {balance = 0, market_gui_visible = false}
function Market:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Market:init(item_values)
    self.item_values = {}
    for _, entry in pairs(tools.sortByValue(item_values)) do
        for name, value in pairs(entry) do
            -- self.player.print(name.."\t"..serpent.line(value))
            self.item_values[name] = tools.round(value)
        end
    end
    self:create_market_button()
    self:create_market_gui()
end

function Market:deposit(v)
    self.balance = self.balance + v
    self:update()
end

function Market:withdraw(v)
    if v > self.balance then
        self.player.print("Insufficient Funds")
    else
        self.balance = self.balance - v
        self:update()
    end
end

function Market:create_market_button()
    self.button_flow = gui.get_button_flow(self.player)
    self.market_button = self.button_flow.add {
        name = "market_button",
        type = "sprite-button",
        sprite = "item/coin",
        number = self.balance,
        tooltip = "[item=coin] "..self.balance
    }
end

function Market:create_market_gui()
    self.frame_flow = gui.get_frame_flow(self.player)
    self.main_frame = self.frame_flow.add {
        type = "frame",
        direction = "vertical",
        visible = self.market_gui_visible
    }
    self.main_flow = self.main_frame.add {
        type = "flow",
        direction = "vertical"
    }
    self.items_frame = self.main_flow.add {
        type = "frame",
        direction = "vertical"
    }
    self.items_flow = self.items_frame.add {
        type = "scroll-pane",
        direction = "vertical"
    }

    self.item_table = self.items_flow.add {type = "table", column_count = 20}
    self.items = {}
    for name, value in pairs(self.item_values) do
        self.items[name] = self.item_table.add {
            name = name,
            type = "sprite-button",
            sprite = "item/" .. name,
            number = math.floor(self.balance / value),
            tooltip = {"tooltips.market_items", name, game.item_prototypes[name].localised_name, value}
        }
    end
end

function Market:toggle_market_gui()
    self:update()
    self.market_gui_visible = not self.market_gui_visible
    self.main_frame.visible = self.market_gui_visible
end

function Market:update()
    self.market_button.number = self.balance
    self.market_button.tooltip = "[item=coin] "..self.balance
    for index, button in pairs(self.items) do
        local value = self.item_values[index]
        button.number = math.floor(self.balance / value)
        button.tooltip = {"tooltips.market_items", button.name, game.item_prototypes[button.name].localised_name, value}
    end
end

function Market:purchase(item)
    local item=item
    local value=self.item_values[item]
    if math.floor(self.balance/value) and self.player.can_insert{name=item} then
        self:withdraw(value)
        self.player.insert{name=item}
    end
end

return Market

