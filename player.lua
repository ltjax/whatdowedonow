
local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Player=class('Player')
local Walker= require "Walker"
local SimpleAnimation = require "SimpleAnimation"

function Player:initialize(image, dyingImage)
  self.speed = 160.0
  self.position = {x=0, y=0}
  self.walker = Walker:new(image)
  self.drawLayer = 2
  self.dead=false
  self.dyingAnimation = SimpleAnimation:new(dyingImage, 4, 0.06)
end

function Player:setPosition(x,y)
  self.position= {x=x, y=y}
  self.walker:reset()
  self.dead=false
  self.dyingAnimation:reset()
end

function Player:kill()
  self.dead=true
  self.dyingAnimation:start()
end

function Player:update(deltaTime)
  
  self.dyingAnimation:update(deltaTime)
  
  if self.dead then
    return
  end
  
  local threshold=0.5
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
    
    local mapBorder=2048+1024
    self.position.x=math.max(-mapBorder, math.min(mapBorder, self.position.x))
    self.position.y=math.max(-mapBorder, math.min(mapBorder, self.position.y))
  end

  
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
  
  if not self.dead then
    self.walker:draw(self.position.x+cx, self.position.y+cy)
  else
    self.dyingAnimation:draw(self.position.x+cx, self.position.y+cy)
  end
end

function Player:setJoystick(joystick)
  self.joystick=joystick
end

function Player:setKeys(keys)
  self.keys = keys
end
return Player
