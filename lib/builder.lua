Builder = {}

function Builder:new(definition)
  local obj = {}
  setmetatable(obj, self)
  self.__index = self
  obj.actions = {}
  obj.index = 1
  obj.position = definition.position
  obj.last_tick = definition.tick
  return obj
end

function Builder:addbuild(builddata)
  self.actions[#self.actions + 1] = builddata
end

function Builder:update(tick)
  if self.index > #self.actions then return end
  action = self.actions[self.index]
  if tick < action.tick + self.last_tick then return end

  -- perform action
  self.position = action.positionfunction(self.position)
  self.index = self.index + 1
  game.surfaces["lab"].create_entity{name=action.name, position=self.position, direction=action.direction}
  self.last_tick = self.last_tick + action.tick
end

function down(position) return {x=position.x, y=position.y + 1} end
function right(position) return {x=position.x + 1, y=position.y} end

-- builder = Builder:new({position={x=0, y=12}, tick=game.tick})
-- for i = 1, 10 do
--   builder:addbuild{tick=10, name="straight-rail", positionfunction=right, direction=defines.direction.east}
-- end
--   builder:addbuild{tick=10, name="curved-rail", positionfunction=left, direction=defines.direction.north}
-- for i = 1, 10 do
--   builder:addbuild{tick=10, name="straight-rail", positionfunction=up, direction=defines.direction.north}
-- end