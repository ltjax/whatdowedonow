local class = require "middleclass"
assert(class, "Unable to load middleclass")
local Vector = require "vector"

local Lamp=class("Lamp")

function Lamp:initialize(x, y, image, imageGlow)
  self.position = {x=x, y=y}
  self.image = image
  self.imageGlow = imageGlow
  self.turnedOn = false
  self.drawLayer = 3
end

function Lamp:getDepth()
  return self.position.y+self.image:getHeight()/2
end

function Lamp:drawSprite(camera)  
  local cx, cy = camera:offsets()
  local x = self.position.x+cx
  local y = self.position.y+cy
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(self.image, x-self.image:getWidth()/2, y-self.image:getHeight()/2)
end

function Lamp:draw(camera)
  if self.turnedOn then
    local cx, cy = camera:offsets()
    local x = self.position.x+cx
    local y = self.position.y+cy
    love.graphics.setColor(255,255,255,255)

    -- love.graphics.setBlendMode("additive") --Default blend mode
    love.graphics.draw(self.imageGlow, x-self.imageGlow:getWidth()/2, y-self.imageGlow:getHeight()/2-38)

    love.graphics.setBlendMode("alpha") --Default blend mode
  end
end



return Lamp
