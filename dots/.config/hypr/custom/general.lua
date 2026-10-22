-- Keyboard layouts (same as the GNOME setup): Alt+Shift switches us/ru,
-- Caps Lock and Ctrl swapped, Right Alt is Compose
hl.config({
	input = {
		kb_layout = "us,ru",
		kb_options = "grp:alt_shift_toggle,ctrl:swapcaps,compose:ralt",
	},
})

-- blur size
hl.config({ decoration = { blur = { size = 6 } } })

-- disable focus stealing
hl.config({ misc = { focus_on_activate = false } })
