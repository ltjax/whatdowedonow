local class = require "middleclass"
local Vector = require "vector"
local Walker = require "walker"

local Dog = class("Dog")

function Dog:initialize(players, targets)
  self.walker = Walker:new("p/bestdog.png", 50, 32)
  self.walker.frameTime = 0.1

  self.sitImage = love.graphics.newImage("p/dog_sit_l.png")
  self.sitAnim = {}
  for t=1,8 do
    self.sitAnim[t] = love.graphics.newQuad(t*50, 0, 50, 32, self.sitImage:getDimensions())
  end

  self.targets = targets
  self.currentTargetIndex = 1
  self.waiting = false
  self.waitingSince = 0.0
  self.speed = 250
  self.walker:reset()
  self.position = self.targets[1] -- first target is the starting pos
  self.players = players
end

function Dog:reset()
  self.currentTargetIndex = 1
  self.waiting = false
  self.waitingSince = 0.0
  self.walker:reset()
  self.position = self.targets[1] -- first target is the starting pos
end

function Dog:getDepth()
  return self.walker:getDepth(self.position.y)
end

function Dog:setPosition(x, y)
  self.walker:reset()
  self.position={x=x, y=y}
end

function Dog:update(dt)

  if self.waiting then
    local nearest = 1000
    for i=1,#self.players do
      nearest = math.min(nearest,Vector.length(Vector.subtract(self.players[i].position, self.position)))
    end

    if nearest < 50 and self.currentTargetIndex < #self.targets then 
      self.currentTargetIndex = self.currentTargetIndex+1
    end
  end


  local delta = Vector.subtract(self.targets[self.currentTargetIndex], self.position)
  local distance = Vector.length(delta)
  local maxSpeed = self.speed*dt
    
  if distance < maxSpeed then
    maxSpeed = distance
    self.waiting = true
    self.waitingSince = self.waitingSince + dt

    local frame = math.floor(self.waitingSince / 0.15)
    if frame < 4 then
      self.sitQuad = self.sitAnim[frame+1]
    else
      frame = math.floor(self.waitingSince / 1.0)
      self.sitQuad = self.sitAnim[(frame % 4) + 4]
    end
    return
  end

  self.waiting = false
  self.waitingSince = 0

  local move = Vector.scale(delta, maxSpeed/distance)
  self.position = Vector.add(self.position, move)
  self.walker:updateWalk(move.x, move.y, dt)
end
  
function Dog:drawSprite(camera)
  local cx,cy=camera:offsets()
  local x = self.position.x + cx
  local y = self.position.y + cy
  love.graphics.setColor(200, 200, 200, 255)
  if self.waiting then
    love.graphics.draw(self.sitImage, self.sitQuad, x-25, y-16)
  else
    self.walker:draw(x, y)
  end
end

return Dog