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
local SessionLockService = require(Services:WaitForChild("DataManager"):WaitForChild("SessionLockService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))
local DataService = require(Services:WaitForChild("DataManager"):WaitForChild("DataService"))
local LeaderstatsService = require(Services:WaitForChild("LeaderstatsService"))
local OrdinaryDataService = require(Services:WaitForChild("DataManager"):WaitForChild("OrdinaryDataService"))
local MusicService = require(Services:WaitForChild("MusicService"))

-- 2. (IMP) Remote that confirms race condition onClientEvent or important script stuff loaded race condtion fixes
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
local InitedPlayer={}
-- Example Global Leaderboards
-- local Win_Global_Leaderstate = workspace:WaitForChild("OtherStuff"):WaitForChild("Win_Leaderboard")
-- local Streak_Global_Leaderstate = workspace:WaitForChild("OtherStuff"):WaitForChild("Streak_Leaderboard")

-- 6. Disabling some features (Data must load before spawn)
Players.CharacterAutoLoads = false

-- ==========================================
-- 7. Server _Init (Initializing main functions)
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

local function SafeInitWithYeilding(moduleName, initFunction)
		local success, err = pcall(initFunction)
		if not success then
			warn("CRITICAL ERROR: Failed to initialize " .. moduleName .. " | Error: " .. tostring(err))
		end
end

-- the core gameplay function not need safeInit or task.spawn
-- GameSystem1._Init()
-- SafeInit("GameSystem2", function() GameSystem2._Init() end)
--SafeInit("MusicService", function()
	--MusicService._Init()
--end)
MonetizationService._Init()
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

local onPlayerAdded = function(player){
	if  InitedPlayer{player} then return end
	InitedPlayer{player}  = true

	local lockAcquired = SessionLockService.AcquireLock(player)
	if not lockAcquired then return end

	if not player or not player.Parent then
		SessionLockService.ReleaseLock(player)
		return
	end
	
		-- 10. Player init (Loading data , setting item data , assigning base and leaderstate if any)
	local AttributeData =
		DataService.loadPlayerData("PlayerAttributeData", 5, true, player, DefaultData.Attributes, true)
	local ItemsData =
		DataService.loadPlayerData("PlayeritemsData", 5, true, player, { ITEM_1 = "", ITEM_2 = "" }, false)
		
	 local leaderstateData = LeaderstatsService.LoadLeaderstats(player)

	if leaderstateData and AttributeData and ItemsData then
		-- SETTING ATTRIBUTE DATA THAT WE LOAD WITHOUT ATTRIBUTE SAVING
		if not player or not player.Parent then
			SessionLockService.ReleaseLock(player)
			return
		end
			
		player:SetAttribute("ITEM_1", ItemsData.ITEM_1 or "")
		player:SetAttribute("ITEM_2", ItemsData.ITEM_2 or "")

		-- Time joined setting
		player:SetAttribute("TimeJoined", os.time())

		-- 10.5 Ensuring data is loaded flag
		Player:SetAttribute("ALLDATALOADED" , true)

		-- 11. Initializing monetization, respawn, and other services
		MonetizationService.Init(player)

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
		SessionLockService.ReleaseLock(player)
		player:Kick("Failed to load data. Please rejoin.")
	end	
}

-- sometimes played joined before player joined the game
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

-- ==========================================
-- SAVE DATA HELPER FUNCTION
-- ==========================================
-- Created a helper to prevent writing task.spawn 3 times in 3 different places
local function SaveAllPlayerData(player , isLeaving)
	if not player:GetAttribute("AllDataLoaded") then return end

	player:SetAttribute("LastLeaveTime", os.time())
	local completedSaves = 0
	local totalSaves = 4
	local results = {s1 = false, s2 = false, s3 = false, s4 = false }

	local timeout = 21
	local elapsed = 0


	task.spawn(function()
		local noCrash, didSave = pcall(function() return AutoDataSavingService.SaveLeaderstatsData(player) end)
		results.s1 = noCrash and didSave
		completedSaves += 1
	end)

	task.spawn(function()
		local noCrash, didSave = pcall(function() return AutoDataSavingService.SaveAttributesData(player) end)
		results.s2 = noCrash and didSave
		completedSaves += 1
	end)

	task.spawn(function()
		local noCrash, didSave = pcall(function() return AutoDataSavingService.SaveItemsData(player) end)
		results.s3 = noCrash and didSave
		completedSaves += 1
	end)

	task.spawn(function()
		local noCrash, didSave = pcall(function() return AutoDataSavingService.SaveOrdinaryDatas(player) end)
		results.s4 = noCrash and didSave
		completedSaves += 1
	end)


	while completedSaves < totalSaves and elapsed < timeout do
		task.wait(0.1)
		elapsed += 0.1
	end

	local timedOut = (elapsed >= timeout)
	if timedOut then
		warn("CRITICAL: DataStores timed out after 20 seconds for " .. player.Name)
	end

	if isLeaving then
		-- Only release if all saves succeeded AND it did not time out
		if results.s1 and results.s2 and results.s3 and results.s4 and not timedOut then 
			SessionLockService.ReleaseLock(player)
		else
			warn("CRITICAL: Data failed to save for " .. player.Name .. ". Lock will naturally expire in 45s.")
		end
	end
end

-- ==========================================
-- 13. On Player Leave
-- ==========================================
Players.PlayerRemoving:Connect(function(player)
	-- Spawn a thread so one player leaving doesn't block the server
	InitedPlayer[player] = nil
	task.spawn(function()
		SaveAllPlayerData(player , true)
	end)
	if invCooldowns[player] then
		invCooldowns[player] = nil
	end
end)

-- ==========================================
-- 14. On Game Crash / Server Shutdown
-- ==========================================
game:BindToClose(function()
	print("Server shutting down. Saving all player data...")
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			SaveAllPlayerData(player , true)
		end)
	end
	if RunService:IsStudio() then
		task.wait(2)
	else
		task.wait(25) -- maybe add proper check per player if needed
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
				SaveAllPlayerData(player , false) -- sending TimeSave true so it do not get global Data Value to nil
				task.wait(1)
			end)
		end
	end
end)

