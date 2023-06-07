local awful = require('awful')
local autostart = {}
local function run_once(prg, arg_string, pname)
  if not prg then
    return nil
  end

  if not pname then
    pname = prg
  end

  if not arg_string then
    awful.spawn.with_shell("pgrep " .. pname .. " || (" .. prg .. ")")
  else
    awful.spawn.with_shell("pgrep " .. pname .. " || (" .. prg .. " " .. arg_string .. ")")
  end
end

autostart.run_once = run_once

function autostart.init()
  run_once('nm-applet')
  run_once('leftmouse.sh')
end

return autostart
