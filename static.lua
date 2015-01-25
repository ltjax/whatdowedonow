
local class = require "middleclass"


local Static=class("static")

function Static:initialize(x, y, image)
  self.position = {x=x, y=y}
  self.image = image
end

function Static:draw(camera)
  local cx, cy=camera:offsets()
  love.graphics.draw(self.image, self.position.x+cx, self.position.y+cy)
end
