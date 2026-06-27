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

-- Callbacks set by main.lua
Menu.onBuy     = nil   -- function(chestIndex)
Menu.onPreview = nil   -- function(chestIndex)  magnifier popup

-- ─── helpers ──────────────────────────────────────────────────────────────────

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

      -- Inner background (#E3B9F6), inset by 3px border
      love.graphics.setColor(0.89, 0.73, 0.96, 1)
      love.graphics.rectangle("fill", cx + 6, cy + 6, cw - 12, CARD_HEIGHT - 12)

      -- Lace overlay: right quadrant, straight edge flush with card top
      love.graphics.setScissor(cx + 6, cy + 6, cw - 12, CARD_HEIGHT - 12)
      laceX,laceY = A.ui.lace:getDimensions()
      love.graphics.setColor(1, 1, 1, 1)   -- full opacity, no transparency
      love.graphics.draw(A.ui.lace, cx-laceX/2.5, cy+6)
      love.graphics.setScissor(lw - 60, top, rw + 60, sh - top)
    end

    -- ── Chest image (hangs over left edge by 25%) ─────────────────
    -- height = card height, width proportional; left quarter overhangs
    local chestH  = CARD_HEIGHT
    local chestImg = imgs and imgs.chest
    local iw, ih  = chestImg:getDimensions()
    local scale   = chestH / ih
    chestW        = iw * scale
    local chestX  = cx -100
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(chestImg, chestX, cy, 0, scale, scale)

    -- ── Chest name ────────────────────────────────────────────────
    local textX = cx + chestW * 0.6  -- starts after the chest image
    local textW = cw - chestW * 0.6
    love.graphics.setColor(0.5,0.09,0.65, 1)
    love.graphics.setFont(A.font.md)
    love.graphics.printf(chest.name, textX, cy + 50, textW, "center")

    -- ── Buy button ────────────────────────────────────────────────
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
-- ─── Public API ───────────────────────────────────────────────────────────────

function Menu.load()
  local totalH = #chestData * (CARD_HEIGHT + CARD_MARGIN) + SCROLL_PAD * 2
  -- maxScrollY computed in update once we know sh
end

function Menu.update(dt, sw, sh)
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
  local top = Navbar.HEIGHT

  -- Only handle clicks in right panel
  if mx < lw then return end

  for i, chest in ipairs(chestData) do
    local cy = cardY(i, top)
    local cx = lw + 8
    local cw = sw - lw - 16

    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + CARD_HEIGHT then
      selectedChest = i   -- select on any tap

      -- Check magnify glass click
      local mgx = cx + cw - 22
      local mgy = cy + 8
      if mx >= mgx and mx <= mgx + 22 and my >= mgy and my <= mgy + 22 then
        if Menu.onPreview then Menu.onPreview(i) end
        return
      end

      -- Check buy button click
      local btnW, btnH = 90, 30
      local btnX = cx + cw - btnW - 8
      local btnY = cy + CARD_HEIGHT - btnH - 12
      if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
        if State.canAfford(chest.price) then
          if Menu.onBuy then Menu.onBuy(i) end
        end
        return
      end
    end
  end
end

return Menu