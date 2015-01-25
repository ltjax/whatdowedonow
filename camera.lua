local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Camera=class('Camera')

function Camera:initialize()
  self.position = {x=0, y=0}
  self.targetPosition = {x=0, y=0}
  self.target = {x=0, y=0}
  self.offset = {x=0, y=0}
  self.size = {x=1, y=1}
  self.margin = 100
end

function Camera:setScissor()
  love.graphics.setScissor(self.offset.x, self.offset.y, self.size.x, self.size.y)
end

function Camera:setFollowTargets(primary, secondary, range)
  self.primary=primary
  self.secondary=secondary
  self.range=range
end

function Camera:resize(x, y, w, h)
  self.offset = {x=x, y=y}
  self.size = {x=w, y=h}
end

function Camera:print(text, font, x, y)
  
  local dx, dy = self:offsets()
  love.graphics.setFont(font);
  love.graphics.print(text, x+dx, y+dy);
end

function Camera:update(dt)
  if not self.primary or not self.secondary then
    return
  end

  local tdx = self.secondary.position.x - self.primary.position.x
  local tdy = self.secondary.position.y - self.primary.position.y

  if math.abs(tdx) < self.size.x * 2 - self.margin and math.abs(tdy) < self.size.y - self.margin then
    -- players are close together; behave as one screen
    local xoff = self.size.x/2 - self.offset.x
    self.targetPosition.x = self.secondary.position.x - tdx/2 - xoff
    self.targetPosition.y = self.secondary.position.y - tdy/2
  else
    -- players further apart; split the screen
    local dx = self.primary.position.x-self.targetPosition.x
    local dy = self.primary.position.y-self.targetPosition.y
    local distance=math.sqrt(dx*dx+dy*dy)
    
    if distance > self.range then
      local scale=1.0-self.range/distance
      self.targetPosition.x = self.targetPosition.x + dx*scale
      self.targetPosition.y = self.targetPosition.y + dy*scale
    end
  end

  -- apply some damping if we are on the verge of splitting the camera
  -- otherwise just set position without damping
  if
    math.abs(tdx) > self.size.x * 2 - self.margin * 2 or
    math.abs(tdy) > self.size.y - self.margin * 2
  then
    self.position.x = self.position.x - (self.position.x - self.targetPosition.x)/10
    self.position.y = self.position.y - (self.position.y - self.targetPosition.y)/10
  else
    self.position.x = self.targetPosition.x
    self.position.y = self.targetPosition.y
  end

end

function Camera:offsets()
  return -self.position.x+self.size.x/2+self.offset.x, -self.position.y+self.size.y/2+self.offset.y
end

function Camera:draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
  -- TODO add clipping
  local dx, dy = self:offsets()
  love.graphics.draw(drawable, x+dx, y+dy, r, sx, sy, ox, oy, kx, ky)
end

function Camera:setPosition(x, y)
  self.position={x=x, y=y}
end

return Camera
