
local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Jumper=class("Jumper")
local SimpleAnimation= require "SimpleAnimation"

function Jumper:initialize(x, y)
  self.position={x=x, y=y}
  self.animation=SimpleAnimation:new("p/sui.png", 16, 0.12)
  self.initialPosition={x=x, y=y}
  self:reset()
end

function Jumper:reset()
  self.timeOut = 18.0
  self.animation:reset()
  self.position = {x=self.initialPosition.x, y=self.initialPosition.y}
  self.move=0
end

function Jumper:draw(camera)
  if self.hide then
    return
  end
  
  local cx,cy=camera:offsets()
  love.graphics.setColor(255, 255, 255, 255)
  self.animation:draw(cx+self.position.x, cy+self.position.y)
end

function Jumper:update(dt)
  
  if self.hide then
    return
  end
  
  self.animation:update(dt)
  
  if self.timeOut <= 0.0 and self.animation.stopped then
    self.animation:start()
    self.move = 60
  else
    self.timeOut = self.timeOut - dt
  end
  
  self.position = {x=self.position.x, y=self.position.y+self.move*dt}
end

return Jumper