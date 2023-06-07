local awful = require("awful")
local toggle = {}

local get_clients = function(screen)
  local cs = {}
  screen = screen or awful.screen.focused()
  local tag = screen.selected_tag
  if tag then
    local tcs = tag:clients()
    -- get all client use default client order
    for _, c in ipairs(client.get()) do
      for _, v in ipairs(tcs) do
        if c == v then
          table.insert(cs, v)
        end
      end
    end
  end
  return cs
end

toggle.tile_or_floating = function(screen)
  screen = screen or awful.screen.focused()
  local tag = screen.selected_tag
  if tag and tag.layout.name ~= awful.layout.suit.tile.name then
    tag.layout =  awful.layout.suit.tile
    for _, client in ipairs(get_clients()) do
      client.floating = false
      client.maximized = false
    end
  elseif tag and tag.layout.name ~= awful.layout.suit.floating.name then
    tag.layout = awful.layout.suit.floating
    for _, client in ipairs(get_clients()) do
      client.floating = true
      client.maximized = true
    end
  end
end

toggle.focus = function(index)
  local screen = awful.screen.focused()
  if not screen then return end
  local c = get_clients(screen)[index]
  if c and client.focus and client.focus ~= c then
    if client.minimized then
      client.minimized = false
    end
    client.focus = c
    c:raise()
  end
end

return toggle
