local State = {}

State.player = {
  exp      = "Lv 12",
  energy   = "20/20",
  coins    = 500000,
  diamonds = 50000,
  owned    = {mariposa=true, rose_maxi=true,rose_tube=true,bejewelled_blue=true, cinderella=true, elsa_crown=true },   -- set of item ids the player owns: { rose_dress = true, ... }
}

function State.hasItem(id)
  return State.player.owned[id] == true
end

function State.addItem(id)
  State.player.owned[id] = true
end

function State.canAfford(price)
  local p = State.player
  if price.currency == "diamonds" then return p.diamonds >= price.amount end
  if price.currency == "coins"    then return p.coins    >= price.amount end
  return false
end

function State.spend(price)
  if price.currency == "diamonds" then State.player.diamonds = State.player.diamonds - price.amount end
  if price.currency == "coins"    then State.player.coins    = State.player.coins    - price.amount end
end

return State