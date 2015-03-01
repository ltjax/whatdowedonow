local class = require "middleclass"
local Vector = require "vector"

local SimpleAnimation=require "simpleanimation"

local SmallBomb=class("SmallBomb")

function SmallBomb:initialize(x, y, playerList)
  self.playerList=playerList
  self.position={x=x, y=y}
  self.initialPosition={x=x, y=y}
  
  self.animation=SimpleAnimation:new("p/bumb.png", 8, 0.25)
  self.triggered=false
  self.explosionTime = -1
  self.explosionRadius = 200
  self.drawLayer = 4
end

function SmallBomb:reset()
  self.position={x=self.initialPosition.x, y=self.initialPosition.y}
  self.triggered=false
  self.animation:reset()
  self.explosionTime = -1
end

function SmallBomb:draw(camera)
  local cx, cy = camera:offsets()
  if self.explosionTime <= 1 then
    local minRadius=30
    local radius=minRadius+self.explosionTime*(self.explosionRadius-minRadius)
    love.graphics.setColor(255,50,50,255)
    love.graphics.circle("fill", self.position.x+cx, self.position.y+cy, radius, 100)
  end
end

function SmallBomb:getDepth()
  return self.animation:getDepth(self.position.y)
end

function SmallBomb:drawSprite(camera)
  local cx, cy = camera:offsets()
  if self.explosionTime < 0 then
    love.graphics.setColor(255,255,255,255)
    self.animation:draw(self.position.x+cx, self.position.y+cy)
  end
end

function SmallBomb:inExplosionRange(position)
  local squareDistance=Vector.squareDistance(position, self.position)
  return squareDistance < self.explosionRadius*self.explosionRadius
end

function SmallBomb:update(dt)
  self.animation:update(dt)
  
  local triggerDistance = 100
  local moveDistance = 30
  local inTriggerRange=false
  local move={x=0, y=0}
  
  for i=1,#self.playerList do
    local player=self.playerList[i]
    local delta=Vector.subtract(player.position, self.position)
    local squareDistance=delta.x*delta.x+delta.y*delta.y
    
    if squareDistance < triggerDistance*triggerDistance  then
      inTriggerRange=true
    end
    
    if squareDistance < moveDistance*moveDistance then
      if math.abs(delta.x) > math.abs(delta.y) then
        move.x = delta.x < 0 and 1 or -1
      else
        move.y = delta.y < 0 and 1 or -1
      end
    end
  end
  
  if move.x ~= 0 or move.y ~= 0 then
    Vector.normalize(move)
    move = Vector.scale(move, dt*165.0)
    self.position = Vector.add(self.position, move)
  end
  
  -- set off the bomb
  if not self.triggered and inTriggerRange then
    self.animation:start()
  end
  
  if self.explosionTime < 0 and self.animation:finished() then
    self.explosionTime = 0
    
    for i=1,#self.playerList do
      local player=self.playerList[i]
      if self:inExplosionRange(player.position) then
        player:kill()
      end
    end
    
    if self.onExplode then
      self.onExplode()
    end
  end
  
  if self.explosionTime >= 0.0 then
    self.explosionTime = self.explosionTime + dt*10
  end
end

return SmallBomb