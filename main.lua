
local class = require "middleclass"
assert(class, "Unable to load middleclass")

local Player= require "Player"
local Camera = require "Camera"
local Bomb = require "Bomb"
local Glowworm = require "Glowworm"
local Button = require "Button"
local Door = require "Door"
local Animal = require "Animal"
local SmallBomb = require "SmallBomb"
local Lamp = require "Lamp"
local Vector = require "Vector"
local Jumper = require "Jumper"
local Static = require "Static"


updateList = {}
drawableList = {}
onNextReset = {}
onReset = {}
  
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

function rewardSpawnDog()
  local dog=Animal:new("p/bestDog.png", 60, 100)
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

function setupBombPuzzle()
  local px, py=-300,-500
  local button=Button:new(-20+px, -260+py, playerList, true, false, "p/schalt_4.png", 2.0)
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

function setupTwoButtonPuzzle()
  local button1=Button:new(500, 500, playerList, true, true, "p/schalt_4.png")
  insertEntity(button1)

  local button2=Button:new(600, 500, playerList, true, true, "p/schalt_4.png")
  insertEntity(button2)
  
  local function stateChanged()
    if button1.activated and button2.activated then
      button1.locked=true
      button2.locked=true

      rewardTurnOnLamps()

      table.insert(onNextReset, function()
      end) 
        
      puzzlesSolved = puzzlesSolved + 1
    end
  end
  
  button1.stateChanged = stateChanged
  button2.stateChanged = stateChanged
end

function setupTwoButtonFurtherPuzzle()
  local button1=Button:new(-220, -1400, playerList, true, true, "p/schalt_4.png")
  insertEntity(button1)

  local button2=Button:new(400, -1200, playerList, true, true, "p/schalt_4.png")
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

function setupLongDistancePuzzle()
  
  local button=Button:new(1100, -1300, playerList, true, false, "p/schalt_1.png")
  insertEntity(button)
  
  local door=Door:new(-1500, 1300, playerList)
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
      spawnDogReward()
    end)
    puzzlesSolved = puzzlesSolved + 1
  end
end

function resetGame()
  backgroundMusic:play()
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

function love.resize(w, h)
  cameraList[1]:resize(0, 0, w/2, h)
  cameraList[2]:resize(w/2, 0, w/2, h)
end

function love.load(arg)
  -- Enable debugging
  if
    arg[#arg] == "-debug" then require("mobdebug").start()
  end
  
  setupGame()
  
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  love.resize(width, height)
  
  
  local joystickList = love.joystick.getJoysticks()
  
  playerList[1]:setJoystick(joystickList[1])
  playerList[2]:setJoystick(joystickList[2])
  playerList[1]:setKeys({'w', 'a', 's', 'd', 'q'})
  playerList[2]:setKeys({'up', 'left', 'down', 'right', 'rctrl'})
    
  local cameraDistance = 100
  cameraList[1]:setFollowTargets(playerList[1], playerList[2], cameraDistance)
  cameraList[2]:setFollowTargets(playerList[2], playerList[1], cameraDistance)
  
  backgroundTexture=love.graphics.newImage("p/sand_grey.png")
    
  backgroundMusic = love.audio.newSource("s/Main_ looperman-l-1327367-0079222-roadwarrior-its-not-the-same-without-you-sad-piano.wav")

  --spawnChicken()
  spawnStatics()
  
  resetGame()
  setupBombPuzzle()
  setupTwoButtonPuzzle()
  setupLongDistancePuzzle()
  setupTwoButtonFurtherPuzzle()
end

function checkEnd(player)
  local maxDistance=120
  local squareDistance=Vector.squareDistance(player.position, jumper.position)
  
  if puzzlesSolved < 4 then
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
  end
end

function love.update(dt)
  for j=1,#updateList do
    updateList[j]:update(dt)
  end
  
  -- check for game end
  for i=1,#playerList do
    checkEnd(playerList[i])
  end
end

function love.draw()
  
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

