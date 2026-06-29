--[[
  StarWow — main entry point
  Scenes: "menu" | "gacha" | "popup" | "refund"
--]]

local A      = require("src.assets")
local State  = require("src.state")
local Navbar = require("src.navbar")
local Menu   = require("src.menu")
local Popup = require("src.popup")

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
  Popup.open(chestIndex, select(2, love.graphics.getDimensions()))
end
-- Wire menu callbacks
Menu.onBuy     = gotoGacha
Menu.onPreview = gotoPopup

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest",1)
  A.load()
  Menu.load()
  if A.bgm then love.audio.play(A.bgm) end
end

function love.update(dt)
  local sw, sh = love.graphics.getDimensions()
  Menu.update(dt, sw, sh)
  Popup.update(dt, sw, sh)   -- always update so slide animates out too
end

function love.draw()
  local sw, sh = love.graphics.getDimensions()
  Menu.draw(sw, sh)
  Navbar.draw(sw)
  Popup.draw(sw, sh)          -- draws on top of everything
end

function love.wheelmoved(x, y)
  if Popup.isVisible() then
    Popup.wheelmoved(x, y)    -- popup consumes scroll when open
  elseif scene == "menu" then
    Menu.wheelmoved(x, y)
  end
end

function love.mousepressed(mx, my, button)
  local sw, sh = love.graphics.getDimensions()
  if Popup.isVisible() then
    Popup.mousepressed(mx, my, button, sw, sh)
    return                    -- menu doesn't receive clicks while popup open
  end
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