local class = require "middleclass"
assert(class, "Unable to load middleclass")

-- Control a walker sprite
local Walker=class('Walker')

function Walker:initialize(image, tileSizeX, tileSizeY)
  self.image=love.graphics.newImage(image)
  self.direction = 1
  self.anim={}
  self.animState=1
  self.animTransition=0.0
  
  self.tileSizeX=tileSizeX or self.image:getWidth() / 16
  self.tileSizeY=tileSizeY or self.image:getHeight()
  
  -- FIXME: use linear array here?
  for x=1,4 do
    self.anim[x] = {}
    for y=1,4 do
      self.anim[x][y] = love.graphics.newQuad((x-1)*self.tileSizeX+(y-1)*self.tileSizeX*4, 0, self.tileSizeX, self.tileSizeY, self.image:getDimensions())
    end
  end
  
  self.offset = {x=-self.tileSizeX/2, y=-self.tileSizeY/2}
end

function Walker:reset()
  self.direction = 1
  self.animState=1
  self.animTransition=0.0
end

function Walker:draw(x, y)
  love.graphics.draw(self.image, self.anim[self.animState][self.direction], x+self.offset.x, y+self.offset.y)
end

function Walker:updateWalk(dx, dy, deltaTime)
  if math.abs(dx) > math.abs(dy) then
    if dx < 0 then
      self.direction = 4
    else
      self.direction = 2
    end
  else
    if dy < 0 then
      self.direction = 3
    else
      self.direction = 1
    end
  end


  -- Make sure we are in a moving anim state
  if self.animState == 1 then
    self.animState = 2
  end
  
  -- Change between animstates as long as we are moving
  self.animTransition = self.animTransition + deltaTime
  if self.animTransition > 0.15 then
    self.animTransition = 0.0
    self.animState = self.animState + 1
    if self.animState > 4 then
      self.animState = 2
    end
  end
end

function Walker:stand()
  self.animState = 1
end

return Walker