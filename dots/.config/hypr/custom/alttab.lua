---@diagnostic disable: undefined-global
-- Alt+Tab / Alt+Shift+Tab: switch windows of the current workspace in most-recently-used order.
-- Keep Alt held and press Tab repeatedly to go further back; releasing Alt commits the choice.

local ALT_KEYS = { "Alt_L", "Alt_R", "Meta_L", "Meta_R" } -- Shift+Alt can register as Meta
local POLL_MS = 25

local cycle = nil -- { windows = { HL.Window... }, index = integer, steps = integer }
local releaseTimer = nil

local function altHeld()
	for _, key in ipairs(ALT_KEYS) do
		if hl.is_key_down(key) then
			return true
		end
	end
	return false
end

local function focusWindow(w)
	pcall(function()
		if w.mapped then
			hl.dispatch(hl.dsp.focus({ window = w }))
			if w.floating then
				-- Focusing alone doesn't raise a floating window above newer ones
				hl.dispatch(hl.dsp.window.bring_to_top())
			end
		end
	end)
end

-- Windows of the focused window's workspace (works inside the scratchpad too), most recent first
local function windowsByRecency()
	local active = hl.get_active_window()
	local ws = (active and active.workspace) or hl.get_active_workspace()
	if not ws then
		return {}
	end

	local list = {}
	for _, w in ipairs(hl.get_workspace_windows(ws)) do
		if w.mapped and not w.hidden and w.accepts_input then
			table.insert(list, w)
		end
	end
	local function rank(w)
		local id = w.focus_history_id
		return (id and id >= 0) and id or math.huge
	end
	table.sort(list, function(a, b)
		return rank(a) < rank(b)
	end)
	return list
end

local function finish()
	if releaseTimer then
		releaseTimer:set_enabled(false)
	end
	local c = cycle
	cycle = nil
	if not c or c.steps < 2 then
		return -- a single step already leaves the focus history in the right order
	end

	-- Every window we passed through got pushed up the focus history. Rebuild it so the picked
	-- window comes first and the others keep their previous order (like KDE/GNOME).
	local picked = c.windows[c.index]
	local order = { picked }
	for i, w in ipairs(c.windows) do
		if i ~= c.index then
			table.insert(order, w)
		end
	end
	for i = #order, 1, -1 do
		focusWindow(order[i])
	end
end

local function step(direction)
	if not cycle then
		local windows = windowsByRecency()
		if #windows < 2 then
			return
		end
		cycle = { windows = windows, index = 1, steps = 0 }

		if not releaseTimer then
			releaseTimer = hl.timer(function()
				if cycle and not altHeld() then
					finish()
				end
			end, { timeout = POLL_MS, type = "repeat" })
		end
		releaseTimer:set_enabled(true)
	end

	local n = #cycle.windows
	cycle.index = (cycle.index - 1 + direction) % n + 1
	cycle.steps = cycle.steps + 1
	focusWindow(cycle.windows[cycle.index])
end

hl.bind("ALT + Tab", function()
	step(1)
end, { description = "Window: Switch to previous (most recent first)" })
hl.bind("ALT + SHIFT + Tab", function()
	step(-1)
end, { description = "Window: Switch, reverse order" })
