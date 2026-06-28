local A        = require("src.assets")
local State    = require("src.state")
local Navbar   = require("src.navbar")
local chestData = require("data.chests")

local Menu = {}

-- Layout
local LEFT_RATIO   = 0.40
local CARD_HEIGHT  = 360
local CARD_MARGIN  = 80
local SCROLL_PAD   = 10

-- Internal state
local scrollY     = 0
local maxScrollY  = 0
local selectedChest = 1   -- index into chestData; drives left panel
local menuTime = 0
-- Callbacks set by main.lua
Menu.onBuy     = nil   -- function(chestIndex)
Menu.onPreview = nil   -- function(chestIndex)  magnifier popup

--  helpers 

local RARITY_COLOR = {
  limited = {1,   0.84, 0,   1},
  special = {0.7, 0.4,  1,   1},
  hot     = {1,   0.45, 0.1, 1},
}

local function rarityLabel(r)
  if r == "limited" then return "★ LIMITED" end
  if r == "special"  then return "◆ SPECIAL"  end
  return "● HOT"
end

-- helper: draws an image scaled to exact w/h (stretches)
local function drawStretch(img, x, y, w, h)
  if not img then return end
  local iw, ih = img:getDimensions()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, x, y, 0, w / iw, h / ih)
end
-- ─── Left panel ───────────────────────────────────────────────────────────────

local function drawLeftPanel(sw, sh)
  local lw = math.floor(sw * LEFT_RATIO)
  local top = Navbar.HEIGHT

  local chest = chestData[selectedChest]

end

-- ─── Right scrollable panel ───────────────────────────────────────────────────

-- Returns screen-space y of a card (accounting for scroll)
local function cardY(index, rightTop)
  return rightTop + SCROLL_PAD + (index-1) * (CARD_HEIGHT + CARD_MARGIN) - scrollY
end

local function drawRightPanel(sw, sh)
  local lw  = math.floor(sw * LEFT_RATIO)
  local rw  = sw - lw
  local top = Navbar.HEIGHT

  -- Background
  drawStretch(A.ui.background, 0, 0, sw, sh)


  love.graphics.setScissor(lw-60, top, rw+60, sh - top)

  for i, chest in ipairs(chestData) do
    local cy  = cardY(i, top)
    local cx  = lw + 20          -- right panel x start with some margin
    local cw  = rw - 150          -- card width

    if cy + CARD_HEIGHT < top or cy > sh then goto continue end

    local imgs = A.chests[chest.id]  -- { card=..., chest=... }

    -- ── Card background ──────────────────────────────────────────
    if imgs and imgs.card then
      drawStretch(imgs.card, cx, cy, cw, CARD_HEIGHT)
    else
      -- Outer border fill (#542e7d)
      love.graphics.setColor(0.33, 0.18, 0.49, 1)
      love.graphics.rectangle("fill", cx, cy, cw, CARD_HEIGHT)

      love.graphics.setColor(0.89, 0.73, 0.96, 1)
      love.graphics.rectangle("fill", cx + 6, cy + 6, cw - 12, CARD_HEIGHT - 12)

      -- Lace overlay: right quadrant, straight edge flush with card top
      love.graphics.setScissor(cx + 6, top, cw - 12,sh-top)
      laceX,laceY = A.ui.lace:getDimensions()
      love.graphics.setColor(1, 1, 1, 1)   -- full opacity, no transparency
      love.graphics.draw(A.ui.lace, cx-laceX/2.5, cy+6)
      love.graphics.setScissor(lw - 60, top, rw + 60, sh - top)
    end

    -- ── Chest image
    -- height = card height, width proportional; left quarter overhangs
    local chestH  = CARD_HEIGHT
    local chestImg = imgs and imgs.chest
    local iw, ih  = chestImg:getDimensions()
    local scale   = chestH / ih
    chestW        = iw * scale
    local chestX  = cx -100
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(chestImg, chestX, cy, 0, scale, scale)
  -- Bopping magnify glass
  local bopScale = scale * (1 + 0.07* math.sin(menuTime * 3.5))
  local mgW = A.ui.magnify:getWidth() * bopScale
  local mgH = A.ui.magnify:getHeight() * bopScale
  love.graphics.draw(
    A.ui.magnify,
    chestX + 25 + mgW/2,   -- offset by half so it scales from center
    cy + chestH * 0.6 + mgH/2,
    0,
    bopScale, bopScale,
    A.ui.magnify:getWidth()/2,   -- origin x = center of image
    A.ui.magnify:getHeight()/2   -- origin y = center of image
  )
    -- Chest name 
    local textX = cx + chestW * 0.6  -- starts after the chest image
    local textW = cw - chestW * 0.6
    love.graphics.setColor(0.5,0.09,0.65, 1)
    love.graphics.setFont(A.font.md)
    love.graphics.printf(chest.name, textX, cy + 50, textW, "center")

    -- Buy button 
    local btnW, btnH = 380, 240
    local btnX = cx + chestW * 0.6
    local btnY = cy + (CARD_HEIGHT - btnH) / 1.3
    local canBuy = State.canAfford(chest.price)

    love.graphics.setColor(canBuy and {1,1,1,1} or {0.5,0.5,0.5,1})
    drawStretch(A.ui.buyBtn, btnX, btnY, btnW, btnH)
    -- "Buy"
    love.graphics.setFont(A.font.lg)
    love.graphics.printf("Buy", btnX, btnY + btnH/4, btnW, "center")

    local iconSize = A.font.sm:getHeight()   -- matches the smaller font now
    local priceStr = tostring(chest.price.amount)
    local iconImg  = (chest.price.currency == "diamonds") and A.ui.diamond or A.ui.coin
    local lineY    = btnY + btnH * 0.6
    local totalW   = iconSize + 4 + A.font.sm:getWidth(priceStr)
    local lineX    = btnX + (btnW - totalW) / 2

    local iw, ih = iconImg:getDimensions()
    love.graphics.draw(iconImg, lineX, lineY, 0, iconSize/iw, iconSize/ih)

    love.graphics.setFont(A.font.sm)
    love.graphics.print(priceStr, lineX + iconSize + 4, lineY)

    ::continue::
  end

  love.graphics.setScissor()
  love.graphics.setColor(1, 1, 1, 1)
end
-- Public API 

function Menu.load()
  local totalH = #chestData * (CARD_HEIGHT + CARD_MARGIN) + SCROLL_PAD * 2
  -- maxScrollY computed in update once we know sh
end

function Menu.update(dt, sw, sh)
  menuTime = menuTime + dt 
  local lw  = math.floor(sw * LEFT_RATIO)
  local rw  = sw - lw
  local totalH = #chestData * (CARD_HEIGHT + CARD_MARGIN) + SCROLL_PAD * 2
  local visH   = sh - Navbar.HEIGHT
  maxScrollY = math.max(0, totalH - visH)
  scrollY    = math.max(0, math.min(scrollY, maxScrollY))
end

function Menu.draw(sw, sh)
  drawLeftPanel(sw, sh)
  drawRightPanel(sw, sh)
end

function Menu.wheelmoved(x, y)
  scrollY = scrollY - y * 30
end

function Menu.mousepressed(mx, my, button, sw, sh)
  if button ~= 1 then return end

  local lw  = math.floor(sw * LEFT_RATIO)
  local rw  = sw - lw
  local top = Navbar.HEIGHT

  if mx < lw - 60 then return end  -- matches scissor start

  for i, chest in ipairs(chestData) do
    local cy = cardY(i, top)
    local cx = lw + 20
    local cw = rw - 150

    if my < cy or my > cy + CARD_HEIGHT then goto continue end
    if mx < cx - 100 or mx > cx + cw    then goto continue end

    selectedChest = i

    -- Derive chestW the same way drawRightPanel does
    local imgs    = A.chests[chest.id]
    local chestX  = cx - 100
    local chestW  = 0
    if imgs and imgs.chest then
      local iw, ih = imgs.chest:getDimensions()
      local scale  = CARD_HEIGHT / ih
      chestW       = iw * scale
    end

    -- Magnify hit area 
    local mgX = chestX + 25
    local mgY = cy + CARD_HEIGHT * 0.6
    local mgSize = 60   -- generous tap target
    if mx >= mgX and mx <= mgX + mgSize and
       my >= mgY and my <= mgY + mgSize then
      if Menu.onPreview then Menu.onPreview(i) end
      return
    end

    -- ── Buy button hit area 
    local btnW  = 380
    local btnH  = 240
    local btnX  = cx + chestW * 0.6
    local btnY  = cy + (CARD_HEIGHT - btnH) / 1.3
    if mx >= btnX and mx <= btnX + btnW and
       my >= btnY and my <= btnY + btnH then
      if State.canAfford(chest.price) then
        if Menu.onBuy then Menu.onBuy(i) end
      end
      return
    end

    ::continue::
  end
end

return Menu