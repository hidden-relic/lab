local util = require("util")

local t = {
    "[color=0, 1, 0]", 
    "[color=0, 0.5, 0.5]", 
    "[color=0, 0, 1]",
    "[color=0.5, 0, 0.5]",  
    "[color=1, 0, 0]",
    "[color=0.5, 0.5, 0]",
    "[color=0, 1, 0]", 
    "[color=0, 0.5, 0.5]", 
    "[color=0, 0, 1]",
    "[color=0.5, 0, 0.5]",  
    "[color=1, 0, 0]",
    "[color=0.5, 0.5, 0]",
}

local str = ""

local function color(n, str)
    return t[n] .. tostring(str) .. "[/color]"
end

local function getIndent(n)
    local n = n or 1
    local indentation = ">>"
    local str = ""
    for i = 1, n, 1 do
            str = str .. color(i, indentation)
    end
    return str
end

function buildTree(recipe, count, indent)
    local p = game.player.print
    local str = str
    if not indent then str = " " end
    local recipe = recipe
    local products = recipe.products
    local count = count or 1
    count = count * products[1].amount
    local indent = indent or 1
    local recipes = game.recipe_prototypes
    local ingredients = recipe.ingredients
    local fluid_table = {
        ["petroleum-gas"] = true,
        ["light-oil"] = true,
        ["heavy-oil"] = true
    }
    if recipe then
        local string = " x" .. count .. " " .. recipe.name ..
        "\n"
        str = str .. getIndent(indent) .. color(indent, string)
        if ingredients then
            indent = indent + 1
            for i, ingredient in pairs(ingredients) do
                if ingredient.type == "item" and recipes[ingredient.name] then
                    str = str ..
                              buildTree(recipes[ingredient.name],
                                        ingredient.amount, indent)
                elseif fluid_table[ingredient.name] then
                    str = str ..
                              buildTree(recipes["advanced-oil-processing"],
                                        ingredient.amount, indent)
                elseif ingredient.type == "item" and not recipes[ingredient.name] then
                    string = " x" .. count .. " " .. ingredient.name ..
        "\n"
        str = str .. getIndent(indent) .. color(indent, string)
                end
            end
        end
    else
        indent = indent - 1
    end
    return str
end

commands.add_command("tree",
                     "prints recipe tree\nrecipe tree will be logged to %AppData%/roaming/factorio/script-output/lab\nleave the parameter blank to get all trees written to file\nexample:\n/tree electronic-circuit",
                     function(command)
    local player = game.players[command.player_index]
    if command.parameter then
        if game.recipe_prototypes[command.parameter] then
            player.print("[font=debug-mono]"..buildTree(game.recipe_prototypes[command.parameter]).."[/font]")
            game.write_file("lab/tree_"..command.parameter..".txt", "")
        elseif type(command.parameter) == "LuaRecipePrototype" then
            player.print("[font=debug-mono]"..buildTree(command.parameter).."[/font]")
            game.write_file("lab/"..command.parameter..".txt", "")
        end
    else
        for _, item in pairs(game.recipe_prototypes) do
            game.write_file("lab/tree_all.txt", buildTree(item), true)
        end
    end
end)