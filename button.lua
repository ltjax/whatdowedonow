local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Button=class('Button')
local Vector=require "vector"

function Button:initialize(x, y, playerList, imageName, sound, options)
  assert(x and y and playerList and imageName, "Incorrect number of parameters")
  
  self.activated=false
  self.position={x=x, y=y}
  self.playerList=playerList
  self.locked=false
  if options and options.volatile ~= nil then
    self.volatile = options.volatile
  else
    self.volatile = true
  end
  self.image=love.graphics.newImage(imageName)
  self.totalPressTime=options and options.pressTime or 0
  self.currentPressTime=0
  self.hidden=false
  self.sound=love.audio.newSource(sound)
  self.sound:setLooping(false)
  self.drawLayer=4
  
  if self.image:getWidth() == 128 then
    self.normalOffset=0
    self.activatedOffset=64
  else
    self.normalOffset=64
    self.activatedOffset=128
  end
  
end

function Button:hide()
  self.hidden=true
end

function Button:show()
  self.hidden=false
end

function Button:getDepth()
  return self.position.y - 32 -- Sic! want to force this "under" all other things
end

function Button:drawSprite(camera)
  if self.hidden then
    return
  end
  
  local cx, cy=camera:offsets()
  
  local quad
  local tileSize=64
  if self.locked and not self.activated then
    quad = love.graphics.newQuad(0, 0, tileSize, tileSize, self.image:getDimensions())
  elseif self.activated then
    quad = love.graphics.newQuad(self.activatedOffset, 0, tileSize, tileSize, self.image:getDimensions())
  else
    quad = love.graphics.newQuad(self.normalOffset, 0, tileSize, tileSize, self.image:getDimensions())
  end
  
  love.graphics.setColor(180, 180, 180, 255)
  love.graphics.draw(self.image, quad, self.position.x+cx-32, self.position.y+cy-32)
end

function Button:draw(camera)
  if self.hidden then
    return
  end
  
  local cx, cy=camera:offsets()
    
  if self.totalPressTime>0 and self.currentPressTime>0 and not self.activated then
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
      local player=self.playerList[i]
      local maxDistance=50
      local squareDistance=Vector.squareDistance(player.position, self.position)
      if squareDistance < maxDistance*maxDistance and player.action then
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
    if self.activated then
      self.sound:play()
    end
  end
end

return Button
