---@diagnostic disable: undefined-global
-- Per-workspace layout modes, awesomewm style: Super+Shift+Space cycles the current workspace
-- through dwindle -> floating -> scrolling.
--  * floating: every window on the workspace floats, new windows open floating. Windows floated
--    by this mode (tagged "layoutfloat") go back to tiling when the workspace leaves the mode
--    or when they are moved to a workspace in another mode. New windows are placed where they
--    don't overlap others (like awful.placement.no_overlap) instead of the screen center.
--  * The current mode is shown on the Quickshell bar (click it to cycle).
--  * Modes are kept in $XDG_RUNTIME_DIR, so they survive config reloads but not a new session.

local MODES = { "dwindle", "floating", "scrolling" }
local TAG = "layoutfloat"
local STATE_FILE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-layoutmodes"

local modes = {} -- [workspace id] = "floating" | "scrolling" (absent = dwindle)
local scrollRules = {} -- [workspace id] = workspace rule with layout = "scrolling"
-- Floats new windows before they are mapped (so they keep their own size). Enabled only while
-- the active workspace is in floating mode: a workspace match in the rule isn't reliable.
local floatNewRule = hl.window_rule({ name = "layoutmodes-float-new", match = { class = ".*" }, float = true, enabled = false })

local PLACEMENT_GAP = 12 -- distance from screen edges, logical px
local PLACEMENT_STEP = 20 -- grid step when looking for a free spot

local function modeOf(ws)
	return (ws and modes[ws.id]) or "dwindle"
end

local function saveState()
	local f = io.open(STATE_FILE, "w")
	if not f then
		return
	end
	for id, mode in pairs(modes) do
		f:write(string.format("%d %s\n", id, mode))
	end
	f:close()
end

local function loadState()
	local f = io.open(STATE_FILE, "r")
	if not f then
		return
	end
	for line in f:lines() do
		local id, mode = line:match("^(-?%d+) (%a+)$")
		if id and (mode == "floating" or mode == "scrolling") then
			modes[tonumber(id)] = mode
		end
	end
	f:close()
end

local function isAutoFloated(w)
	for _, tag in ipairs(w.tags or {}) do
		if tag == TAG then
			return true
		end
	end
	return false
end

local function setFloating(w, enable)
	pcall(function()
		hl.dispatch(hl.dsp.window.float({ action = enable and "enable" or "disable", window = w }))
		hl.dispatch(hl.dsp.window.tag({ tag = (enable and "+" or "-") .. TAG, window = w }))
	end)
end

local function updateRules(id)
	local mode = modes[id] or "dwindle"
	scrollRules[id] = scrollRules[id]
		or hl.workspace_rule({ workspace = tostring(id), layout = "scrolling", enabled = false })
	scrollRules[id]:set_enabled(mode == "scrolling")
end

-- Usable monitor area in logical coordinates (without the bar and other reserved space)
local function workArea(mon)
	local r = mon.reserved or {}
	local scale = mon.scale or 1
	local left, right, top, bottom = r.left or 0, r.right or 0, r.top or 0, r.bottom or 0
	return {
		x = mon.x + left,
		y = mon.y + top,
		w = mon.width / scale - left - right,
		h = mon.height / scale - top - bottom,
	}
end

local function overlapArea(x, y, w, h, b)
	local x1, y1 = math.max(x, b.x), math.max(y, b.y)
	local x2, y2 = math.min(x + w, b.x + b.w), math.min(y + h, b.y + b.h)
	if x2 <= x1 or y2 <= y1 then
		return 0
	end
	return (x2 - x1) * (y2 - y1)
end

-- Like awful.placement.no_overlap + no_offscreen: first spot (top-left to bottom-right) that
-- doesn't cover other windows, or the least covering one
local function placeWindow(w)
	local mon = w.monitor or hl.get_active_monitor()
	if not mon or not w.workspace then
		return
	end
	local area = workArea(mon)
	local maxW, maxH = area.w - 2 * PLACEMENT_GAP, area.h - 2 * PLACEMENT_GAP
	local width, height = w.size.x, w.size.y

	-- Windows without a preferred size come out stretched to the whole screen height
	if width >= maxW * 0.9 or height >= maxH * 0.9 then
		width, height = math.floor(maxW * 0.55), math.floor(maxH * 0.65)
	end
	width, height = math.min(width, maxW), math.min(height, maxH)

	local others = {}
	for _, o in ipairs(hl.get_workspace_windows(w.workspace)) do
		if o.address ~= w.address and o.mapped and not o.hidden then
			table.insert(others, { x = o.at.x, y = o.at.y, w = o.size.x, h = o.size.y })
		end
	end

	local bestX, bestY, bestOverlap = area.x + PLACEMENT_GAP, area.y + PLACEMENT_GAP, math.huge
	for y = area.y + PLACEMENT_GAP, area.y + area.h - PLACEMENT_GAP - height, PLACEMENT_STEP do
		for x = area.x + PLACEMENT_GAP, area.x + area.w - PLACEMENT_GAP - width, PLACEMENT_STEP do
			local total = 0
			for _, o in ipairs(others) do
				total = total + overlapArea(x, y, width, height, o)
				if total >= bestOverlap then
					break
				end
			end
			if total < bestOverlap then
				bestX, bestY, bestOverlap = x, y, total
			end
			if total == 0 then
				goto done
			end
		end
	end
	::done::

	pcall(function()
		if width ~= w.size.x or height ~= w.size.y then
			hl.dispatch(hl.dsp.window.resize({ x = width, y = height, window = w }))
		end
		hl.dispatch(hl.dsp.window.move({ x = bestX, y = bestY, window = w }))
	end)
end

local function syncFloatRule()
	floatNewRule:set_enabled(modeOf(hl.get_active_workspace()) == "floating")
end

local function applyMode(ws, mode)
	local old = modeOf(ws)
	if old == mode then
		return
	end
	modes[ws.id] = (mode ~= "dwindle") and mode or nil
	saveState()
	updateRules(ws.id)
	syncFloatRule()

	for _, w in ipairs(hl.get_workspace_windows(ws)) do
		if mode == "floating" and not w.floating then
			setFloating(w, true)
		elseif mode ~= "floating" and w.floating and isAutoFloated(w) then
			setFloating(w, false)
		end
	end
end

local function cycleMode()
	local active = hl.get_active_window()
	local ws = (active and active.workspace) or hl.get_active_workspace()
	if not ws then
		return
	end
	local current = modeOf(ws)
	local next = MODES[1]
	for i, m in ipairs(MODES) do
		if m == current then
			next = MODES[i % #MODES + 1]
			break
		end
	end
	applyMode(ws, next)
end

-- Restore modes after a config reload; the file also tells the Quickshell bar indicator
-- (LayoutModeIndicator.qml) that this module is active
loadState()
saveState()
for id in pairs(modes) do
	updateRules(id)
end
syncFloatRule()
hl.on("workspace.active", syncFloatRule)

-- New windows on a floating workspace (floated by floatNewRule, or here if they were opened
-- onto it in the background) get a spot that doesn't cover other windows
hl.on("window.open", function(w)
	if w and modeOf(w.workspace) == "floating" and not isAutoFloated(w) then
		setFloating(w, true)
		placeWindow(w)
	end
end)

-- Windows moved between workspaces follow the target workspace's mode
hl.on("window.move_to_workspace", function(w, ws)
	if not w or not ws then
		return
	end
	if modeOf(ws) == "floating" then
		if not w.floating then
			setFloating(w, true)
		end
	elseif isAutoFloated(w) and w.floating then
		setFloating(w, false)
	end
end)

-- Maximize on floating workspaces, awesomewm style: the window is just resized to the work area
-- and stays an ordinary floating window. Hyprland's own "maximized" is a fullscreen state with its
-- own layer, so such a window couldn't be raised above or lowered below other floating windows.
local savedGeometry = {} -- [window address] = { x, y, w, h } before maximizing

local function isNear(a, b)
	return math.abs(a - b) <= 2
end

local function toggleMaximize()
	local w = hl.get_active_window()
	if not w then
		return
	end
	if modeOf(w.workspace) ~= "floating" or not w.floating then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
		return
	end
	-- Left over from before the workspace switched to floating mode: drop that state first
	if (w.fullscreen or 0) ~= 0 then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = w.fullscreen == 1 and "maximized" or "fullscreen", action = "toggle", window = w }))
	end

	local mon = w.monitor or hl.get_active_monitor()
	if not mon then
		return
	end
	local area = workArea(mon)
	local saved = savedGeometry[w.address]
	local maximized = saved
		and isNear(w.at.x, area.x) and isNear(w.at.y, area.y)
		and isNear(w.size.x, area.w) and isNear(w.size.y, area.h)

	pcall(function()
		if maximized then
			savedGeometry[w.address] = nil
			hl.dispatch(hl.dsp.window.resize({ x = saved.w, y = saved.h, window = w }))
			hl.dispatch(hl.dsp.window.move({ x = saved.x, y = saved.y, window = w }))
		else
			savedGeometry[w.address] = { x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
			hl.dispatch(hl.dsp.window.move({ x = area.x, y = area.y, window = w }))
			hl.dispatch(hl.dsp.window.resize({ x = area.w, y = area.h, window = w }))
			hl.dispatch(hl.dsp.window.bring_to_top({ window = w }))
		end
	end)
end

hl.on("window.close", function(w)
	if w then
		savedGeometry[w.address] = nil
	end
end)

hl.bind("SUPER + SHIFT + Space", cycleMode, { description = "Workspace: Cycle layout mode (dwindle/floating/scrolling)" })

return { applyMode = applyMode, modeOf = modeOf, cycleMode = cycleMode, toggleMaximize = toggleMaximize }
