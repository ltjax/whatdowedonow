
local class = require "middleclass"
assert(class, "Unable to load middleclass")
local Vector = require "vector"

local Glowworm=class("Glowworm")

local function normalize(p)
  local length = math.sqrt(p.x*p.x + p.y*p.y)
  p.x = p.x / length;
  p.y = p.y / length;  
end

function Glowworm:initialize(x, y, image)
  self.position = {x=x, y=y}
  self.image = image
  self:pickTarget()
  self.jitterPosition = {x=0, y=0}
  self.drawLayer = 4
end

function Glowworm:pickTarget()
  local angle=love.math.random(0.0, 2*math.pi)
  local distance=love.math.random(5, 13)
  
  self.jitterTarget = Vector.scale(Vector.fromAngle(angle), distance)
end

function Glowworm:update(dt)
  
  local delta = Vector.subtract(self.jitterTarget, self.jitterPosition) 
  local distance = Vector.length(delta)
  
  if distance > 1 then
    self.jitterPosition = Vector.add(self.jitterPosition,Vector.scale(delta, math.min(dt*2, distance)))
  else
    self:pickTarget()
  end

end

function Glowworm:draw(camera)
  
  love.graphics.setBlendMode("additive") --Default blend mode
  love.graphics.setColor(255, 255, 255, 80)
  
  local cx, cy = camera:offsets()
  local position=Vector.add(self.position, self.jitterPosition)
  love.graphics.draw(self.image, position.x+cx+self.image:getWidth()/2, position.y+cy+self.image:getHeight()/2)
  love.graphics.setBlendMode("alpha") --Default blend mode
end


return Glowworm
