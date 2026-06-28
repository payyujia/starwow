local A = {}

local function tryImage(path)
  local ok, result = pcall(love.graphics.newImage, path)
  if not ok then
    print("FAILED: " .. path .. " | " .. tostring(result))
    return nil
  end
  return result
end

local function tryFont(path, size)
  local ok, f = pcall(love.graphics.newFont, path, size)
  return ok and f or love.graphics.newFont(size)
end

function A.load()
  A.font = {
    sm  = tryFont("assets/fonts/main.ttf", 25),
    md  = tryFont("assets/fonts/main.ttf", 40),
    lg  = tryFont("assets/fonts/main.ttf", 50),
    xl  = tryFont("assets/fonts/main.ttf", 100),
  }

  -- UI / navbar
  A.ui = {
    diamond   = tryImage("assets/images/ui/diamond.png"),
    coin      = tryImage("assets/images/ui/coin.png"),
    energy    = tryImage("assets/images/ui/energy.png"),
    exp       = tryImage("assets/images/ui/exp.png"),
    background = tryImage("assets/images/ui/background.png"),
    settings  = tryImage("assets/images/ui/settings.png"),
    lace      = tryImage("assets/images/ui/lace.png"),
    buyBtn    = tryImage("assets/images/ui/pinkbutton.png"),
    mannequin = tryImage("assets/images/ui/dressup_dummy_stand-hd.png"),
    magnify   = tryImage("assets/images/ui/magnify.png")
  }


  -- Per-chest: card background + chest image, keyed by chest id
  A.chests = {}
  local chestData = require("data.chests")
  for _, chest in ipairs(chestData) do
    A.chests[chest.id] = {
      card  = tryImage("assets/images/chests/card_"  .. chest.id .. ".png"),
      chest = tryImage("assets/images/chests/chest_" .. chest.id .. ".png"),
    }
  end

  -- Prize sprites keyed by item id
  A.prizes = {}
  for _, chest in ipairs(chestData) do
    for _, item in ipairs(chest.pool) do
      if not A.prizes[item.id] then
        A.prizes[item.id] = tryImage("assets/images/prizes/" .. item.id .. ".png")
      end
    end
  end

  local ok, src = pcall(love.audio.newSource, "assets/music/bgm.mp3", "stream")
  if ok then A.bgm = src; A.bgm:setLooping(true) end
end
-- Draw a placeholder box when image is nil
function A.drawOrPlaceholder(img, x, y, w, h, r, g, b)
  if img then
    local iw, ih = img:getDimensions()
    love.graphics.draw(img, x, y, 0, w/iw, h/ih)
  else
    love.graphics.setColor(r or 0.7, g or 0.7, b or 0.8, 0.6)
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return A