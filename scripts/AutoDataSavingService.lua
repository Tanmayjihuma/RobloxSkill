-- this is just an example how AutoDataSavingService works variable names can be different 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(game.ReplicatedStorage.Services.DataService)
local OrdinaryDataService = require(game.ReplicatedStorage.Services.DataService.OrdinaryDataService)
local Config = ReplicatedStorage:WaitForChild("Config")
local DefaultData = require(Config:WaitForChild("DefaultData"))
local AutoDataSavingService = {}
local DATA_TYPE_WIN = "LEADERSTATS_DATA_WIN"
local DATA_TYPE_STREAK = "LEADERSTATS_DATA_STREAK"

AutoDataSavingService.SaveLeaderstatsData = function(player)
	
	if _G.DataLoaded[player.UserId.."LEADERSTATS_DATA_LOADED"] then
		local Wins = player.leaderstats.Wins.Value
		local Streak = player.leaderstats.Streak.Value
		OrdinaryDataService.savePlayerData(DATA_TYPE_WIN , 6, false , true , player , Wins)
		OrdinaryDataService.savePlayerData(DATA_TYPE_STREAK , 6, false , true , player , Streak)
		_G.DataLoaded[player.UserId.."LEADERSTATS_DATA_LOADED"] = nil
	end
end 

AutoDataSavingService.SaveAttributesData= function(player)
	local dataToSave = {}
	for attributeName, _ in pairs(DefaultData.Attributes) do
		local currentValue = player:GetAttribute(attributeName)
		-- this is to prevent data loss in attributes when player join and leaver before its data is loaded
		if currentValue ~= nil then
			dataToSave[attributeName] = currentValue
		end
	end

	DataService.savePlayerData("PlayerAttributeData", 4, false, true, player, dataToSave)
end

AutoDataSavingService.SaveItemsData = function(player)
	if _G.DataLoaded[player.UserId.."ITEMS_DATA_LOADED"] then
		local dataToSave = {
			Chair = player:GetAttribute("OwnedChairs") ,
			Death = player:GetAttribute("OwnedDeath") ,
			EquippedChair = player:GetAttribute("EquippedChair"),
			EquippedDeath = player:GetAttribute("EquippedDeath") 
		}

		DataService.savePlayerData("PlayeritemsData", 5, false, true, player, dataToSave)
	end
end

return AutoDataSavingService







