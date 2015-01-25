local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Button=class('Button')
local Vector=require "Vector"

function Button:initialize(x, y, playerList, explicitAction, volatile, imageName, pressTime)
  self.activated=false
  self.position={x=x, y=y}
  self.playerList=playerList
  self.locked=false
  self.explicitAction=explicitAction
  self.volatile=volatile
  self.image=love.graphics.newImage(imageName)
  self.totalPressTime=pressTime or 0
  self.currentPressTime=0
  self.hidden=false
end

function Button:hide()
  self.hidden=true
end

function Button:show()
  self.hidden=false
end

function Button:draw(camera)
  if self.hidden then
    return
  end
  
  local quad
  local tileSize=64
  if self.activated then
    quad = love.graphics.newQuad(64, 0, 64, 64, self.image:getDimensions())
  else
    quad = love.graphics.newQuad(0, 0, 64, 64, self.image:getDimensions())
  end
  local cx, cy=camera:offsets()
  
  love.graphics.setColor(120, 120, 120, 255)
  love.graphics.draw(self.image, quad, self.position.x+cx-32, self.position.y+cy-32)
  
  if self.totalPressTime>0 then
    love.graphics.rectangle("line", self.position.x+cx-32, self.position.y+cy+32+8, 64, 8)
    love.graphics.rectangle("fill", self.position.x+cx-32, self.position.y+cy+32+8, 64*self.currentPressTime/self.totalPressTime, 8)
  end
end

function Button:update(dt)
  if self.locked or self.hidden then
    return
  end
  
  local previousState=self.activated
  
  if self.volatile or not self.activated then
    local buttonPressed=false
    
    for i=1,#self.playerList do
      local player=playerList[i]
      local maxDistance=50
      local squareDistance=Vector.squareDistance(player.position, self.position)
      if squareDistance < maxDistance*maxDistance and (player.action or not self.explicitAction) then
        buttonPressed=true
      end
    end
    
    if self.totalPressTime <= 0.0 then
      self.activated=buttonPressed
    elseif buttonPressed then
      self.currentPressTime = self.currentPressTime + dt
      if self.currentPressTime >= self.totalPressTime then
        self.activated=true
      end
    else
      self.currentPressTime = 0
    end
  end
  
  -- Has anything changed? notify event handlers
  if self.stateChanged and self.activated ~= previousState then
    self.stateChanged(self.activated)
  end
end

return Button
