--[[
  StarWow — main entry point
  Scenes: "menu" | "gacha" | "popup" | "refund"
--]]

local A      = require("src.assets")
local State  = require("src.state")
local Navbar = require("src.navbar")
local Menu   = require("src.menu")

-- ── scene wiring (stubs until you build them) ────────────────────────────────
local scene = "menu"
local pendingChest = nil   -- chest index for gacha/popup

local function gotoGacha(chestIndex)
  pendingChest = chestIndex
  scene = "gacha"
  -- TODO: require("src.gacha").start(chestIndex)
end

local function gotoPopup(chestIndex)
  pendingChest = chestIndex
  scene = "popup"
  -- TODO: require("src.popup").open(chestIndex)
end

-- Wire menu callbacks
Menu.onBuy     = gotoGacha
Menu.onPreview = gotoPopup

function love.load()
  love.graphics.setDefaultFilter("linear", "linear")
  A.load()
  Menu.load()
  if A.bgm then love.audio.play(A.bgm) end
end

function love.update(dt)
  local sw, sh = love.graphics.getDimensions()
  if scene == "menu" then
    Menu.update(dt, sw, sh)
  end
end

function love.draw()
  local sw, sh = love.graphics.getDimensions()

  if scene == "menu" then
    Menu.draw(sw, sh)
    Navbar.draw(sw)        -- draws on top
  end

  -- Debug overlay (remove when done)
  love.graphics.setColor(0.4, 1, 0.6, 0.6)
  love.graphics.setFont(A.font.sm)
  love.graphics.print("scene:" .. scene .. "  fps:" .. love.timer.getFPS(), 4, sh - 16)
  love.graphics.setColor(1,1,1,1)
end

function love.wheelmoved(x, y)
  if scene == "menu" then Menu.wheelmoved(x, y) end
end

function love.mousepressed(mx, my, button)
  local sw, sh = love.graphics.getDimensions()
  if scene == "menu" then
    Menu.mousepressed(mx, my, button, sw, sh)
  end
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  -- Debug: refill currency
  if key == "d" then State.player.diamonds = State.player.diamonds + 1000 end
  if key == "c" then State.player.coins    = State.player.coins    + 50000 end
end