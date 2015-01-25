local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Grave=class('Grave')

function Grave:initialize(x, y)
  self.position = {x=x, y=y}
  self.image = love.graphics.newImage("p/grab.png")
  self.imageCandle = love.graphics.newImage("p/grab_kerze.png")
  self.drawLayer = 3
  self.hasCandle = false
end

function Grave:update(dt)
end

function Grave:draw(camera)
  local cx, cy = camera:offsets()
  local x = self.position.x+cx
  local y = self.position.y+cy

  if self.hasCandle then
    love.graphics.draw(self.imageCandle, x-self.imageCandle:getWidth()/2, y-self.imageCandle:getHeight()/2)
  else
    love.graphics.draw(self.image, x-self.image:getWidth()/2, y-self.image:getHeight()/2)
    
  end
end

return Grave