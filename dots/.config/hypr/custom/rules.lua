-- Re-enable compositor blur for kitty (hyprland/rules.lua disables blur for every window;
-- kitty's own background_blur only works on macOS/KWin)
hl.window_rule({ match = { class = "^(kitty)$" }, no_blur = false })
