group = {}

function group:new(player)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o = s.create_unit_group{position=player.position, force=player.force}
  return o
end

function group:addUnit(entity)
	if entity.type == "unit" then
		self.add_member(entity)
	end
end

function group:command(data)
	local t = {}
	if data then
		t.type = data[1]
		t.field1 = ""
		t.field2 = ""
		if data[2] then
			t.field1 = data[2]
		end
		if data[3] then
			t.field2 = data[3]
		end

	self.set_command(t.type, t.field1, t.field2)
	end
end

function group:auto()
	self.set_autonomous()
end

function group:rush()
	self.start_moving()
end