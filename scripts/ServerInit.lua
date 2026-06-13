-- 1. Defining Basic Services
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")


local Services = ServerScriptService:WaitForChild("Services")
local Systems = ServerScriptService:WaitForChild("Systems")

-- Require core services
local AutoDataSavingService = require(Services:WaitForChild("DataManager"):WaitForChild("AutoDataSavingService"))
local MonotizationService = require(Services:WaitForChild("MonotizationService"))
local DataService = require(Services:WaitForChild("DataManager"):WaitForChild("DataService"))
--local LeaderstatsService = require(Services:WaitForChild("LeaderstatsService"))
local OrdinaryDataService = require(Services:WaitForChild("DataManager"):WaitForChild("OrdinaryDataService"))
--local MusicService = require(Services:WaitForChild("MusicService"))

-- 2. (IMP) Remote that confirms race condition onClientEvent or important script stuff loaded
local GuiLoadedRemote = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("OnClientEventLoaded")

-- 3. Defining required Modules
local Config = ReplicatedStorage:WaitForChild("Config")
local DefaultData = require(Config:WaitForChild("DefaultData"))
local RespawnHandler = require(Systems:WaitForChild("RespawnHandler"))

-- Example Game Systems
-- local GameSystem1 = require(Systems:WaitForChild("gamesystem1"))
-- local GameSystem2 = require(Systems:WaitForChild("gamesystem2"))
-- local GameSystem3 = require(Systems:WaitForChild("gamesystem3"))
-- local EXAMPLE_SERVICE = require(Services:WaitForChild("EXAMPLE_SERVICE"))

-- 4. Defining variables from workspace
local SpawnPart = workspace:WaitForChild("SpawnPart")
-- Example Global Leaderboards
-- local Win_Global_Leaderstate = workspace:WaitForChild("OtherStuff"):WaitForChild("Win_Leaderboard")
-- local Streak_Global_Leaderstate = workspace:WaitForChild("OtherStuff"):WaitForChild("Streak_Leaderboard")

-- 5. Loaded data checker
_G.DataLoaded = {}

-- 6. Disabling some features (Data must load before spawn)
Players.CharacterAutoLoads = false

-- ==========================================
-- 7. Server _Init (Initing main functions)
-- ==========================================

-- Helper function to safely init modules without crashing the main thread
local function SafeInit(moduleName, initFunction)
	task.spawn(function()
		local success, err = pcall(initFunction)
		if not success then
			warn("CRITICAL ERROR: Failed to initialize " .. moduleName .. " | Error: " .. tostring(err))
		end
	end)
end
-- the core gameplay function not need safeInit or task.spawn
-- GameSystem1._Init()
mon
-- SafeInit("GameSystem2", function() GameSystem2._Init() end)
--SafeInit("MusicService", function()
	--MusicService._Init()
--end)
MonotizationService._Init()
-- Example GlobalLeaderboard init code
-- SafeInit("WinLeaderboard", function()
-- 	OrdinaryDataService.startGlobalLeaderboard("LEADERSTATS_DATA_WIN", 2, 20, Win_Global_Leaderstate, 250, 50, "Top Wins")
-- end)

-- ==========================================
-- 8. Confirming onClientEvent Loaded
-- ==========================================
GuiLoadedRemote.OnServerEvent:Connect(function(player, data)
	-- TO PREVENT REMOTE EVENT ABUSE
	if data == "CLIENTEVENTNAME_1" or data == "CLIENTEVENTNAME_2" or data == "CLIENTEVENTNAME_3" then
		player:SetAttribute(data, true)
	end
end)

-- ==========================================
-- 9. On Player Added
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	-- 10. Player init (Loading data , seting item data , assing base and leaderstate if any)
	local AttributeData =
		DataService.loadPlayerData("PlayerAttributeData", 5, true, player, DefaultData.Attributes, true)
	local ItemsData =
		DataService.loadPlayerData("PlayeritemsData", 5, true, player, { ITEM_1 = "", ITEM_2 = "" }, false)
		
	-- Placeholder for the example, assuming LeaderstatsService handles this
	-- local leaderstateData = LeaderstatsService.LoadLeaderstats(player)
	local leaderstateData = true

	if leaderstateData and AttributeData and ItemsData then
		-- SETTING ATTRIBUTE DATA THAT WE LOAD WITHOUT ATTRIBUTE SAVING
		player:SetAttribute("ITEM_1", ItemsData.ITEM_1 or "")
		player:SetAttribute("ITEM_2", ItemsData.ITEM_2 or "")

		-- Time joined setting
		player:SetAttribute("TimeJoined", DateTime.now().UnixTimestamp)

		-- 10.5 Ensuring data is loaded flag
		_G.DataLoaded[player.UserId .. "ITEMS_DATA_LOADED"] = true
		_G.DataLoaded[player.UserId .. "LEADERSTATS_LOADED"] = true

		-- 11. Initializing monetization, respawn, and other services
		MonotizationService.Init(player)

		RespawnHandler.Init(player, SpawnPart)
		RespawnHandler.SpawnPlayer(player, SpawnPart)

		-- EXAMPLE_SERVICE._init(arguments)
		-- EXAMPLE_SERVICE.DoSomeThing(arguments)

		-- 12. Character conditions
		if player.Character then
			-- Logic if character instantly loaded
		end
		player.CharacterAdded:Connect(function(character)
			-- Logic for subsequent respawns
		end)
	else
		-- Data failed to load entirely, player should probably be kicked to prevent data loss.
		player:Kick("Failed to load data. Please rejoin.")
	end
end)

-- ==========================================
-- SAVE DATA HELPER FUNCTION
-- ==========================================
-- Created a helper to prevent writing task.spawn 3 times in 3 different places
local function SaveAllPlayerData(player)
	task.spawn(function()
		pcall(function()
			AutoDataSavingService.SaveLeaderstatsData(player)
		end)
	end)
	task.spawn(function()
		pcall(function()
			AutoDataSavingService.SaveAttributesData(player)
		end)
	end)
	task.spawn(function()
		pcall(function()
			AutoDataSavingService.SaveItemsData(player)
		end)
	end)
end

-- ==========================================
-- 13. On Player Leave
-- ==========================================
Players.PlayerRemoving:Connect(function(player)
	-- Spawn a thread so one player leaving doesn't block the server
	task.spawn(function()
		SaveAllPlayerData(player)
	end)
end)

-- ==========================================
-- 14. On Game Crash / Server Shutdown
-- ==========================================
game:BindToClose(function()
	

	print("Server shutting down. Saving all player data...")
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			SaveAllPlayerData(player)
		end)
	end
	if RunService:IsStudio() then
		task.wait(2)
	else
		task.wait(30)
	end
end)

-- 15. Some other stuff

-- ==========================================
-- 16. Auto Data Saving Loop
-- ==========================================
task.spawn(function()
	while true do
		task.wait(600) -- Save every 10 minutes
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(function()
				SaveAllPlayerData(player)
				task.wait(1)
			end)
		end
	end
end)
