-- ~/.config/hypr/hyprland.lua
--
-- Split config. Each file lives next to this one in ~/.config/hypr/.
-- Order matters: env before autostart, so launched apps inherit the vars.
--
-- Original untouched default is kept at hyprland.lua.bak
-- Check for errors after editing:  hyprctl reload && hyprctl configerrors

require("env")
require("monitors")
require("looks")
require("input")
require("rules")
require("binds")
require("autostart")
