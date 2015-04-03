
-- Utility modules
local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Gamestate = require "gamestate"
assert(Gamestate, "Unable to load gamestate")

-- Game modules
local Player= require "player"
local Camera = require "camera"
local Bomb = require "bomb"
local Glowworm = require "glowworm"
local Button = require "button"
local Animal = require "animal"
local Dog = require "dog"
local SmallBomb = require "smallbomb"
local Lamp = require "lamp"
local Vector = require "vector"
local Jumper = require "jumper"
local Static = require "static"
local Grave = require "grave"

local introState = {}
local inGameState = {}
local endGameState = {}
local creditsState = {}

local music = {}

function music:setCurrent(music)
  if self.current then
    self.current:pause()
  end
  self.current = music
  self.current:play()
end

  
function inGameState:insertEntity(entity)
  -- Insert items that need update pulsing
  if entity.update then
    table.insert(self.updateList, entity)
  end
  
  -- Insert generic drawable items
  if entity.draw or entity.drawLayer then
    assert(entity.draw and entity.drawLayer, "Sprite-like entities need both draw and drawLayer")
    table.insert(self.drawableList, entity)
  
    -- Update layers, if needed
    table.sort(self.drawableList, function(a, b)
        local layerA = a.drawLayer or 1
        local layerB = b.drawLayer or 1
        return layerA < layerB
    end) 
  end
  
  -- Insert sprite-like items into the sprite list
  if entity.drawSprite or entity.getDepth then
    assert(entity.drawSprite and entity.getDepth, "Sprite-like entities need both drawSprite and getDepth")
    table.insert(self.spriteList, entity)
  end
  
  -- Insert all objects in the generic object list, in case we need to search
  table.insert(self.objectList, entity)
end

function inGameState:alwaysOnReset(f)
  table.insert(self.onReset, f)
end

function inGameState:onceOnReset(f)
  table.insert(self.onNextReset, f)
end


function inGameState:spawnChicken(x, y)
  local imageList={"p/huun.png", "p/huun_d.png", "p/huun_hpng.png"}
  local chicken=Animal:new(imageList[love.math.random(1, #imageList)], 30, 20)
  self:insertEntity(chicken)
  chicken:setPosition(x, y)
  self:alwaysOnReset(function() chicken:setPosition(x, y) end)
end

function inGameState:rewardSpawnChicken()
  local chickenCount = 80
  local chickenRange = 1800
  for _=1,chickenCount do
    local x=love.math.random(-chickenRange, chickenRange)
    local y=love.math.random(-chickenRange, chickenRange)
    self:spawnChicken(x, y)
  end
end

function inGameState:rewardSpawnPlants()
  local count = 1000
  local range = 1800
  local plantImage = love.graphics.newImage("p/plant.png")
  for _=1,count do
    local x=love.math.random(-range, range)
    local y=love.math.random(-range, range)
    self:insertEntity(Static:new(x, y, plantImage))
  end
end

function inGameState:rewardSpawnDog()
  
  local dogRoute = {
    {x=0, y=250},
    {x=-100, y=500},
    {x=150, y=900},
    {x=250, y=1400},
    {x=0, y=1500},
    {x=self.jumper.position.x + 60, y=self.jumper.position.y-20}
  }
  
  local dog=Dog:new(self.playerList, dogRoute)
  self:insertEntity(dog)

  self:alwaysOnReset(function() dog:reset() end)
end

function inGameState:rewardSpawnGlowWorms()
  local glowwormImage = love.graphics.newImage("p/glowworm.png")
  local glowwormCount = 240
  local glowwormRange = 2000
  for _=1,glowwormCount do
    local x=love.math.random(-glowwormRange, glowwormRange)
    local y=love.math.random(-glowwormRange, glowwormRange)
    
    self:insertEntity(Glowworm:new(x, y, glowwormImage))
  end
end

function inGameState:rewardTurnOnLamps()
  for j=1,#self.objectList do
    -- find all lamps and turn them on
    if self.objectList[j]:isInstanceOf(Lamp) then
      self.objectList[j].turnedOn = true
    end
  end
end

function inGameState:rewardAddCandleToGrave()
  for j=1,#self.objectList do
    -- find the grave
    if self.objectList[j]:isInstanceOf(Grave) then
      self.objectList[j].hasCandle = true
    end
  end
end

function inGameState:setupBombPuzzle() --6
  local px, py=-900, 900
  local button=Button:new(px, py+32, self.playerList, "p/schalt_4.png", self.buttonSound[2], {volatile=false})
  self:insertEntity(button)
  
  local smallBomb=SmallBomb:new(px+250, py+32, self.playerList)
  self:insertEntity(smallBomb)
  
  local stoneCircle=Static:new(px, py, love.graphics.newImage("p/steinkreis.png"))
  stoneCircle.depthOffset = stoneCircle.depthOffset / 2
  self:insertEntity(stoneCircle)
  
  -- Setup colliders
  self.playerList[1].ellipseCollider={x=px,y=py+32,rx=140,ry=80}
  self.playerList[2].ellipseCollider={x=px,y=py+32,rx=140,ry=80}
  
  smallBomb.onExplode = function()
    if smallBomb:inExplosionRange(stoneCircle.position) then
      stoneCircle.image = love.graphics.newImage("p/steinkreis_a.png")
      
      -- Clear colliders
      self.playerList[1].ellipseCollider=nil
      self.playerList[2].ellipseCollider=nil
    end
  end
  
  self:alwaysOnReset(function()
    stoneCircle.image = love.graphics.newImage("p/steinkreis.png")
    self.playerList[1].ellipseCollider={x=px,y=py+32,rx=140,ry=80}
    self.playerList[2].ellipseCollider={x=px,y=py+32,rx=140,ry=80}
    smallBomb:reset()
  end)
  
  button.stateChanged = function()
    self:onceOnReset(self.rewardSpawnGlowWorms)
  
    self.puzzlesSolved = self.puzzlesSolved + 1
  end
end

function inGameState:setupTwoButtonPuzzle() --1
  local button1=Button:new(100, 200, self.playerList, "p/schalt_4.png", self.buttonSound[1])
  self:insertEntity(button1)

  local button2=Button:new(-100, 200, self.playerList, "p/schalt_4.png", self.buttonSound[1])
  self:insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      self:onceOnReset(self.rewardSpawnDog)      
        
      self.puzzlesSolved = self.puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function inGameState:setupTwoButtonPuzzleAtEdge() --4
  local button1=Button:new(900, -1800, self.playerList, "p/schalt_4.png", self.buttonSound[1])
  self:insertEntity(button1)

  local button2=Button:new(-1500, 1500, self.playerList, "p/schalt_4.png", self.buttonSound[1])
  self:insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      self:onceOnReset(self.rewardSpawnPlants) 
        
      self.puzzlesSolved = self.puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function inGameState:setupTwoButtonFurtherPuzzle() --5
  local button1=Button:new(-1800, -1800, self.playerList, "p/schalt_4.png", self.buttonSound[1])
  self:insertEntity(button1)

  local button2=Button:new(1800, -1800, self.playerList, "p/schalt_4.png", self.buttonSound[1])
  self:insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      self:onceOnReset(self.rewardSpawnChicken) 
        
      self.puzzlesSolved = self.puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function inGameState:setupLongDistancePuzzle() --2
  
  local button=Button:new(0, -900, self.playerList, "p/schalt_1.png", self.buttonSound[2], {volatile=false})
  self:insertEntity(button)
  
  local deactivatedButton=Button:new(0, 900, self.playerList, "p/schalt_4.png", self.buttonSound[1], {volatile=false})
  self:insertEntity(deactivatedButton)
  deactivatedButton.locked=true
  
  button.stateChanged = function()
    deactivatedButton.locked=false
  end
  
  self:alwaysOnReset(function()
    button.activated=false
    deactivatedButton.locked=true
  end)
  
  deactivatedButton.stateChanged = function()
    self:onceOnReset(self.rewardAddCandleToGrave)
    self.puzzlesSolved = self.puzzlesSolved + 1
  end
end

function inGameState:setupLongDistancePuzzleGrave() -- not Grave anymore -- 3 -- sry
  
  local button=Button:new(-1500, -1800, self.playerList, "p/schalt_1.png", self.buttonSound[2], {volatile=false})
  self:insertEntity(button)
  
  local deactivatedButton=Button:new(0, 1200, self.playerList, "p/schalt_4.png", self.buttonSound[1], {volatile=false})
  self:insertEntity(deactivatedButton)
  deactivatedButton.locked=true
  
  button.stateChanged = function()
    deactivatedButton.locked=false
  end
  
  self:alwaysOnReset(function()
    button.activated=false
    deactivatedButton.locked=true
  end)
  
  deactivatedButton.stateChanged = function()
    self:onceOnReset(self.rewardTurnOnLamps)
    self.puzzlesSolved = self.puzzlesSolved + 1
  end
end

function inGameState:resetGame()
  self.playerList[1]:setPosition(-130, 0)
  self.playerList[2]:setPosition(130, 0)
  self.cameraList[1]:setPosition(0, 0)
  self.cameraList[2]:setPosition(0, 0)
  
  local resetList = self.onNextReset
  self.onNextReset={}
  
  for i=1,#resetList do
    resetList[i](self)
  end
  
  for i=1,#self.onReset do
    self.onReset[i](self)
  end
end

function inGameState:spawnStatics()
  local imageFileList={
    "p/bird_dead_l.png",
    "p/bird_dead_r.png",
    "p/flash_l.png",
    "p/flash_r.png",
    "p/flash_u.png",
    "p/paper_l.png",
    "p/paper_r.png",
    "p/plant.png",
    "p/stein1.png",
    "p/stein2.png",
    "p/stein3.png"
  }
  local imageList={}
  for i=1,#imageFileList do
    table.insert(imageList, love.graphics.newImage(imageFileList[i]))
  end
  
  local objectCount = 140
  local objectRange = 1900
  for _=1,objectCount do
    local x=love.math.random(-objectRange, objectRange)
    local y=love.math.random(-objectRange, objectRange)
    
    self:insertEntity(Static:new(x, y, imageList[love.math.random(1, #imageList)]))
  end
end

function inGameState:checkEnd(player)
  local maxDistance=120
  local squareDistance=Vector.squareDistance(player.position, self.jumper.position)
  
  if self.puzzlesSolved < self.puzzleCount then
    return
  end
  
  if squareDistance > maxDistance*maxDistance then
    return
  end
  
  -- Don't end if the jumper is already jumping
  if not self.jumper.animation.stopped then
    return
  end
  
  -- Start the finish hug
  player.autoTarget = {x=self.jumper.position.x+player.hugOffset, y=self.jumper.position.y}
  player.autoTargetFinished = function()
    self.jumper.hide=true
    player:hug()
    self.bomb.disabled=true
    player.huggingFinished = function() Gamestate.switch(endGameState) end
  end
end

function introState:load()
  self.introMusic = love.audio.newSource("s/Intro.mp3")
  self.introMusic:setLooping(true)
  
  self.introImageList = {
    love.graphics.newImage("p/intro_1.png"),
    love.graphics.newImage("p/intro_2.png"),
    love.graphics.newImage("p/intro_3.png"),
    love.graphics.newImage("p/intro_4.png")
  }
end

function introState:enter()
  self.timer = 0.0
  self.frame = 1
  self.introMusic:rewind()
  music:setCurrent(self.introMusic)
end

function introState:update(dt)
  self.timer = self.timer + dt
  if self.timer > 0.05 then
    self.timer = 0
    self.frame = self.frame + 1
    if self.frame > #self.introImageList then
      self.frame = 1
    end
  end
end

function introState:keypressed()
  Gamestate.switch(inGameState)
end

function introState:draw()
  love.graphics.setScissor()
  love.graphics.draw(self.introImageList[self.frame], 0, 0)    
end

function inGameState:setupCameraSizes(w, h)
  self.cameraList[1]:resize(0, 0, w/2, h)
  self.cameraList[2]:resize(w/2, 0, w/2, h)
end

function love.load(arg)
  -- Enable debugging
  if arg[#arg] == "-debug" then
    require("mobdebug").start()
  end   
  
  inGameState:load()  
  introState:load()
  creditsState:load()  
  
  inGameState:newGame()

  Gamestate.registerEvents()
  Gamestate.switch(introState)
end

function inGameState:load()
  self.backgroundTexture=love.graphics.newImage("p/sand_grey.jpg")
    
  self.backgroundMusic = love.audio.newSource("s/Main.mp3")
  self.backgroundMusic:setLooping(false)
end

function inGameState:newGame() 
  self.updateList = {}
  self.drawableList = {}
  self.spriteList = {}
  self.objectList = {}
  self.onNextReset = {}
  self.onReset = {}
  self.cameraList = {}

  -- Create players here
  self.playerList = {
    Player:new("p/typin_p.png", "p/typin_dead.png", "p/hug_f.png", 64),
    Player:new("p/typ_blond.png", "p/typ_blond_dead.png", "p/hug_m.png", 64)
  }

  self.cameraList = {
    Camera:new(),
    Camera:new()
  }
  
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  self:setupCameraSizes(width, height)

  for i=1,#self.playerList do
    self:insertEntity(self.playerList[i])
  end

  for i=1,#self.cameraList do
    table.insert(self.updateList, self.cameraList[i])
  end
  
  local joystickList = love.joystick.getJoysticks()
  
  self.playerList[1]:setJoystick(joystickList[1])
  self.playerList[2]:setJoystick(joystickList[2])
  self.playerList[1]:setKeys({'w', 'a', 's', 'd', 'q'})
  self.playerList[2]:setKeys({'i', 'j', 'k', 'l', 'u'})
    
  local cameraDistance = 100
  self.cameraList[1]:setFollowTargets(self.playerList[1], self.playerList[2], cameraDistance)
  self.cameraList[2]:setFollowTargets(self.playerList[2], self.playerList[1], cameraDistance)

  -- Add the bomb
  self.bomb=Bomb:new(function() self:resetGame() end)
  self:insertEntity(self.bomb)

  -- Add Lamps
  local lampImage = love.graphics.newImage("p/lamp.png")
  local lampImageGlow = love.graphics.newImage("p/lamp_glow.png")
  local lampPositions = {
    {768,0}, {-768,0}, {0,768}, {0,-768}, 
    {-1024, -1024}, {-1024,1024}, {1024,1024},{1024,-1024},
  }
  for i=1,#lampPositions do
    self:insertEntity(Lamp:new(lampPositions[i][1], lampPositions[i][2], lampImage, lampImageGlow))
  end

  -- Add Grave
  self:insertEntity(Grave:new(-300, -100))
  
  -- Add the suicidal person
  self.jumper=Jumper:new(love.math.random(-300, 300), 2000)
  self:insertEntity(self.jumper)
  self:alwaysOnReset(function() self.jumper:reset() end)

  
  self.puzzlesSolved = 0
  
  self.buttonSound = {
    "s/Butt.wav",
    "s/Schalt.mp3"
  }
  
  --spawnChicken()
  self:spawnStatics()
  
  self:resetGame()
  self:setupBombPuzzle()
  self:setupTwoButtonPuzzle()
  self:setupTwoButtonPuzzleAtEdge()
  self:setupLongDistancePuzzle()
  self:setupLongDistancePuzzleGrave()
  self:setupTwoButtonFurtherPuzzle()
  self.puzzleCount=6
    
  self:alwaysOnReset(function() 
    self.backgroundMusic:rewind()
    music:setCurrent(self.backgroundMusic)
  end)
end


function inGameState:enter()
  music:setCurrent(self.backgroundMusic)
end


function inGameState:update(dt)
  for j=1,#self.updateList do
    self.updateList[j]:update(dt)
  end

  -- Update sprite depth
  table.sort(self.spriteList, function(a, b) return a:getDepth() < b:getDepth() end)
  
  -- check for game end
  for i=1,#self.playerList do
    self:checkEnd(self.playerList[i])
  end  
end

function inGameState:keypressed(key)
  if key == "escape" then
    Gamestate.switch(introState)
  end  
end

function inGameState:draw()
  
  for i=1,#self.cameraList do
    self.cameraList[i]:setScissor()
    love.graphics.setColor(64, 64, 64)
    
    -- Draw background
    self.cameraList[i]:draw(self.backgroundTexture, -2048, -2048)
    
    -- Draw sprites
    for j=1,#self.spriteList do
      self.spriteList[j]:drawSprite(self.cameraList[i])
    end
  
    -- Draw other stuff
    for j=1,#self.drawableList do
      self.drawableList[j]:draw(self.cameraList[i])
    end
  end
  love.graphics.setScissor()
end

function endGameState:enter()
  self.fade = 0
end

function endGameState:update(dt)  
  self.fade = math.min(self.fade + dt*0.13, 1.0)  
  if self.fade >= 1.0 then
    Gamestate.switch(creditsState)
  end
end

function endGameState:draw()
  inGameState:draw()
  love.graphics.setScissor()
  love.graphics.setColor(255, 255, 255, 255*self.fade)
  love.graphics.draw(creditsState.notTheEndImage, 0, 0)
end

-- Credit state
function creditsState:load()
  self.notTheEndImage = love.graphics.newImage("p/not_end_cred.png")
  self.creditsMusic = love.audio.newSource("s/End.mp3")
  self.creditsMusic:setLooping(true)
end


function creditsState:enter()
  self.creditsMusic:rewind()
  music:setCurrent(self.creditsMusic)
  self.slide=0
  self.maxSlide=self.notTheEndImage:getHeight() - love.graphics.getHeight()
end

function creditsState:update(dt)
  self.slide=math.min(self.maxSlide, self.slide + dt*60)
end

function creditsState:draw()
  love.graphics.setScissor()
  love.graphics.draw(self.notTheEndImage, 0, -self.slide)
end

function creditsState:keypressed()
  if self.slide >= self.maxSlide then
    inGameState:newGame() -- start a completely new game
    Gamestate.switch(introState)
  end
end
  