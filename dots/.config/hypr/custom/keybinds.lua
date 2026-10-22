---@diagnostic disable: undefined-global
hl.bind(
	"CTRL+SUPER+ALT+Slash",
	hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
	{ description = "Edit user keybinds" }
)

hl.bind("SUPER + SHIFT + Q", hl.dsp.global("quickshell:sessionToggle"), { description = "Shell: Toggle session menu" })

-- focus by direction
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

for i = 1, 4 do
	local arrowkey = { "H", "L", "K", "J" }
	local focusdir = { "l", "r", "u", "d" }
	hl.bind(
		"SUPER + " .. arrowkey[i],
		hl.dsp.focus({ direction = focusdir[i] }),
		{ description = "Window: Focus " .. arrowkey[i] }
	)
end

-- lock
hl.unbind("SUPER + SHIFT + L")
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Session: Lock" })

hl.bind("CTRL + SUPER + B", hl.dsp.global("quickshell:barToggle"), { description = "Shell: Toggle bar" })

-- Windows
hl.unbind("SUPER + M")
hl.bind(
	"SUPER + M",
	-- On floating workspaces this resizes instead of using the fullscreen layer (see layoutmodes.lua)
	function()
		require("custom.layoutmodes").toggleMaximize()
	end,
	{ description = "Window: Maximize" }
)

hl.bind("SHIFT + SUPER + C", hl.dsp.window.close(), { description = "Window: Close" })

-- Alt+Tab (most recent first) and per-workspace layout modes
require("custom.alttab")
require("custom.layoutmodes")
