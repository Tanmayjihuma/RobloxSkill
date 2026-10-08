--[[
	MenuUtils.lua (ModuleScript)
	----------------------------
	Shared, race-safe Open/Close animator for MainFrame-style popups.

	Fixes the "size stuck at 0" bug present in the Daily / Teleporter / Rebirth /
	Settings / Shop / LuckMachine-Meteor scripts:

	OLD (unsafe) pattern used in those scripts:
		if not menuSizes[targetMainFrame] then
			menuSizes[targetMainFrame] = targetMainFrame.Size
		end

	UDim2.new(0,0,0,0) is a perfectly valid, non-nil Lua value. The check above
	only asks "have we cached ANYTHING yet", not "is what we cached usable". If
	targetMainFrame.Size is already (0,0,0,0) the FIRST time OpenMenu ever runs
	for that frame (e.g. a "hide all menus on spawn" script also zeroed .Size
	instead of only .Visible), that zero gets cached forever. Every later
	"open" tween then animates 0 -> 0: Visible = true, but permanently
	invisible.

	This module never caches (0,0,0,0), falls back safely if a real size truly
	isn't available yet, and cancels/tokens tweens so rapid open/close spam
	can't leave two tweens fighting over the same property.

	Place under ReplicatedStorage.SharedScripts (or wherever your other shared
	modules live) and `require` it from each menu script.
]]

local TweenService = game:GetService("TweenService")

local OPEN_TWEEN_INFO  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local ZERO = UDim2.new(0, 0, 0, 0)

local MenuUtils = {}


local menuSizes   = setmetatable({}, { __mode = "k" })
local menuToken   = setmetatable({}, { __mode = "k" })
local activeTween = setmetatable({}, { __mode = "k" })

local function isZeroSize(s)
	return s.X.Scale == 0 and s.X.Offset == 0 and s.Y.Scale == 0 and s.Y.Offset == 0
end

--- Caches a frame's current Size UNLESS it's already cached or is currently
--- (0,0,0,0). Call this once per frame as early as possible in each script
--- (right after WaitForChild-ing the frame, before anything else can run).
--- @param frame GuiObject
--- @param fallback UDim2? -- used only if the live size is zero AND nothing cached yet
function MenuUtils.CacheSize(frame, fallback)
	if menuSizes[frame] then return menuSizes[frame] end

	local live = frame.Size
	if not isZeroSize(live) then
		menuSizes[frame] = live
		return live
	end

	if fallback then
		menuSizes[frame] = fallback
		return fallback
	end

	return nil -- caller must retry later or accept the generic fallback in Open()
end

local function closeOthers(playerGui, autoCloseGuis, except)
	for _, guiName in ipairs(autoCloseGuis) do
		local gui = playerGui:FindFirstChild(guiName)
		if gui and gui:IsA("ScreenGui") then
			local frame = gui:FindFirstChild("MainFrame")
			if frame and frame ~= except then
				frame.Visible = false
			end
		end
	end
end

--- Opens (tweens 0 -> cached size) a menu frame.
--- opts: { playerGui, autoCloseGuis, bgFrame, fallback, openTweenInfo }
function MenuUtils.Open(frame, opts)
	opts = opts or {}
	if not frame then return end

	if opts.playerGui and opts.autoCloseGuis then
		closeOthers(opts.playerGui, opts.autoCloseGuis, frame)
	end

	local goal = MenuUtils.CacheSize(frame, opts.fallback)
	if not goal then
		-- Truly never had a good size to work with. Don't get stuck at 0 --
		-- use a safe default and remember it so behaviour stays consistent.
		goal = opts.fallback or UDim2.fromScale(0.5, 0.5)
		menuSizes[frame] = goal
	end

	menuToken[frame] = (menuToken[frame] or 0) + 1
	local myToken = menuToken[frame]

	local running = activeTween[frame]
	if running then
		running:Cancel()
		activeTween[frame] = nil
	end

	if opts.bgFrame then opts.bgFrame.Visible = true end

	frame.Size = ZERO
	frame.Visible = true

	local tw = TweenService:Create(frame, opts.openTweenInfo or OPEN_TWEEN_INFO, { Size = goal })
	activeTween[frame] = tw
	tw.Completed:Connect(function()
		if menuToken[frame] ~= myToken then return end
		activeTween[frame] = nil
		frame.Size = goal
	end)
	tw:Play()
end

--- Closes (tweens cached size -> 0, then hides) a menu frame.
--- opts: { bgFrame, fallback, closeTweenInfo }
function MenuUtils.Close(frame, opts)
	opts = opts or {}
	if not frame then return end
	if not frame.Visible then
		if opts.bgFrame then opts.bgFrame.Visible = false end
		return
	end

	MenuUtils.CacheSize(frame, opts.fallback) -- remember the size we're closing FROM

	menuToken[frame] = (menuToken[frame] or 0) + 1
	local myToken = menuToken[frame]

	local running = activeTween[frame]
	if running then
		running:Cancel()
		activeTween[frame] = nil
	end

	local tw = TweenService:Create(frame, opts.closeTweenInfo or CLOSE_TWEEN_INFO, { Size = ZERO })
	activeTween[frame] = tw
	tw.Completed:Connect(function()
		if menuToken[frame] ~= myToken then return end -- reopened mid-close: abort the hide
		activeTween[frame] = nil
		frame.Visible = false
		frame.Size = menuSizes[frame] or frame.Size
		if opts.bgFrame then opts.bgFrame.Visible = false end
	end)
	tw:Play()
end

function MenuUtils.OpenInstant(frame, opts)
	opts = opts or {}
	if not frame then return end

	if opts.playerGui and opts.autoCloseGuis then
		closeOthers(opts.playerGui, opts.autoCloseGuis, frame)
	end

	local goal = MenuUtils.CacheSize(frame, opts.fallback)
	if not goal then
		goal = opts.fallback or UDim2.fromScale(0.5, 0.5)
		menuSizes[frame] = goal
	end

	menuToken[frame] = (menuToken[frame] or 0) + 1 -- invalidate any in-flight tween callback

	local running = activeTween[frame]
	if running then
		running:Cancel()
		activeTween[frame] = nil
	end

	if opts.bgFrame then opts.bgFrame.Visible = true end

	frame.Size = goal
	frame.Visible = true
end

return MenuUtils
