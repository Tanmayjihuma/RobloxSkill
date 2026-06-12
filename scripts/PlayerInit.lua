
--1 laoding basic things and models 
local Players = game:GetService("Players")
local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
local Player = Players.LocalPlayer
local Systems = StarterPlayer:WaitForChild("Systems")
local Services = StarterPlayer:WaitForChild("Services")
local GameSystem = require(Systems:WaitForChild("GameSystem"))
local MusicService = require(Services.MusicService)
local ProximityPromptService= game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")
 
local ObbyEffect = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("ObbyEffect")

local IsLoaded = false

-- 2 basic models init
GameSystem.init()
task.spawn(function()
	MusicService._init()
end)

--EXAMPLE
local function trackSittingState(character)
end

-- 3 on player character (example) (for some rare cases --keep in mind sometimes using same on player.character and player.character added cause it call 2 times but we need only one call so make a variable to block it )
-- never leave things alone to Player.Character cuz sometimes is not loaded so use player.Character added and keep rememember thing i said above
if Player.Character then
	trackSittingState(Player.Character)
end

Player.CharacterAdded:Connect(trackSittingState)

Player.CharacterRemoving:Connect(function()
    -- for example 
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local PP = PlayerGui:FindFirstChild("ProximityPrompts")
	if PP then
		PP:Destroy()
	end
    
end)

