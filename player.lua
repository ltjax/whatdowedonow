
local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Player=class('Player')
local Walker= require "Walker"
local SimpleAnimation = require "SimpleAnimation"
local Vector = require "Vector"

function Player:initialize(image, dyingImage, hugImage, hugOffset)
  self.speed = 160.0
  self.position = {x=0, y=0}
  self.walker = Walker:new(image)
  self.drawLayer = 2
  self.dead=false
  self.dyingAnimation = SimpleAnimation:new(dyingImage, 4, 0.06)
  self.hugAnimation = SimpleAnimation:new(hugImage, 24, 0.1)
  self.hugOffset = hugOffset
  self.hugging=false
end

function Player:setPosition(x,y)
  self.position= {x=x, y=y}
  self.walker:reset()
  self.dead=false
  self.dyingAnimation:reset()
end

function Player:hug()
  self.hugging=true
  self.hugAnimation:start()
end

function Player:kill()
  self.dead=true
  self.dyingAnimation:start()
end

function Player:updateInput()
  local dx, dy = 0, 0
  
  self.action=false
  
  if self.joystick then
    dx, dy = self.joystick:getAxes()
    if self.joystick:isGamepadDown("a") then
      self.action=true
    end
  end

  if( self.keys ) then
    if love.keyboard.isDown(self.keys[1]) then
      dy = -1
    end
    if love.keyboard.isDown(self.keys[2]) then
      dx = -1
    end
    if love.keyboard.isDown(self.keys[3]) then
      dy = 1
    end
    if love.keyboard.isDown(self.keys[4]) then
      dx = 1
    end
    if love.keyboard.isDown(self.keys[5]) then
      self.action=true
    end
    
    local mapBorder=1990
    self.position.x=math.max(-mapBorder, math.min(mapBorder, self.position.x))
    self.position.y=math.max(-mapBorder, math.min(mapBorder, self.position.y))
  end
  
  return dx, dy
end

function Player:update(deltaTime)

  if self.hugging then
    self.hugAnimation:update(deltaTime)
    if self.hugAnimation:finished() and self.huggingFinished then
      self.huggingFinished()
      self.huggingFinished = nil
    end  
    return
  end

  self.dyingAnimation:update(deltaTime)
  
  if self.dead then
    return
  end
  
  
  local dx, dy = 0, 0
  
  if not self.autoTarget then
    dx, dy = self:updateInput()
  else
    local delta = Vector.subtract(self.autoTarget, self.position)
    
    if math.abs(delta.x)<=1 and math.abs(delta.y)<=1 then
      self.position = {x=self.autoTarget.x, y=self.autoTarget.y}
      self.autoTarget = nil
      self.autoTargetFinished()
    else
      if math.abs(delta.x)>1 then
        dx = delta.x<0 and -1 or 1
      end
      if math.abs(delta.y)>1 then
        dy = delta.y<0 and -1 or 1
      end
    end  
  end
  
  local threshold=0.5
  if math.abs(dx) > threshold or math.abs(dy) > threshold then
    local scale=deltaTime*self.speed
    self.position = {x=self.position.x+scale*dx, y=self.position.y+scale*dy}
    
    self.walker:updateWalk(dx, dy, deltaTime)
  else
    self.walker:stand()
  end
end

function Player:draw(camera)
  
  love.graphics.setColor(180, 180, 180, 255);
  --camera:draw(self.image, self.position.x+self.offset.x, self.position.y+self.offset.y)
  local cx, cy = camera:offsets()
  
  if not self.hugging then   
    if not self.dead then
      self.walker:draw(self.position.x+cx, self.position.y+cy)
    else
      self.dyingAnimation:draw(self.position.x+cx, self.position.y+cy)
    end
  else
    self.hugAnimation:draw(self.position.x+cx-32, self.position.y+cy)
  end
end

function Player:setJoystick(joystick)
  self.joystick=joystick
end

function Player:setKeys(keys)
  self.keys = keys
end
return Player
