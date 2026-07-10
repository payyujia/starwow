local A         = require("src.assets")
local State     = require("src.state")
local chestData = require("data.chests")

local Popup = {}

-- Config
local SLIDE_SPEED  = 10
local PRIZE_SIZE   = 150
local PRIZE_PAD    = 12
local PRIZE_BORDER = 10
local SECTION_PAD  = 16
local CORNER       = 16
local HEADER_H     = 110
local COLLECTED_H  = 36

local SECTIONS = {
  { rarity = "limited", label = "Limited", bg = {1, 0.8, 0.2}, border = {0.95, 0.5, 0.15} },
  { rarity = "special", label = "Special", bg = {1, 0.78, 0.97}, border = {0.62, 0.32, 0.9} },
  { rarity = "hot",     label = "Hot",     bg = {0.72, 0.88, 1.0}, border = {0.25, 0.6,  0.95} },
}

-- State
local visible    = false
local chestIndex = 1
local slideY     = 0
local targetY    = 0
local popScrollY = 0
local maxPopScrollY = 0

-- ── helpers ────────────────────────────────────────────────────────────────

local function drawStretch(img, x, y, w, h)
  if not img then return end
  local iw, ih = img:getDimensions()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, x, y, 0, w/iw, h/ih)
end

local function getChest()
  return chestData[chestIndex]
end

local function getSection(pool, rarity)
  local out = {}
  for _, item in ipairs(pool) do
    if item.rarity == rarity then out[#out+1] = item end
  end
  return out
end

local function countOwned(pool)
  local n = 0
  for _, item in ipairs(pool) do
    if State.hasItem(item.id) then n = n + 1 end
  end
  return n
end

local function computeContentH(pool, contentW)
  local cols = math.max(1, math.floor((contentW + PRIZE_PAD) / (PRIZE_SIZE + PRIZE_PAD)))
  local total = 0
  for _, sec in ipairs(SECTIONS) do
    local items = getSection(pool, sec.rarity)
    if #items > 0 then
      local rows = math.ceil(#items / cols)
      -- header label + lace ~60, prize rows, padding
      total = total + SECTION_PAD + 60 + rows * (PRIZE_SIZE + PRIZE_PAD) + SECTION_PAD * 2
    end
  end
  return total
end

-- ── public ─────────────────────────────────────────────────────────────────

function Popup.open(idx, sh)
  chestIndex = idx
  visible    = true
  popScrollY = 0
  slideY     = sh * 0.9   -- start off-screen below
end

function Popup.close()
  visible = false
end

function Popup.isVisible()
  return visible
end

-- ── draw helpers ────────────────────────────────────────────────────────────

local function drawPrize(item, x, y, borderCol)
  -- thick border
  love.graphics.setColor(borderCol)
  love.graphics.rectangle("fill", x, y, PRIZE_SIZE, PRIZE_SIZE, 10, 10)
  -- inner bg
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle("fill",
    x + PRIZE_BORDER, y + PRIZE_BORDER,
    PRIZE_SIZE - PRIZE_BORDER*2, PRIZE_SIZE - PRIZE_BORDER*2,
    7, 7)
  -- sprite
  local img = A.prizes[item.id]
  if img then
    local iw, ih = img:getDimensions()
    local inner  = PRIZE_SIZE - PRIZE_BORDER * 2
    local s      = math.max(inner/iw, inner/ih)   -- fill instead of fit
    local ox     = (inner - iw*s) / 2
    local oy     = (inner - ih*s) / 2
    love.graphics.setColor(State.hasItem(item.id) and {1,1,1,1} or {0,0,0,0.85})
    love.graphics.draw(img,
      x + PRIZE_BORDER + ox,
      y + PRIZE_BORDER + oy,
      0, s, s)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local function drawSection(sec, items, x, y, w, scissorY, scissorH)
  local cols = math.max(1, math.floor((w + PRIZE_PAD) / (PRIZE_SIZE + PRIZE_PAD)))
  local rows = math.ceil(#items / cols)
  local secH = SECTION_PAD + 60 + rows * (PRIZE_SIZE + PRIZE_PAD) + SECTION_PAD

  love.graphics.setColor(sec.bg)
  love.graphics.rectangle("fill", x, y, w, secH, CORNER, CORNER)

  if A.ui.lace then
    local lw2, lh2 = A.ui.lace:getDimensions()
    local sx = w / lw2  -- scale to fill full width
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(A.ui.lace, x, y, 0, sx, 1)
    if sec.rarity == "limited" then
      local gw, gh = A.ui.glitter:getDimensions()
      love.graphics.draw(A.ui.glitter, x, y, 0, w/gw, 1)
    else
      love.graphics.draw(A.ui.lace, x + w, y + secH, math.pi, sx, 1)
    end
  end

  -- Label centered
  love.graphics.setColor(0.42, 0.05, 0.45, 1)
  love.graphics.setFont(A.font.md)
  love.graphics.printf(sec.label, x, y + SECTION_PAD, w, "center")

  local gridW  = cols * (PRIZE_SIZE + PRIZE_PAD) - PRIZE_PAD
  local gridX  = x + (w - gridW) / 2
  local gridY  = y + SECTION_PAD + 58
  for idx, item in ipairs(items) do
    local col = (idx-1) % cols
    local row = math.floor((idx-1) / cols)
    local px
    if sec.rarity == "limited" then
      local itemsInRow = math.min(cols, #items - row * cols)
      local rowW = itemsInRow * (PRIZE_SIZE + PRIZE_PAD) - PRIZE_PAD
      px = x + (w - rowW) / 2 + col * (PRIZE_SIZE + PRIZE_PAD)
    else
      px = gridX + col * (PRIZE_SIZE + PRIZE_PAD)
    end
    local py = gridY + row * (PRIZE_SIZE + PRIZE_PAD)
    drawPrize(item, px, py, sec.border)
  end
  love.graphics.setColor(1, 1, 1, 1)
  return secH
end
-- ── update / draw / input ───────────────────────────────────────────────────

function Popup.update(dt, sw, sh)
  if not visible then return end

  local modalW  = math.floor(sw * .7)
  local modalH  = math.floor(sh * 0.9)
  targetY       = sh - modalH
  slideY        = slideY + (targetY - slideY) * math.min(1, dt * SLIDE_SPEED)

  local chest    = getChest()
  local contentW = modalW - SECTION_PAD * 2
  local listH    = modalH - HEADER_H - COLLECTED_H
  local contentH = computeContentH(chest.pool, contentW)
  maxPopScrollY  = math.max(0, contentH - listH)
  popScrollY     = math.max(0, math.min(popScrollY, maxPopScrollY))
end

function Popup.draw(sw, sh)
  if not visible then return end

  local modalW = math.floor(sw * .7)
  local modalH = math.floor(sh * 0.9)
  local mx_    = math.floor((sw - modalW) / 2)  -- centered horizontally
  local my     = math.floor(slideY)-SECTION_PAD

  -- Dim the menu behind
  love.graphics.setColor(0, 0, 0, 0.52)
  love.graphics.rectangle("fill", 0, 0, sw, sh)

  -- Modal background
  if A.ui.prizecontainer then
    drawStretch(A.ui.prizecontainer, mx_, my, modalW, modalH)
  else
    love.graphics.setColor(0.97, 0.93, 0.99, 1)
    love.graphics.rectangle("fill", mx_, my, modalW, modalH, 20, 20)
  end -- DELETE ltr ─────────────────────────────────────────────────────────

  local chest = getChest()
  local imgs  = A.chests[chest.id]

  -- ── Header ─────────────────────────────────────────────────────────
  local headerY = my

  -- Chest thumbnail left
  if imgs and imgs.chest then
    local iw, ih = imgs.chest:getDimensions()
    local s = (HEADER_H*2) / ih
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(imgs.chest, mx_, headerY-ih/5, 0, s, s)
  end

  -- Chest name
  love.graphics.setColor(0.3, 0.05, 0.4, 1)
  love.graphics.setFont(A.font.lg)
  love.graphics.printf(
    chest.name,
    HEADER_H + 10, headerY + (HEADER_H - A.font.lg:getHeight()) / 2,
    sw - HEADER_H - 70, "center")

  -- Collected count
  local owned = countOwned(chest.pool)
  local total = #chest.pool
  love.graphics.setColor(0.45, 0.3, 0.55, 1)
  love.graphics.setFont(A.font.sm)
  love.graphics.printf(
    owned .. "/" .. total .. " Collected",
    mx_, my + HEADER_H + 10,
    modalW - 16, "right")

  -- Scrollable prize list
  local listTop  = my + HEADER_H + COLLECTED_H
  local listH    = modalH - HEADER_H - COLLECTED_H
  local contentX = mx_ + SECTION_PAD
  local contentW = modalW - SECTION_PAD*2
  local drawY    = listTop - popScrollY + SECTION_PAD

  for _, sec in ipairs(SECTIONS) do
    local items = getSection(chest.pool, sec.rarity)
    if #items > 0 then
      love.graphics.setScissor(mx_, listTop, modalW, listH)
      local secH = drawSection(sec, items, contentX, drawY, contentW, listTop, listH)
      drawY = drawY + secH + SECTION_PAD
    end
  end

  love.graphics.setScissor()
  love.graphics.setColor(1, 1, 1, 1)
end

function Popup.wheelmoved(x, y)
  if not visible then return end
  popScrollY = popScrollY - y * 30
end

function Popup.mousepressed(mx, my_coord, button, sw, sh)
  if not visible then return false end
  if button ~= 1 then return false end

  local modalW   = math.floor(sw * .7)
  local my_modal = math.floor(slideY)

  -- Tap outside modal = close
  local mx_ = math.floor((sw - modalW) / 2)
  if mx < mx_ or mx > mx_ + modalW or my_coord < my_modal then
    Popup.close()
    return true
  end

  return true
end
return Popup