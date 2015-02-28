
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
local Door = require "door"
local Animal = require "animal"
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

updateList = {}
drawableList = {}
onNextReset = {}
onReset = {}
cameraList = {}
  
local function insertEntity(entity)
  if entity.update then
    table.insert(updateList, entity)
  end
  if entity.draw then
    table.insert(drawableList, entity) 
  end
end

local function alwaysOnReset(f)
  table.insert(onReset, f)
end

function setupGame()
  -- Create players here
  playerList = {
    Player:new("p/typin_p.png", "p/typin_dead.png", "p/hug_f.png", 64),
    Player:new("p/typ_blond.png", "p/typ_blond_dead.png", "p/hug_m.png", 64)
  }

  cameraList = {
    Camera:new(),
    Camera:new()
  }

  for i=1,#playerList do
    insertEntity(playerList[i])
  end

  for i=1,#cameraList do
    table.insert(updateList, cameraList[i])
  end

  -- Add the bomb
  bomb=Bomb:new()
  insertEntity(bomb)

  -- Add Lamps
  local lampImage = love.graphics.newImage("p/lamp.png")
  local lampImageGlow = love.graphics.newImage("p/lamp_glow.png")
  local lampPositions = {
    {768,0}, {-768,0}, {0,768}, {0,-768}, 
    {-1024, -1024}, {-1024,1024}, {1024,1024},{1024,-1024},
  }
  for i=1,#lampPositions do
    insertEntity(Lamp:new(lampPositions[i][1], lampPositions[i][2], lampImage, lampImageGlow))
  end

  -- Add Grave
  insertEntity(Grave:new(-300, -100))
  
  -- Add the suicidal person
  jumper=Jumper:new(love.math.random(-300, 300), 2000)
  insertEntity(jumper)
  alwaysOnReset(function() jumper:reset() end)
  
  puzzlesSolved = 0

end

function spawnChicken(x, y)
  local imageList={"p/huun.png", "p/huun_d.png", "p/huun_hpng.png"}
  local chicken=Animal:new(imageList[love.math.random(1, #imageList)], 30, 20)
  insertEntity(chicken)
  chicken:setPosition(x, y)
  alwaysOnReset(function() chicken:setPosition(x, y) end)
end

function rewardSpawnChicken()
  local chickenCount = 80
  local chickenRange = 1800
  for i=1,chickenCount do
    local x=love.math.random(-chickenRange, chickenRange)
    local y=love.math.random(-chickenRange, chickenRange)
    spawnChicken(x, y)
  end
end

function rewardSpawnPlants()
  local count = 1000
  local range = 1800
  local plantImage = love.graphics.newImage("p/plant.png")
  for i=1,count do
    local x=love.math.random(-range, range)
    local y=love.math.random(-range, range)
    insertEntity(Static:new(x, y, plantImage))
  end
end

function rewardSpawnDog()
  local dog=Animal:new("p/bestdog.png", 60, 100)
  insertEntity(dog)
  dog:setPosition(200, 200) 
  alwaysOnReset(function() dog:setPosition(200, 200) end)
end

function rewardSpawnGlowWorms()
  glowwormImage = love.graphics.newImage("p/glowworm.png")
  local glowwormCount = 240
  local glowwormRange = 2000
  for i=1,glowwormCount do
    local x=love.math.random(-glowwormRange, glowwormRange)
    local y=love.math.random(-glowwormRange, glowwormRange)
    
    insertEntity(Glowworm:new(x, y, glowwormImage))
  end
end

function rewardTurnOnLamps()
  for j=1,#updateList do
    -- find all lamps and turn them on
    if updateList[j]:isInstanceOf(Lamp) then
      updateList[j].turnedOn = true
    end
  end
end

function rewardAddCandleToGrave()
  for j=1,#updateList do
    -- find the grave
    if updateList[j]:isInstanceOf(Grave) then
      updateList[j].hasCandle = true
    end
  end
end

function setupBombPuzzle() --6
  local px, py=-900, 900
  local button=Button:new(-20+px, -260+py, playerList, "p/schalt_4.png", buttonSound[2], {volatile=false, pressTime=2.0})
  insertEntity(button)
  
  local smallBomb=SmallBomb:new(30+px, -230+py, playerList)
  insertEntity(smallBomb)
  smallBomb.onExplode = function()
    if smallBomb:inExplosionRange(button.position) then
      button:hide()
    end
  end
  
  alwaysOnReset(function()
    button:show()
    smallBomb:reset()
  end)
  
  button.stateChanged = function()
    table.insert(onNextReset, rewardSpawnGlowWorms)
  
    puzzlesSolved = puzzlesSolved + 1
  end
end

function setupTwoButtonPuzzle() --1
  local button1=Button:new(100, 200, playerList, "p/schalt_4.png", buttonSound[1])
  insertEntity(button1)

  local button2=Button:new(-100, 200, playerList, "p/schalt_4.png", buttonSound[1])
  insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      rewardAddCandleToGrave()

      table.insert(onNextReset, function()
      end) 
        
      puzzlesSolved = puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function setupTwoButtonPuzzleAtEdge() --4
  local button1=Button:new(900, -1800, playerList, "p/schalt_4.png", buttonSound[1])
  insertEntity(button1)

  local button2=Button:new(-1500, 1500, playerList, "p/schalt_4.png", buttonSound[1])
  insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      table.insert(onNextReset, function()
        rewardSpawnPlants()
      end) 
        
      puzzlesSolved = puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function setupTwoButtonFurtherPuzzle() --5
  local button1=Button:new(-1800, -1800, playerList, "p/schalt_4.png", buttonSound[1])
  insertEntity(button1)

  local button2=Button:new(1800, -1800, playerList, "p/schalt_4.png", buttonSound[1])
  insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      table.insert(onNextReset, rewardSpawnChicken) 
        
      puzzlesSolved = puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function setupLongDistancePuzzle() --2
  
  local button=Button:new(0, -900, playerList, "p/schalt_1.png", buttonSound[2], {volatile=false})
  insertEntity(button)
  
  local door=Door:new(0, 900, playerList)
  insertEntity(door)
  door.locked=true
  
  button.stateChanged = function()
    door.locked=false
  end
  
  alwaysOnReset(function()
    button.activated=false
    door.locked=true
  end)
  
  door.stateChanged = function()
    table.insert(onNextReset, function()
      rewardSpawnDog()
    end)
    puzzlesSolved = puzzlesSolved + 1
  end
end

function setupLongDistancePuzzleGrave() -- not Grave anymore -- 3 -- sry
  
  local button=Button:new(-1500, -1800, playerList, "p/schalt_1.png", buttonSound[2], {volatile=false})
  insertEntity(button)
  
  local door=Door:new(0, 1200, playerList)
  insertEntity(door)
  door.locked=true
  
  button.stateChanged = function()
    door.locked=false
  end
  
  alwaysOnReset(function()
    button.activated=false
    door.locked=true
  end)
  
  door.stateChanged = function()
    table.insert(onNextReset, function()
      
      rewardTurnOnLamps()
    end)
    puzzlesSolved = puzzlesSolved + 1
  end
end

function resetGame()
  playerList[1]:setPosition(-130, 0)
  playerList[2]:setPosition(130, 0)
  cameraList[1]:setPosition(0, 0)
  cameraList[2]:setPosition(0, 0)
  
  local resetList = onNextReset
  onNextReset={}
  
  for i=1,#resetList do
    resetList[i]()
  end
  
  for i=1,#onReset do
    onReset[i]()
  end
end

function spawnStatics()
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
  for i=1,objectCount do
    local x=love.math.random(-objectRange, objectRange)
    local y=love.math.random(-objectRange, objectRange)
    
    insertEntity(Static:new(x, y, imageList[love.math.random(1, #imageList)]))
  end
end

function checkEnd(player)
  local maxDistance=120
  local squareDistance=Vector.squareDistance(player.position, jumper.position)
  
  if puzzlesSolved < puzzleCount then
    return
  end
  
  if squareDistance > maxDistance*maxDistance then
    return
  end
  
  player.autoTarget = {x=jumper.position.x+player.hugOffset, y=jumper.position.y}
  player.autoTargetFinished = function()
    jumper.hide=true
    player:hug()
    bomb.disabled=true
    player.huggingFinished = function() Gamestate.switch(endGameState) end
  end
end

function introState:enter()
  self.timer = 0.0
  self.frame = 1
  introMusic:rewind()
  music:setCurrent(introMusic)
end

function introState:update(dt)
  self.timer = self.timer + dt
  if self.timer > 0.05 then
    self.timer = 0
    self.frame = self.frame + 1
    if self.frame > #introImageList then
      self.frame = 1
    end
  end
end

function introState:keypressed(key, isrepeat)
  Gamestate.switch(inGameState)
end

function introState:draw()
  love.graphics.setScissor()
  love.graphics.draw(introImageList[self.frame], 0, 0)    
end

function setupCameraSizes(w, h)
  cameraList[1]:resize(0, 0, w/2, h)
  cameraList[2]:resize(w/2, 0, w/2, h)
end

function love.load(arg)
  -- Enable debugging
  if arg[#arg] == "-debug" then
    require("mobdebug").start()
  end
  
  setupGame()
  
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  setupCameraSizes(width, height)
  
  introImageList = {
    love.graphics.newImage("p/intro_1.png"),
    love.graphics.newImage("p/intro_2.png"),
    love.graphics.newImage("p/intro_3.png"),
    love.graphics.newImage("p/intro_4.png")
  }
  
  notTheEndImage = love.graphics.newImage("p/not_end.png")
  creditsImage = love.graphics.newImage("p/credits.png")
  theEndImage = love.graphics.newImage("p/end.png")
    
  local joystickList = love.joystick.getJoysticks()
  
  playerList[1]:setJoystick(joystickList[1])
  playerList[2]:setJoystick(joystickList[2])
  playerList[1]:setKeys({'w', 'a', 's', 'd', 'q'})
  playerList[2]:setKeys({'i', 'j', 'k', 'l', 'u'})
    
  local cameraDistance = 100
  cameraList[1]:setFollowTargets(playerList[1], playerList[2], cameraDistance)
  cameraList[2]:setFollowTargets(playerList[2], playerList[1], cameraDistance)
  
  backgroundTexture=love.graphics.newImage("p/sand_grey.jpg")
    
  backgroundMusic = love.audio.newSource("s/Main.mp3")
  backgroundMusic:setLooping(false)
  
  introMusic = love.audio.newSource("s/Intro.mp3")
  introMusic:setLooping(true)
  
  creditsMusic = love.audio.newSource("s/End.mp3")
  creditsMusic:setLooping(true)
  
  
  buttonSound = {
    "s/Butt.wav",
    "s/Schalt.mp3"
  }
  
  --spawnChicken()
  spawnStatics()
  
  resetGame()
  setupBombPuzzle()
  setupTwoButtonPuzzle()
  setupTwoButtonPuzzleAtEdge()
  setupLongDistancePuzzle()
  setupLongDistancePuzzleGrave()
  setupTwoButtonFurtherPuzzle()
  puzzleCount=6
    
  alwaysOnReset(function() 
    backgroundMusic:rewind()
    music:setCurrent(backgroundMusic)
  end)
  Gamestate.registerEvents()
  Gamestate.switch(introState)
end

function inGameState:enter()
  music:setCurrent(backgroundMusic)
end


function inGameState:update(dt)
  for j=1,#updateList do
    updateList[j]:update(dt)
  end
  
  -- check for game end
  for i=1,#playerList do
    checkEnd(playerList[i])
  end  
end

function inGameState:keypressed(key, isrepeat)
  if key == "escape" then
    Gamestate.switch(introState)
  end  
end

function inGameState:draw()
  table.sort(drawableList, function(a, b)
      local layerA = a.drawLayer or 1
      local layerB = b.drawLayer or 1
      return layerA < layerB
  end)
  
  for i=1,#cameraList do
    cameraList[i]:setScissor()
    love.graphics.setColor(64, 64, 64)
    
    cameraList[i]:draw(backgroundTexture, -2048, -2048)
    for j=1,#drawableList do
      drawableList[j]:draw(cameraList[i])
    end
  end
  love.graphics.setScissor()
end

function endGameState:enter()
  self.fade = 0
end

function endGameState:update(dt)  
  self.fade = math.min(self.fade + dt*0.1, 1.0)   
end

function endGameState:draw()
  inGameState:draw()
  love.graphics.setScissor()
  love.graphics.setColor(255, 255, 255, 255*self.fade)
  love.graphics.draw(notTheEndImage, 0, 0)
end

function endGameState:keypressed(key, isrepeat)
  if self.fade > 0.8 then
    Gamestate.switch(creditsState)
  end
end

function creditsState:enter()
  creditsMusic:rewind()
  music:setCurrent(creditsMusic)
end

function creditsState:draw()
  love.graphics.setScissor()
  love.graphics.draw(creditsImage, 0, 0)
end

function creditsState:keypressed(key, isrepeat)
  Gamestate.switch(introState)
end
  