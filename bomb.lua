

local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Bomb=class("Bomb")

function Bomb:initialize()
  self.maxTime = 20
  self.time = self.maxTime
  self.position = {x=0, y=0}
  self.explosionTime = 0.4
  self.drawLayer = 5
  self.font = love.graphics.newFont("p/digital-7.ttf", 16)
  self.explosionSound = love.audio.newSource("s/Bomb.mp3", "static")
  self.explosionSound:setLooping(false)
  self.explosionSound:setVolume(0.3)
  self.image=love.graphics.newImage("p/bomb_big_bigger.png")
  self.haloImage=love.graphics.newImage("p/glowworm.png")
end

function Bomb:reset()
  self.time = self.maxTime
  resetGame()
end

function Bomb:draw(camera)
  local ox, oy=camera:offsets()
  love.graphics.draw(self.image, self.position.x + ox - self.image:getWidth()/2, self.position.y + oy - self.image:getHeight()/2)
  
  love.graphics.setBlendMode("additive") --Default blend mode
  love.graphics.setColor(50, 50, 50, 80)
  local flickerTime=1
  local haloScale=100+math.sin(math.fmod(self.time, flickerTime)/flickerTime*math.pi)*2
  love.graphics.draw(self.haloImage, self.position.x + ox - haloScale*self.haloImage:getWidth()/2, self.position.y + oy - haloScale*self.haloImage:getHeight()/2, 0, haloScale, haloScale)
  love.graphics.setBlendMode("alpha") --Default blend mode
  
  local time=self.time
  if time < 0 then
    love.graphics.setColor(10, 10, 10, 255);
    time = 0
  else
    love.graphics.setColor(255, 255, 255, 255);    
  end
  
  
  local text = os.date("%M:%S", time)
  local lineHeight = self.font:getHeight()
  camera:print(text, self.font, self.position.x - self.font:getWidth(text)/2, self.position.y -lineHeight/2);
  
  if self.time < 0.0 then
    if self.time > -self.explosionTime then
      love.graphics.setColor(255, 255, 255, 255);
      local radius=math.pow(-self.time/self.explosionTime, 3.0) * 3000
      love.graphics.circle("fill", self.position.x+ox, self.position.y+oy, radius, 100); -- Draw white circle with 100 segments.
    else
      love.graphics.setColor(255, 255, 255, 255);
      love.graphics.rectangle("fill", camera.offset.x, camera.offset.y, camera.size.x, camera.size.y)
    end
  end

end

function Bomb:update(dt)
  if self.disabled then
    return
  end
  
  self.time = self.time - dt
  if self.time <= 0.0 and not self.explosionSound:isPlaying() and self.time > -self.explosionTime then
    self.explosionSound:play()
  end
  
  if self.time <= -self.explosionTime and self.explosionSound:isStopped() then
    self:reset()
  end
end

return Bomb

