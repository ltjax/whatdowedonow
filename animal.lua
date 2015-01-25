local class = require "middleclass"
local Vector = require "vector"
local Walker = require "walker"

local Animal = class("Animal")

function Animal:initialize(image, speed, distance)
  self.walker = Walker:new(image)
  self.position = {x=0, y=0}
  self.waitTime = 0.0
  self.drawLayer = 2
  self.speed = speed
  self.distance = distance
end

function Animal:setPosition(x, y)
  self.walker:reset()
  self.position={x=x, y=y}
end

function Animal:update(dt)
  if self.waitTime > 0 then
    self.waitTime = self.waitTime - dt
    self.walker:stand()
  else
    if not self.targetPosition then
      local offset2D = {x=love.math.random(-self.distance, self.distance), y=love.math.random(-self.distance, self.distance)}
      self.targetPosition = Vector.add(self.position, offset2D)
    end
    
    local delta = Vector.subtract(self.targetPosition, self.position) 
    local distance = Vector.length(delta)
    local maxSpeed = self.speed*dt
    
    if distance < maxSpeed then
      maxSpeed = distance
      self.targetPosition=nil
      self.waitTime = love.math.random(0.6, 2.2)
    end
    
    local move = Vector.scale(delta, maxSpeed/distance)
    self.position = Vector.add(self.position, move)
    self.walker:updateWalk(move.x, move.y, dt)
  end
end
  
function Animal:draw(camera)
  local cx,cy=camera:offsets()
  love.graphics.setColor(200, 200, 200, 255)
  self.walker:draw(self.position.x+cx, self.position.y+cy)
end

return Animal