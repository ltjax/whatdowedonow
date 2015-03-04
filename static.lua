
local class = require "middleclass"


local Static=class("static")

function Static:initialize(x, y, image)
  self.image = image
  self.depthOffset = self.image:getHeight()
  self.position = {x=x, y=y}
  self.drawPosition = {x=x-self.image:getWidth()/2, y=y-self.image:getHeight()/2}
end

function Static:getDepth()
  return self.position.y + self.depthOffset
end

function Static:drawSprite(camera)
  local cx, cy=camera:offsets()
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(self.image, self.drawPosition.x+cx, self.drawPosition.y+cy)
end

return Static