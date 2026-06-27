local A     = require("src.assets")
local State = require("src.state")

local Navbar = {}
Navbar.HEIGHT = 48

local STATS = {
  { key = "exp",      icon = "exp",     color = {0,0,0} },
  { key = "energy",   icon = "energy",  color = {0,0,0}   },
  { key = "coins",    icon = "coin",    color = {0.64, 0.27, 0.07}  },
  { key = "diamonds", icon = "diamond", color = {0.8,0.19,0.75}   },
}

local SETTINGS_W = 100   -- fixed width slot for settings on the right


function Navbar.draw(sw)
  local h   = Navbar.HEIGHT
  local bw  = math.floor((sw - SETTINGS_W) / #STATS)  -- 4 stats share remaining width

  -- Background bar
  love.graphics.setColor(0.12, 0.12, 0.18, 0.6)
  love.graphics.rectangle("fill", 0, 0, sw, h)

  local p = State.player

  for i, stat in ipairs(STATS) do
    local x   = (i-1) * bw + 40
    local val = p[stat.key]

    -- Pill: starts 6px from left of slot, leaves room for icon to anchor on left edge
    local pillX = x + 6
    local pillW = bw -55
    local pillH = h - 18
    local pillY = 9

    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.rectangle("fill", pillX, pillY, pillW, pillH, 9, 9)

    local iconSize = h+5
    local icon     = A.ui[stat.icon]
    local iconX    = pillX - iconSize * 0.3   -- shift left so icon straddles pill edge
    local iconY    = pillY + (pillH - iconSize) / 2 + 4

  
    local iw, ih = icon:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(icon, iconX, iconY, 0, iconSize/iw, iconSize/ih)
  

    -- Value text: pushed right of icon
    love.graphics.setColor(stat.color)
    love.graphics.setFont(A.font.sm)
    local textX = pillX + iconSize * 0.8   -- starts just right of where icon ends inside pill
    local textW = pillW - iconSize * 0.8 - 4
    love.graphics.printf(val, textX, pillY + (pillH - A.font.sm:getHeight()) / 2, textW, "left")
  end

  local sx = sw - SETTINGS_W

  local iw, ih = A.ui.settings:getDimensions()
  local sz = 30
  love.graphics.setColor(1, 1, 1, 0.92)
  love.graphics.draw(A.ui.settings, sx + (SETTINGS_W-sz)/2, (h-sz)/2, 0, sz/iw, sz/ih)

  love.graphics.setColor(1, 1, 1, 1)
end

-- Call this in mousepressed in main.lua to detect settings tap
function Navbar.clickedSettings(mx, my, sw)
  local h  = Navbar.HEIGHT
  local sx = sw - SETTINGS_W
  return mx >= sx and mx <= sw and my >= 0 and my <= h
end

return Navbar