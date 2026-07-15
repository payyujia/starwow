local A = {}

local function tryImage(path, filterMode)
  local ok, img = pcall(love.graphics.newImage, path)
  if not ok then
    print("MISSING IMAGE: " .. path)
    return nil
  end

  filterMode = filterMode or "linear"
  img:setFilter(filterMode, filterMode)

  return img
end

local function tryFont(path, size)
  local ok, f = pcall(love.graphics.newFont, path, size)
  return ok and f or love.graphics.newFont(size)
end

function A.load()
  A.font = {
    sm  = tryFont("assets/fonts/main.ttf", 28),
    md  = tryFont("assets/fonts/main.ttf", 40),
    lg  = tryFont("assets/fonts/main.ttf", 50),
    xl  = tryFont("assets/fonts/main.ttf", 100),
  }

  -- UI / navbar
  A.ui = {
    diamond   = tryImage("assets/images/ui/diamond2.png"),
    coin      = tryImage("assets/images/ui/coin2.png"),
    energy    = tryImage("assets/images/ui/energy2.png"),
    exp       = tryImage("assets/images/ui/exp2.png"),
    background= tryImage("assets/images/ui/background.png"),
    settings  = tryImage("assets/images/ui/settings.png"),
    lace      = tryImage("assets/images/ui/lace.png"),
    buyBtn    = tryImage("assets/images/ui/pinkbutton.png"),
    mannequin = tryImage("assets/images/ui/dressup_dummy_stand-hd.png"),
    magnify   = tryImage("assets/images/ui/magnify.png"),
    glitter   = tryImage("assets/images/ui/glitter_row.png"),
    spotlight = tryImage("assets/images/ui/spotlight.png"),
    ribbon    = tryImage("assets/images/ui/banner.png"),
    confetti1 = tryImage("assets/images/ui/confetti1.png"),
    confetti2 = tryImage("assets/images/ui/confetti2.png"),
    radial    = tryImage("assets/images/ui/radial.png"),
    container = tryImage("assets/images/ui/container.png")
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
    print("chest:", chest.id, "pool size:", chest.pool and #chest.pool or "NIL")
    for _, item in ipairs(chest.pool) do
      A.prizes[item.id] = tryImage("assets/images/prizes/" .. item.id .. ".png","nearest")
    end
  end
  print(A.prizes)
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