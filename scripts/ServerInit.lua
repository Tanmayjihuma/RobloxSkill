-- this contains good example of server init 
-- follow this structure 

-- 1  defining Basic Services
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Services = ServerScriptService:WaitForChild("Services")
local Systems = ServerScriptService:WaitForChild("Systems")
local AutoDataSavingService = require(Services.DataService.AutoDataSavingService)
local MonotizationService = require(Services.MonotizationService)
local DataService = require(Services.DataService)
local LeaderstatsService = require(Services.LeaderstatsService)
local OrdinaryDataService = require(Services.DataService.OrdinaryDataService)
local MusicService = require(Services.MusicService)

-- 2 (IMP) Remote that conform race condition onClientEvent or maybe somemore important script stuff Loaded or not 
local GuiLoadedRemote = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("OnClientEventLoaded")

-- 3 defining required Modules 
local Config = ReplicatedStorage:WaitForChild("Config")
local DefaultData = require(Config:WaitForChild("DefaultData"))
local RespawnHandler = require(Systems.RespawnHandler)
-- for example
local GameSystem1 = require(Systems:WaitForChild("gamesystem1")
local GameSystem2 = require(Systems:WaitForChild("gamesystem2")
local GameSystem3 = require(Systems:WaitForChild("gamesystem3")
  
-- 4 defining variables from workspace (example)
local SpawnPart = workspace:WaitForChild("SpawnPart")
local Win_Global_Leaderstate = workspace:WaitForChild("OtherStuff"):WaitForChild("Win_Leaderboard")
local Streak_Global_Leaderstate = workspace:WaitForChild("OtherStuff"):WaitForChild("Streak_Leaderboard")

-- 5 loaded data checker 
_G.DataLoaded={}

-- 6 disabling/enableing  some featurese
Players.CharacterAutoLoads = false

-- 7 Server _Init ( initing main functions ) 

-- its depends u want put it in pcall or task.spawn or not 
local s1 , r1 = pcall(function() GameSystem1._Init() end) 
task.spawn(function() local s1 , r1 = pcall(function() GameSystem2._Init() end) if not s1 then warn("Error in ServerScript s1-->" .. r1) end end)
task.spawn(function() local s1 , r1 = pcall(function() GameSystem3._Init() end) if not s1 then warn("Error in ServerScript s1-->" .. r1) end end)
task.spawn(function() local s1 , r1 = pcall(function() MusicService._Init() end) if not s1 then warn("Error in ServerScript s1-->" .. r1) end end)
-- GlobalLeaderboard init code
task.spawn(function() local s1 , r1 = pcall(function() OrdinaryDataService.startGlobalLeaderboard("LEADERSTATS_DATA_WIN" , 2 , 20 , Win_Global_Leaderstate , 250 , 50 , "Top Wins") end) 
	if not s1 then warn("Error in ServerScript s1-->" .. r1) end end)
task.spawn(function() local s1 , r1 = pcall(function() OrdinaryDataService.startGlobalLeaderboard("LEADERSTATS_DATA_STREAK" , 2 , 20 , Streak_Global_Leaderstate , 250 , 50 , "Top Streaks") end) 
	if not s1 then warn("Error in ServerScript s1-->" .. r1) end end)

-- 8 confarming onClientEvent Loaded or not
GuiLoadedRemote.OnServerEvent:Connect(function(player, data)
	if data == "5X5" or data == "6X6" or data  == "GuiOpened"then
		player:SetAttribute(data, true)
	end
end)

-- 9 On Player added
Players.PlayerAdded:Connect(function(player)
	-- 10 player init (loading player data and assigning him leaderboard , base if needed etc )  (for example )
  
	local AttributeData = DataService.loadPlayerData("PlayerAttributeData", 5, true, player, DefaultData.Attributes, true)
	local ItemsData = DataService.loadPlayerData("PlayeritemsData", 5, true, player, {
		Chair = "", 
		Death = "", 
		EquippedChair = "BasicChair", 
		EquippedDeath = "BasicDeath"
	}, false)
	
	-- 10.5 seting player data 
	if leaderstateData and AttributeData and ItemsData then
		
		--player:SetAttribute("QuestLastReset" , 20000)
		player:SetAttribute("OwnedChairs", ItemsData.Chair or "")
		player:SetAttribute("OwnedDeath", ItemsData.Death or "")
		
		player:SetAttribute("EquippedChair", ItemsData.EquippedChair or "BasicChair")
		player:SetAttribute("EquippedDeath", ItemsData.EquippedDeath or "BasicDeath")
		
		local s , r = pcall(function() 
			if player:GetAttribute("EquippedChair") == "" then
				player:SetAttribute("EquippedChair" , "BasicChair")
			elseif player:GetAttribute("EquippedDeath") == ""  then
				player:SetAttribute("EquippedDeath" , "BasicDeath")
			end
		end)

    -- 10.9 assigning time join attribute it needed (like in time reward etc ), making player true for data loaded  
		player:SetAttribute("TimeJoined", DateTime.now().UnixTimestamp)
		_G.DataLoaded[player.UserId.."ITEMS_DATA_LOADED"] = true

    --11 initalizing monatization services , respawn service and other service 
		MonotizationService._Init(player)
            
		RespawnHandler.SpawnPlayer(player , SpawnPart)
    --(for example ) 
		local QuestService = require(Services.QuestService)
		QuestService.CheckDailyReset(player)
		QuestService.AddProgress(player, "Login", 1)
		
		RespawnHandler.Init(player , SpawnPart)
    -- 12 condition of chatacter when character added  if needed
    -- make sure if anything can call only one time on player Character then add variable to block it using in character added or something 
		if player.Character then
    end
    player.CharacterAdded:Connect(function(character)
    end)
            
	end
end)

-- 13 On player leave
Players.PlayerRemoving:Connect(function(player)
	task.spawn(function() AutoDataSavingService.SaveLeaderstatsData(player) end)
	task.spawn(function() AutoDataSavingService.SaveAttributesData(player) end)	
	task.spawn(function() AutoDataSavingService.SaveItemsData(player) end)
end)

-- 14 on game crash
game:BindToClose(function()
	for _ , player in pairs(game.Players:GetPlayers()) do
		task.spawn(function() AutoDataSavingService.SaveLeaderstatsData(player) end)
		task.spawn(function() AutoDataSavingService.SaveAttributesData(player) end)	
		task.spawn(function() AutoDataSavingService.SaveItemsData(player) end)
	end
	task.wait(20) 
end)

-- 15 some other stuff
-- (for example )
task.spawn(function()
	local QuestService = require(Services.QuestService)
	while true do
		task.wait(60)
		for _, player in pairs(game.Players:GetPlayers()) do
			local currentMins = player:GetAttribute("DailyPlaytimeMinutes") or 0
			player:SetAttribute("DailyPlaytimeMinutes", currentMins + 1)
			QuestService.AddProgress(player, "PlayTime", 1)
		end
	end
end)

-- 16 auto data saving 
while true  do
	task.wait(600)
	for _ , player in pairs(game.Players:GetPlayers()) do
		task.spawn(function() AutoDataSavingService.SaveLeaderstatsData(player) end)
		task.spawn(function() AutoDataSavingService.SaveAttributesData(player) end)	
		task.spawn(function() AutoDataSavingService.SaveItemsData(player) end)
	end
end
