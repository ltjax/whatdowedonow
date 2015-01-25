local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Door=class('Door')
local Vector=require "Vector"

function Door:initialize(x, y, playerList)
  self.activated=false
  self.position={x=x, y=y}
  self.playerList=playerList
  self.image=love.graphics.newImage("p/tuer_1.png")
  self.quad=love.graphics.newQuad(0, 0, 64, 64, self.image:getDimensions())
end


function Door:draw(camera)
  local cx, cy=camera:offsets()
  
  love.graphics.setColor(72, 28, 10, 255)
  
  love.graphics.draw(self.image, self.quad, self.position.x+cx-32, self.position.y+cy-32)
end


function Door:update(dt)
    
  if self.locked then
    return
  end
  
  local previousState=self.activated
  
  for i=1,#self.playerList do
    local player=self.playerList[i]
    local maxDistance=30
    local squareDistance=Vector.squareDistance(player.position, self.position)
    if squareDistance < maxDistance*maxDistance and player.action then
      self.activated=true
    end
  end
  
  -- Has anything changed? notify event handlers
  if self.activated ~= previousState then
    self.quad=love.graphics.newQuad(64, 0, 64, 64, self.image:getDimensions())
    if self.stateChanged then
      self.stateChanged(self.activated)
    end
  end
end

return Door