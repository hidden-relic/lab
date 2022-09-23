-- a global variable is used across all files, can be accessed by all players (through the code, not the console), and resides in the running game's global table. try NOT to use globals
a_global_variable = "a global value"

-- local variables are local in their scope (inside whatever they are created in, no parents)
local a_local_variable = "a local value"

--the local variable can now be referenced just by it's name
a_local_variable = "a new local value"

-- function creation

local function funcname(param_a, param_b)
	-- this local variable is only available inside this function, but you can just return it to ask for it outside
	local var_local_to_function = "some value"
	print(param_a)
	print(param_b)
	return var_local_to_function
end

local funcname = function(param_a, param_b)
	local var_local_to_function = "some value"
	print(param_a)
	print(param_b)
	return var_local_to_function
end

-- both functions above are exactly the same. first declares a local function called funcname, second declares an 'anonymous' function under the variable name funcname, both are called exactly the same.
local var_inside_function = funcname("param 1", "param 2")
-- this prints both args and sets var_inside_function to var_local_to_function's value ("some value")

-- save a function under a different name (this can increase performance if function belongs to some table or some other file)
local newfuncname = funcname --no parenthesis

--if a function has named parameters, or has a table as a parameter, such as "teleport{"surface_name", {x, y}}" or "teleport{surface="surface_name"}" as you can see curlies {} must be used in place of parenthesis

--it can be thought of like you're passing a big table on the tail of the function name.
-- example_function{big="table", possible_with={another="table"}}

-- tables

-- {} for tables (an 'object'. can be a list, key/value pairs, or functions or whatever mixed)

local a_list = {"hello", "there"} -- accessed by index (lua is NOT 0-based, 1 is the first item)
print(a_list[1]) -- prints "hello"

table.insert(a_list, "nerd") -- adds "nerd" as a third item to a_list
print(a_list[3]) -- prints "nerd"

print(#a_list) -- prints the count

-- create an empty table:
local empty_table = {}

--create a table with values
local table_with_values = {
	key_1 = "value 1",
	key_2 = "value 2",
	["key_3"] = "value 3"
}
print(table_with_values.key_1) -- prints "value 1"
print(table_with_values["key_3"]) -- to access named keys (for dynamic usage, like a player's name). prints "value 3"
local dynamic_var = "key_3"
print(table_with_values[dynamic_var]) -- prints "value 3"

-- lua uses dot notation
local a_table = {}

function a_table.a_table_function(params)
	print("this is a function inside a table")
end

a_table.a_table_function = function(params)
	print("this is the exact same function")
end

-- lua doesn't seem to mind incorrect indents. you just need an "end".
function a_table.another_table_function(params) print("single line function") end

-- instead of curlies or indents to signify code blocks, lua uses a suffix of 'then' or 'do', and a prefix of 'end'
-- 'then' is for a decision i guess you'd call it
if a == b then print(a) end
-- 'do' is for looping
while a ~= b do print(b) end -- a while loop. ~= is lua's "not-equal-to". forget !=. this will print b's value until a equals b
for i in 1, 100 do print(i) end -- a for loop, will iterate through the target. this prints 1-100
for i in "hello" do print(i) end -- this should print a single letter on each line h-e-l-l-o (i believe)

-- other files/modulation
--declare a local table to hold everything in
local this_file = {} --use this variable to hold things you want to be 'global'

this_file.key_a = "value 1"

function this_file.a_function()
	print("function local to file")
end

--at the end, just return the variable as if this file is just a variable of it's own in some bigger function, being returned to a less local scope
return this_file

--in another file, you can then use
local first_file = require("first_file_name")
first_file.a_function() -- will print "function local to file" from function in first file

--this is how you can make things 'global', by using the files only where needed with 'require'
