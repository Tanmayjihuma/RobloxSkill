local MusicService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local SONG_GAP = 0.5 -- seconds of silence between songs


-- One SoundGroup controls all music volume (the settings UI uses this)
function MusicService.GetGroup()
	local group = SoundService:FindFirstChild("LocalMusicGroup")
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = "LocalMusicGroup"
		group.Parent = SoundService
	end
	return group
end

-- SERVER

--function MusicService._Init()
--	local ServerStorage = game:GetService("ServerStorage")
--	local songs = ServerStorage:WaitForChild("GameMusic"):GetChildren()
--	if #songs == 0 then
--		warn("MusicService: no songs in ServerStorage.GameMusic")
--		return
--	end

--	task.spawn(function()
--		local last
--		while true do
--			local song = songs[math.random(1, #songs)]
--			if #songs > 1 and song == last then
--				continue
--			end
--			last = song

--			ContentProvider:PreloadAsync({ song })
--			if song.IsLoaded and song.TimeLength > 0 then
--				ReplicatedStorage:SetAttribute("MusicId", song.SoundId)
--				ReplicatedStorage:SetAttribute("MusicLength", song.TimeLength)
--				ReplicatedStorage:SetAttribute("MusicStart", workspace:GetServerTimeNow()) -- set last, it's the trigger
--				task.wait(song.TimeLength + 2)
--			else
--				warn("MusicService: failed to load " .. song.Name .. ", skipping")
--				task.wait(1)
--			end
--		end
--	end)
--end
function MusicService._Init()
	local ServerStorage = game:GetService("ServerStorage")
	local songs = ServerStorage:WaitForChild("GameMusic"):GetChildren()
	if #songs == 0 then
		warn("MusicService: no songs in ServerStorage.GameMusic")
		return
	end

	local function pickSong(last)
		if #songs == 1 then return songs[1] end
		local song
		repeat
			song = songs[math.random(1, #songs)]
		until song ~= last
		return song
	end

	local function load(song)
		ContentProvider:PreloadAsync({ song })
		return song.IsLoaded and song.TimeLength > 0
	end

	task.spawn(function()
		local current = pickSong(nil)

		while true do
			if not load(current) then
				warn("MusicService: failed to load " .. current.Name .. ", skipping")
				current = pickSong(current)
				task.wait(1)
				continue
			end

			local length = current.TimeLength
			local startedAt = os.clock()

			ReplicatedStorage:SetAttribute("MusicId", current.SoundId)
			ReplicatedStorage:SetAttribute("MusicLength", length)
			ReplicatedStorage:SetAttribute("MusicStart", workspace:GetServerTimeNow()) -- set last, it's the trigger

			-- Pick the NEXT song now and load it while this one plays.
			local nextSong = pickSong(current)
			ReplicatedStorage:SetAttribute("MusicNextId", nextSong.SoundId) -- clients preload this
			load(nextSong)

			-- Wait only for what's left of the current song.
			local remaining = length - (os.clock() - startedAt)
			task.wait(math.max(remaining, 0) + SONG_GAP)

			current = nextSong
		end
	end)
end


-- CLIENT
function MusicService._init()
	local group = MusicService.GetGroup()

	local sound = SoundService:FindFirstChild("LocalGameMusic")
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "LocalGameMusic"
		sound.Volume = 1
		sound.SoundGroup = group
		sound.Parent = SoundService
	end

	local function preloadNext()
		local nextId = ReplicatedStorage:GetAttribute("MusicNextId")
		if not nextId then return end

		local temp = Instance.new("Sound")
		temp.SoundId = nextId
		ContentProvider:PreloadAsync({ temp })
		temp:Destroy()
	end


	local token = 0
	local function playCurrent()
		local id = ReplicatedStorage:GetAttribute("MusicId")
		local start = ReplicatedStorage:GetAttribute("MusicStart")
		local length = ReplicatedStorage:GetAttribute("MusicLength")
		if not id or not start then return end

		token += 1
		local myToken = token

		sound:Stop()
		sound.SoundId = id
		sound:Play()

		-- joined mid-song? jump to where everyone else is
		local elapsed = workspace:GetServerTimeNow() - start
		if length and elapsed > 2 and elapsed < length then
			if not sound.IsLoaded then sound.Loaded:Wait() end
			if myToken == token then
				sound.TimePosition = elapsed
			end
		end
	end

	ReplicatedStorage:GetAttributeChangedSignal("MusicStart"):Connect(playCurrent)
	ReplicatedStorage:GetAttributeChangedSignal("MusicNextId"):Connect(function()
		task.spawn(preloadNext)
	end)
	
	task.spawn(preloadNext)
	task.spawn(playCurrent)
end

return MusicService



--- also the local client for settings (added for example)

--[[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SettingsGui = PlayerGui:WaitForChild("Settings")
local MainFrame = SettingsGui:WaitForChild("MainFrame")
local OpenButton = SettingsGui:WaitForChild("OpenButton")

local TitleFrame = MainFrame:WaitForChild("TitleFrame")
local CloseButton = TitleFrame:WaitForChild("CloseButton")

local MusicFrame = MainFrame:WaitForChild("MusicFrame")
local MusicBar = MusicFrame:WaitForChild("MusicBar")
local SlidingButton = MusicBar:WaitForChild("SlidingButton")
local MuteButton = MusicBar:WaitForChild("MuteButton")

local autoCloseGuis = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Settings")).MainFrameGui

local basicSFX = SoundService:WaitForChild("BasicSFX")
local hoverSound = basicSFX:WaitForChild("UiHover")
local clickSound = basicSFX:WaitForChild("UiClick")
local closeClickSound = basicSFX:WaitForChild("UiCloseClick")

local menuSizes = {}

local MusicService = require(ReplicatedStorage:WaitForChild("SharedScripts"):WaitForChild("MusicService"))
local musicGroup = MusicService.GetGroup()

local currentVolume = musicGroup:GetAttribute("UserVolume") or 1
local isMuted = musicGroup:GetAttribute("UserMuted") or false

local MenuUtils = require(ReplicatedStorage:WaitForChild("SharedScripts"):WaitForChild("MenuUtils"))

-- As early as possible, right after MainFrame = ...WaitForChild(...):
-- Exact size of StarterGui.Settings.MainFrame (scale-only, window-independent)
MenuUtils.CacheSize(MainFrame, UDim2.fromScale(0.259340674, 0.665312767))


local function OpenMenu(targetMainFrame)
	for _, guiName in ipairs(autoCloseGuis) do
		local gui = PlayerGui:FindFirstChild(guiName)
		if gui and gui:IsA("ScreenGui") then
			local frame = gui:FindFirstChild("MainFrame")
			if frame and frame ~= targetMainFrame then frame.Visible = false end
		end
	end

	if not menuSizes[targetMainFrame] then
		menuSizes[targetMainFrame] = targetMainFrame.Size
	end

	targetMainFrame.Size = UDim2.new(0, 0, 0, 0)
	targetMainFrame.Visible = true

	TweenService:Create(targetMainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = menuSizes[targetMainFrame]}):Play()
end

local function CloseMenu(targetMainFrame)
	local closeTween = TweenService:Create(targetMainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
	closeTween:Play()
	closeTween.Completed:Wait()
	targetMainFrame.Visible = false
end

--OpenButton.MouseButton1Click:Connect(function()
--	--if clickSound then clickSound:Play() end
--	if MainFrame.Visible then
--		CloseMenu(MainFrame)
--	else
--		OpenMenu(MainFrame)
--	end
--end)

--CloseButton.MouseButton1Click:Connect(function()
--	--if closeClickSound then closeClickSound:Play() end
--	CloseMenu(MainFrame)
--end)

OpenButton.MouseButton1Click:Connect(function()
	if MainFrame.Visible then
		MenuUtils.Close(MainFrame)
	else
		MenuUtils.Open(MainFrame, { playerGui = PlayerGui, autoCloseGuis = autoCloseGuis })
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	MenuUtils.Close(MainFrame)
end)

local function bindHover(btn)
	local originalSize = btn.Size
	btn.MouseEnter:Connect(function()
		if hoverSound then hoverSound:Play() end
		TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, originalSize.Y.Scale * 1.05, originalSize.Y.Offset)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {Size = originalSize}):Play()
	end)
end
--bindHover(OpenButton)
--bindHover(MuteButton)


local isDragging = false



local function ApplyMusicVolume(vol)
	musicGroup:SetAttribute("UserVolume", vol)
	musicGroup:SetAttribute("UserMuted", isMuted)
	musicGroup.Volume = isMuted and 0 or vol
end

local function updateSlider(input)
	local barSize = MusicBar.AbsoluteSize.X
	local barPos = MusicBar.AbsolutePosition.X
	local mousePos = input.Position.X

	local percentage = math.clamp((mousePos - barPos) / barSize, 0, 1)

	TweenService:Create(SlidingButton, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(percentage, 0, SlidingButton.Position.Y.Scale, SlidingButton.Position.Y.Offset)
	}):Play()

	currentVolume = percentage

	if not isMuted then
		ApplyMusicVolume(currentVolume)
	end
end

SlidingButton.MouseButton1Down:Connect(function() isDragging = true end)
--MusicBar.MouseButton1Down:Connect(function() isDragging = true end)

-- Handle Mouse/Touch movement
UserInputService.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

MuteButton.MouseButton1Click:Connect(function()
	if clickSound then clickSound:Play() end
	isMuted = not isMuted

	if isMuted then
		MuteButton.Text = "UNMUTE"
		MuteButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- Turn Gray
		ApplyMusicVolume(0)
	else
		MuteButton.Text = "MUTE"
		MuteButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Turn Red
		ApplyMusicVolume(currentVolume)
	end
end)

MuteButton.Text = isMuted and "UNMUTE" or "MUTE"
MuteButton.BackgroundColor3 = isMuted and Color3.fromRGB(120,120,120) or Color3.fromRGB(255,0,0)
ApplyMusicVolume(currentVolume)
SlidingButton.Position = UDim2.new(currentVolume, 0, SlidingButton.Position.Y.Scale, SlidingButton.Position.Y.Offset)

]]




