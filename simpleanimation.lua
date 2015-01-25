local class = require "middleclass"

local SimpleAnimation=class("SimpleAnimation")

function SimpleAnimation:initialize(image, count, frameTime)
  self.image=love.graphics.newImage(image)
  self.count=count
  self.tileSizeX=self.image:getWidth()/count
  self.tileSizeY=self.image:getHeight()
  self.frameList={}
  for i=0,count-1 do
    table.insert(self.frameList, love.graphics.newQuad(i*self.tileSizeX, 0, self.tileSizeX, self.tileSizeY, self.image:getDimensions()))
  end
  self.currentFrame=1
  self.currentTimer=0.0
  self.frameTime=frameTime
  self.stopped=true
end

function SimpleAnimation:start()
  self.stopped=false
end

function SimpleAnimation:finished()
  return self.currentFrame == #self.frameList
end

function SimpleAnimation:update(dt)
  if self.stopped then
    return
  end
  
  self.currentTimer = self.currentTimer + dt
  
  while self.currentTimer > self.frameTime and self.currentFrame < #self.frameList do
    self.currentFrame = self.currentFrame + 1
    self.currentTimer = self.currentTimer - self.frameTime
  end
  
  if self.currentFrame == #self.frameList then
    self.stopped=true
  end
end

function SimpleAnimation:draw(x, y)
  love.graphics.draw(self.image, self.frameList[self.currentFrame], x-self.tileSizeX/2, y-self.tileSizeY/2)
end

return SimpleAnimation
