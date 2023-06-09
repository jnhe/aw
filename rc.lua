-- randomseed
math.randomseed( os.time() )
math.random()

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")
local autostart = require("autostart")
local toggle = require("toggle_tile")
local config = require("config")

local function change_default_menu_size(h, w)
  -- beautiful.hotkeys_font = "Source Code Pro"
  -- beautiful.hotkeys_description_font = "Source Code Pro"
  beautiful.menu_font = "Source Code Pro"
  beautiful.menu_height = h or 28
  beautiful.menu_width = w or 350
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function (err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true

    naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, an error happened!",
    text = tostring(err) })
    in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- This is used later as the default terminal and editor to run.
local konsole = "konsole"
local gnome_terminal = "gnome-terminal"
local terminal = konsole or gnome_terminal
local editor = os.getenv("EDITOR") or "nvim"
local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"


-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    awful.layout.suit.corner.ne,
    awful.layout.suit.corner.sw,
    awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil
    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
local myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

local freedesktop = require("freedesktop")

change_default_menu_size()
local mymainmenu = freedesktop.menu.build({
  before = {
    { "Open terminal", terminal },
    { "Open konsole", konsole },
    { "Awesome", myawesomemenu, beautiful.awesome_icon },
    -- other triads can be put here
  },
  after = {
    -- other triads can be put here
  },
})

local mylauncher = awful.widget.launcher(
  { image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock()
local cal_notification
mytextclock:connect_signal("button::release", function ()
  if cal_notification == nil then
    awful.spawn.easy_async([[bash -c "cal --color=always -3"]], function (stdout)
      cal_notification = naughty.notify{
        text = string.gsub(string.gsub(stdout, "%[7m", "<span foreground='red'>"), "%[0m", "</span>"),
        font = "Source Code Pro Regular",
        timeout = 0,
        width = auto,
        destroy = function () cal_notification = nil end,
      }
    end)
  else
    naughty.destroy(cal_notification)
    cal_notification = nil
  end
end
)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
  awful.button({ }, 1, function(t) t:view_only() end),
  awful.button({ modkey }, 1, function(t)
    if client.focus then
      client.focus:move_to_tag(t)
    end
  end),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, function(t)
    if client.focus then
      client.focus:toggle_tag(t)
    end
  end),
  awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
  awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
  awful.button({ }, 1, function (c)
    if c == client.focus then
      c.minimized = true
    else
      -- Without this, the following
      -- :isvisible() makes no sense
      c.minimized = false
      if not c:isvisible() and c.first_tag then
        c.first_tag:view_only()
      end
      -- This will also un-minimize
      -- the client, if needed
      client.focus = c
      c:raise()
    end
  end),
  awful.button({ }, 3, client_menu_toggle_fn()),
  awful.button({ }, 4, function ()
    awful.client.focus.byidx(1)
  end),
  awful.button({ }, 5, function ()
    awful.client.focus.byidx(-1)
end))

local function set_wallpaper(s)
  -- Main screen
  if screen.primary == s then
    gears.wallpaper.maximized(config.main_wallpaper, s, true)
  else
  end
end

local volume_widget = require('awesome-wm-widgets.volume-widget.volume')

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
  -- Wallpaper
  set_wallpaper(s)

  -- Each screen has its own tag table.
  -- Tag 2 is tile layout
  local suit = awful.layout.suit
  awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, { suit.floating, suit.tile })

  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()
  -- Create an imagebox widget which will contain an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  s.mylayoutbox = awful.widget.layoutbox(s)
  s.mylayoutbox:buttons(gears.table.join(
  awful.button({ }, 1, function () awful.layout.inc( 1) end),
  awful.button({ }, 3, function () awful.layout.inc(-1) end),
  awful.button({ }, 4, function () awful.layout.inc( 1) end),
  awful.button({ }, 5, function () awful.layout.inc(-1) end)))
  -- Create a taglist widget
  s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

  -- Create a tasklist widget
  s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

  -- Create the wibox
  s.mywibox = awful.wibar({ position = "top", screen = s })

  -- Add widgets to the wibox
  s.mywibox:setup {
    layout = wibox.layout.align.horizontal,
    { -- Left widgets
      layout = wibox.layout.fixed.horizontal,
      mylauncher,
      s.mytaglist,
      s.mypromptbox,
    },
    s.mytasklist, -- Middle widget
    { -- Right widgets
      layout = wibox.layout.fixed.horizontal,
      mykeyboardlayout,
      wibox.widget.systray(),
      volume_widget{
        widget_type = 'arc'
      },
      mytextclock,
      s.mylayoutbox,
    },
  }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
  awful.button({ }, 3, function () mymainmenu:toggle() end),
  awful.button({ }, 4, awful.tag.viewnext),
  awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join(
  awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
  {description="show help", group="awesome"}),
  awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
  {description = "view previous", group = "tag"}),
  awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
  {description = "view next", group = "tag"}),
  awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
  {description = "go back", group = "tag"}),

  awful.key({ modkey,           }, "j",
  function () awful.client.focus.byidx( 1) end,
  {description = "focus next", group = "client"}
  ),
  awful.key({ modkey,           }, "k",
  function () awful.client.focus.byidx(-1) end,
  {description = "focus previous", group = "client"}
  ),
  awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
  {description = "show main menu", group = "awesome"}),
  awful.key({ modkey,           }, "e",
  function () awful.spawn.with_shell("nautilus") end,
  {description = "open files", group = "awesome"}),

  -- screen saver
  awful.key({modkey, }, "F12", function()
    awful.spawn("xlock -mode blank")
  end, { description = "Lock screen", group = "clinet" }),

  -- Layout manipulation
  awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
  {description = "swap with next client by index", group = "client"}),
  awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
  {description = "swap with previous client by index", group = "client"}),
  awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
  {description = "focus the next screen", group = "screen"}),
  awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
  {description = "focus the previous screen", group = "screen"}),
  awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
  {description = "jump to urgent client", group = "client"}),
  awful.key({ modkey,           }, "Tab",
  function () awful.client.focus.byidx(1) end,
  {description = "go back", group = "client"}),

  -- Standard program
  awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
  {description = "open a terminal", group = "launcher"}),

  awful.key({ modkey, "Shift"   }, "Return", function () awful.spawn("kitty") end,
  {description = "open a terminal", group = "launcher"}),

  awful.key({ modkey, "Control" }, "r", awesome.restart,
  {description = "reload awesome", group = "awesome"}),

  awful.key({ modkey, "Shift"   }, "q", awesome.quit,
  {description = "quit awesome", group = "awesome"}),

  awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
  {description = "increase master width factor", group = "layout"}),
  awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
  {description = "decrease master width factor", group = "layout"}),
  awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
  {description = "increase the number of master clients", group = "layout"}),
  awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
  {description = "decrease the number of master clients", group = "layout"}),
  awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
  {description = "increase the number of columns", group = "layout"}),
  awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
  {description = "decrease the number of columns", group = "layout"}),
  awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
  {description = "select next", group = "layout"}),
  awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
  {description = "select previous", group = "layout"}),
  awful.key({ modkey,           }, "i",     function () toggle.tile_or_floating() end,
  {description = "tile the current tag", group = "layout"}),

  awful.key({ modkey, "Shift"   }, "Down",   function () client.focus:relative_move(0,  0,   0,    20) end),
  awful.key({ modkey, "Shift"   }, "Up",     function () client.focus:relative_move(0,  0,   0,   -20) end),
  awful.key({ modkey, "Shift"   }, "Left",   function () client.focus:relative_move(0,  0,   -20,   0) end),
  awful.key({ modkey, "Shift"   }, "Right",  function () client.focus:relative_move(0,  0,   20,    0) end),

  awful.key({ modkey, "Control" }, "n",
  function ()
    local c = awful.client.restore()
    -- Focus restored client
    if c then
      client.focus = c
      c:raise()
    end
  end,
  {description = "restore minimized", group = "client"}),

  -- Prompt
  awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
  {description = "run prompt", group = "launcher"}),

  awful.key({ modkey }, "x", function ()
    awful.prompt.run {
      prompt       = "Run Lua code: ",
      textbox      = awful.screen.focused().mypromptbox.widget,
      exe_callback = awful.util.eval,
      history_path = awful.util.get_cache_dir() .. "/history_eval"
    }
  end, {description = "lua execute prompt", group = "awesome"}),
  -- Menubar
  awful.key({ modkey }, "p", function() menubar.show() end,
  {description = "show the menubar", group = "launcher"}),

  awful.key({ modkey }, "[", function () awful.spawn("amixer -D pulse sset Master 5%-") end,
  {description = "increase volume", group = "custom"}),
  awful.key({ modkey }, "]", function () awful.spawn("amixer -D pulse sset Master 5%+") end,
  {description = "decrease volume", group = "custom"}),
  awful.key({ modkey }, "\\", function () awful.spawn("amixer -D pulse set Master +1 toggle") end,
  {description = "mute volume", group = "custom"}),

  awful.key({ modkey }, "a", function() awful.spawn.with_shell("sleep 0.2; scrot -s -o ~/_a_.png && xclip -selection c -t image/png ~/_a_.png") end,
  {description = "screenshot select area", group = "screenshot"}),
  awful.key({ modkey }, "c", function() awful.spawn.with_shell("sleep 0.2; scrot -u -o ~/_ac_.png") end,
  {description = "screenshot focus area", group = "screenshot"}),
  awful.key({ modkey }, "z", function() awful.spawn.with_shell("sleep 0.2; scrot -m -o ~/_az_.png") end,
  {description = "screenshot multidisp", group = "screenshot"}),
  awful.key({ modkey, "Mod1"}, "r", function() awful.spawn.with_shell("simplescreenrecorder") end,
  {description = "screancat", group = "screenshot"}),
  awful.key({modkey }, "'", function() awful.spawn.with_shell([[
    zenity --entry | xclip -rmlastnl -sel clip
    sleep 0.05
    xdotool key --window "$(xdotool getwindowfocus)" ctrl+v
    ]]) end, { description = "input CJK for steam", group = "steam"} )
)

local clientkeys = gears.table.join(
  awful.key({ modkey,           }, "f",
  function (c)
    c.fullscreen = not c.fullscreen
    c:raise()
  end,
  {description = "toggle fullscreen", group = "client"}),
  awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
  {description = "close", group = "client"}),
  awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
  {description = "toggle floating", group = "client"}),
  awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
  {description = "move to master", group = "client"}),
  awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
  {description = "move to screen", group = "client"}),
  awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
  {description = "toggle keep on top", group = "client"}),
  awful.key({ modkey,           }, "n",
  function (c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
  end ,
  {description = "minimize", group = "client"}),
  awful.key({ modkey,           }, "m",
  function (c)
    c.maximized = not c.maximized
    c:raise()
  end ,
  {description = "(un)maximize", group = "client"}),
  awful.key({ modkey, "Control" }, "m",
  function (c)
    c.maximized_vertical = not c.maximized_vertical
    c:raise()
  end ,
  {description = "(un)maximize vertically", group = "client"}),
  awful.key({ modkey, "Shift"   }, "m",
  function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c:raise()
  end ,
  {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  globalkeys = gears.table.join(globalkeys,
    -- View tag only.
    awful.key({ modkey }, "#" .. i + 9, function ()
      local screen = awful.screen.focused()
      local tag = screen.tags[i]
      if tag then
        tag:view_only()
      end
    end,
    {description = "view tag #"..i, group = "tag"}),
    -- Toggle tag display.
    awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
      local screen = awful.screen.focused()
      local tag = screen.tags[i]
      if tag then
        awful.tag.viewtoggle(tag)
      end
    end,
    {description = "toggle tag #" .. i, group = "tag"}),
    -- Move client to tag.
    awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
      if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
          client.focus:move_to_tag(tag)
        end
      end
    end,
    {description = "move focused client to tag #"..i, group = "tag"}),
    -- Toggle tag on focused client.
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
    function ()
      if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
          client.focus:toggle_tag(tag)
        end
      end
    end,
    {description = "toggle focused client on tag #" .. i, group = "tag"}),
    awful.key({"Control", }, "#" .. i + 9, function ()
      if client.focus then
        toggle.focus(i)
      end
    end,
    {description = "toggle ith focused client in current tag", group = "tag"})
  )
end

-- Set keys
root.keys(globalkeys)
-- }}}

local clientbuttons = gears.table.join(
  awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize))

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap+awful.placement.no_offscreen
    }
  },

  -- Floating clients.
  {
    rule_any = {
      instance = {
        "DTA",  -- Firefox addon DownThemAll.
        "copyq",  -- Includes session name in class.
      },
      class = {
        "Arandr",
        "Gpick",
        "Kruler",
        "MessageWin",  -- kalarm.
        "Sxiv",
        "Wpa_gui",
        "pinentry",
        "veromix",
        "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

      -- Add titlebars to normal clients and dialogs
      { rule_any = {type = { "normal", "dialog" }
    }, properties = { titlebars_enabled = true }
  },

  -- Set Firefox to always map on the tag named "2" on screen 1.
  { rule = { class = "gnome-terminal" },
  properties = { size_hints_honor = false } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
  -- Set the windows at the slave,
  -- i.e. put it at the end of others instead of setting it master.
  -- if not awesome.startup then awful.client.setslave(c) end

  if awesome.startup and
    not c.size_hints.user_position
    and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- buttons for the titlebar
  local buttons = gears.table.join(
    awful.button({ }, 1, function()
      client.focus = c
      c:raise()
      awful.mouse.client.move(c)
    end),
    awful.button({ }, 3, function()
      client.focus = c
      c:raise()
      awful.mouse.client.resize(c)
    end)
  )

  awful.titlebar(c):setup {
    { -- Left
      awful.titlebar.widget.iconwidget(c),
      buttons = buttons,
      layout  = wibox.layout.fixed.horizontal
    },
    { -- Middle
      { -- Title
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
      },
      buttons = buttons,
      layout  = wibox.layout.flex.horizontal
    },
    { -- Right
      awful.titlebar.widget.floatingbutton (c),
      awful.titlebar.widget.maximizedbutton(c),
      awful.titlebar.widget.stickybutton   (c),
      awful.titlebar.widget.ontopbutton    (c),
      awful.titlebar.widget.closebutton    (c),
      layout = wibox.layout.fixed.horizontal()
    },
    layout = wibox.layout.align.horizontal
  }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
  if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    and awful.client.focus.filter(c) then
    client.focus = c
  end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

autostart.init()
