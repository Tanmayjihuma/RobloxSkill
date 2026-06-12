-- 1. Loading basic things and services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer") 
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Player = Players.LocalPlayer

-- Yield until scripts are available (good practice for client scripts)
local Systems = StarterPlayer:WaitForChild("Systems", 5)
local Services = StarterPlayer:WaitForChild("Services", 5)

-- Assuming these exist in your game structure (FOR EXAMPLE)
	local GameSystem = require(Systems:WaitForChild("GameSystem"))
	local MusicService = require(Services:WaitForChild("MusicService"))

local ObbyEffect = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("ObbyEffect")

-- 2. Basic models init
	GameSystem._init()
	task.spawn(function()
		MusicService._init()
	end)

-- Use this flag to ensure "run once" functions truly only run the FIRST time the character loads.
local hasInitializedOnce = false

-- Runs every single time the player respawns
local function RunEveryTimeCharacterLoads(character)
	-- CAN BE PUT IN RESPAWN HANDLER BUT ITS DEPENDS 
	-- YOUR CODE
end

-- Runs ONLY the very first time the player's character loads
local function RunOnceOnFirstCharacterLoad(character)
	if hasInitializedOnce then return end
	hasInitializedOnce = true
	-- YOUR CODE
end

-- Master function to handle character setup
local function OnCharacterAdded(character)
	RunEveryTimeCharacterLoads(character)
	RunOnceOnFirstCharacterLoad(character)
end

-- 3. The "Already Loaded vs Added" Pattern
-- Sometimes the script loads slightly AFTER the character already exists in the world.
-- We must check if it exists right now, AND listen for future spawns.
if Player.Character then
 	OnCharacterAdded(Player.Character)
end

-- Listen for all future respawns 
Player.CharacterAdded:Connect(OnCharacterAdded)

-- 4. Cleanup on death/removal
Player.CharacterRemoving:Connect(function(character)
	-- SOME CLEARNING ,PLAYER REMOVING STUFF 
end)
