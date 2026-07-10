local A     = require("src.assets")
local State = require("src.state")
local Chests = require("data.chests")

local Gacha = {}


local SWING_DURATION   = 2   -- seconds of spotlight swing / chest bounce-in
local BURST_DURATION   = 0.7  -- star flash + particle pop-off before reveal settles
local HEART_DELAY      = 0.8 -- seconds after the star burst fires before hearts follow
local RADIAL_SPEED     = 0.6   -- radians/sec, constant rotation behind prize
local RESTING_ANGLE    = math.rad(-25) -- final spotlight angle, converging \/ on chest
local SWING_PEAKS      = {
  { t = 0.00, mul = -4 },  -- /\ 
  { t = 0.40, mul = 3 },  -- \/
  { t = 0.80, mul = -3 }, -- /\
  { t = 1.20, mul = 2 },  -- \/
  { t = 1.60, mul = 1.0  }, -- \/  final rest at RESTING_ANGLE
}
 
local PRIZE_SIZE   = 150
local PRIZE_BORDER = 10

local RARITY_STYLE = {
  limited = { bg = {1, 0.8, 0.2},   border = {0.95, 0.5, 0.15}, label = "Limited" },
  special = { bg = {1, 0.78, 0.97}, border = {0.62, 0.32, 0.9}, label = "Special" },
  hot     = { bg = {0.72, 0.88, 1.0}, border = {0.25, 0.6, 0.95}, label = "Hot" },
}

local phase       = nil     -- nil until Gacha.start() is called
local t           = 0       -- phase-local clock
local burstClock  = 0       -- persists across burst -> reveal, drives one-shot emissions
local starsFired  = false
local heartsFired = false
local chest       = nil     -- chest data (from Chests[chestIndex])
local prize       = nil     -- rolled pool entry {id, rarity, label, weight}
local sw, sh      = love.graphics.getDimensions()
local chestCX, chestCY = sw/2, sh/2 + 90
local radialAngle = 0
local starPS, heartPS = nil, nil
local onDone      = nil     -- callback(prize) fired when player taps past reveal

local function weightedPick(pool)
  local total = 0
  for _, e in ipairs(pool) do total = total + e.weight end
  local roll = love.math.random() * total
  local acc = 0
  for _, e in ipairs(pool) do
    acc = acc + e.weight
    if roll <= acc then return e end
  end
  return pool[#pool] -- float safety fallback
end

local function buildParticleSystems()
  starPS = love.graphics.newParticleSystem(A.ui.confetti2, 1000)
  starPS:setParticleLifetime(1.5, 2)
  starPS:setEmissionRate(100)
  starPS:setEmitterLifetime(1)
  starPS:setSpeed(500, 700)
  starPS:setLinearAcceleration(-800,100, 800, 600)
  starPS:setLinearDamping(1.8)
  starPS:setSpread(math.pi * 5)
  starPS:setRotation(0, math.pi * 2)
  starPS:setSpin(-6, 6)
  starPS:setSizes(0.2, 0.15, 0.1)
  starPS:setSizeVariation(1)
  starPS:setColors(1, 1, 1, 0.4,  1, 1, 1, 0.4,  1, 1, 1, 0)

  heartPS = love.graphics.newParticleSystem(A.ui.confetti1, 100)
  heartPS:setParticleLifetime(2)
  heartPS:setEmissionRate(0)
  heartPS:setSpeed(490, 500)
  heartPS:setLinearDamping(1.7)
  heartPS:setSpread(math.pi * 2)
  heartPS:setSizes(0.1, 0.12, 0.08)
  heartPS:setSizeVariation(0.15)
  heartPS:setColors(1, 0.6, 1, 0.2,  1, 0.6, 1, 0.2,  1, 0.6, 1, 0.1)
end

local function easeOutCubic(x)
  return 1 - (1 - x)^3
end

local function fireStars()
  starPS:setPosition(chestCX, sh/2)
  starPS:reset()
  starPS:emit(250)
end
 
local function fireHearts()
  heartPS:setPosition(chestCX, sh/2)
  heartPS:reset()
  heartPS:emit(50)
end
 
local function updateBurst(dt)
  if starPS then starPS:update(dt) end
  if heartPS then heartPS:update(dt) end
end
 
local function drawBurst()
  if starPS then love.graphics.draw(starPS) end
  if heartPS then love.graphics.draw(heartPS) end
end
 

function Gacha.start(chestIndex, doneCallback)
  chest = Chests[chestIndex]
  if not chest then return false, "invalid chest" end
 
  if not State.canAfford(chest.price) then
    return false, "insufficient funds"
  end
 
  State.spend(chest.price)
  prize = weightedPick(chest.pool)
 
  phase = "bounce"
  t = 0
  burstClock = 0
  starsFired = false
  heartsFired = false
  radialAngle = 0
  onDone = doneCallback
 
  if not starPS then buildParticleSystems() end
 
  return true
end

function Gacha.isActive()
  return phase ~= nil
end

local function spotlightAngle(f)
  for i = 1, #SWING_PEAKS - 1 do
    local a, b = SWING_PEAKS[i], SWING_PEAKS[i+1]
    if f >= a.t and f <= b.t then
      local local_f = (f - a.t) / (b.t - a.t)
      local eased = easeOutCubic(local_f)
      local mul = a.mul + (b.mul - a.mul) * eased
      return RESTING_ANGLE * mul
    end
  end
  return RESTING_ANGLE
end

function Gacha.update(dt)
  if not phase then return end
  t = t + dt
 
  if phase == "bounce" then
    if t >= SWING_DURATION+1 then
      phase = "burst"
      t = 0
      burstClock = 0
    end
 
  elseif phase == "burst" then
    burstClock = burstClock + dt
    if not starsFired then
      fireStars()
      starsFired = true
    end
    if t >= BURST_DURATION then
      phase = "reveal"
      t = 0
    end
 
  elseif phase == "reveal" then
    burstClock = burstClock + dt
    if not heartsFired and burstClock >= HEART_DELAY then
      fireHearts()
      heartsFired = true
    end
    updateBurst(dt) -- let remaining particles finish drifting/fading
  end
 
  radialAngle = radialAngle + RADIAL_SPEED * dt
end

function Gacha.tap()
  if phase == "reveal" and t > 0.15 then -- small guard vs. the tap that opened it
    local p = prize
    phase = nil
    if onDone then onDone(p) end
  end
end

local function drawSpotlights(f)
  local ang = spotlightAngle(f)
  local img = A.ui.spotlight
  local iw, ih = img:getDimensions()

  -- left spotlight: anchored top-left-ish, tilts right (+ang) toward chest
  love.graphics.setColor(1, 1, 1, 0.55)
  love.graphics.draw(img, chestCX - 400, -20, ang, 1, 1, iw/2, 0)

  -- right spotlight: mirrored, tilts left (-ang) toward chest
  love.graphics.draw(img, chestCX + 400, -20, -ang, 1, 1, iw/2, 0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(f)
end

local function drawChest(t)
  local imgs = A.chests[chest.id]
  local iw, ih = imgs.chest:getDimensions()

  local progress = t / 2

  local wobble = math.sin(t / 0.3 * math.pi)

  local scaleX = 1.3 - progress*0.3 * wobble
  local scaleY = 1.3 + progress*0.3 * wobble

  -- illuminated by spotlight
  local light = math.abs(math.sin((t or 0) * 2))
  love.graphics.setColor(light, light, light)

  love.graphics.draw(imgs.chest, chestCX, chestCY, 0,
    scaleX, scaleY, iw/2, ih/2)
  love.graphics.setColor(1,1,1)
end

local function drawRadial()
  local img = A.ui.radial
  local iw, ih = img:getDimensions()
  love.graphics.setColor(1,1,1,0.9)
  love.graphics.draw(img, sw/2, sh/2, radialAngle, 1, 1, iw/2, ih/2)
end

local function drawWhiteFlash(f)
  local img = A.ui.confetti2
  local progress = math.min(easeOutCubic(f), 1)
  local x, y = sw / 2, sh / 2
  local iw, ih = img:getDimensions()

  local scale1 = progress * 6
  local scale2 = progress * 11

  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.draw(img, x, y, 0, scale1, scale1, iw / 2, ih / 2)
  love.graphics.draw(img, x, y, 0, scale2, scale2, iw / 2, ih / 2)
  love.graphics.setColor(1, 1, 1, 1)
end

local function drawPrizeFramed()
  local style = RARITY_STYLE[prize.rarity]
  local x = sw/2 - PRIZE_SIZE/2
  local y = sh/2 - PRIZE_SIZE/2

  drawRadial()

  love.graphics.setColor(style.border)
  love.graphics.rectangle("fill", x, y, PRIZE_SIZE, PRIZE_SIZE, 10, 10)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle("fill",
    x + PRIZE_BORDER, y + PRIZE_BORDER,
    PRIZE_SIZE - PRIZE_BORDER*2, PRIZE_SIZE - PRIZE_BORDER*2, 7, 7)

  local img = A.prizes[prize.id]
  if img then
    local iw, ih = img:getDimensions()
    local inner = PRIZE_SIZE - PRIZE_BORDER * 2
    local s  = math.max(inner/iw, inner/ih)
    local ox = (inner - iw*s) / 2
    local oy = (inner - ih*s) / 2
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(img, x + PRIZE_BORDER + ox, y + PRIZE_BORDER + oy, 0, s, s)
  end
  love.graphics.setColor(1,1,1,1)

  -- ribbon beneath, original size, rarity label in A.font.lg
  local ribbon = A.ui.ribbon
  if ribbon then
    local rw, rh = ribbon:getDimensions()
    local rx, ry = chestCX, y + PRIZE_SIZE + rh/2 + 6
    love.graphics.draw(ribbon, rx, ry, 0, 1, 1, rw/2, rh/2)

    love.graphics.setFont(A.font.lg)
    love.graphics.setColor(1,1,1,1)
    local label = style.label
    local tw = A.font.lg:getWidth(label)
    love.graphics.print(label, rx - tw/2, ry - A.font.lg:getHeight()/2)
  end
end

function Gacha.draw()
  if not phase then return end
  love.graphics.draw(A.ui.background, 0, 0, 0, sw/A.ui.background:getWidth(),sh/A.ui.background:getHeight())
  love.graphics.setColor(0,0,0,0.7)
  love.graphics.rectangle("fill", 0, 0, sw, sh)
  love.graphics.setColor(1,1,1)
  if phase == "bounce" then
    local f = math.min(t / SWING_DURATION, 1)
    drawSpotlights(f)
    drawChest(t)
 
  elseif phase == "burst" then
    local f = math.min(t / BURST_DURATION, 1)
    drawSpotlights(1)
    drawChest(2)
    drawWhiteFlash(f)
  
  elseif phase == "reveal" then
    drawSpotlights(1)
    drawBurst() -- trailing particles still falling/fading
    drawRadial()
    drawPrizeFramed()
  end
end

return Gacha