-- this is just an example how AutoDataSavingService works variable names can be different 
-- also we store data in 2 format after loading , attributes and this system here is allready perfect
-- second is leaderboard this is also kinda perfect


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(game.ReplicatedStorage.Services.DataService)
local OrdinaryDataService = require(game.ReplicatedStorage.Services.DataService.OrdinaryDataService)
local Config = ReplicatedStorage:WaitForChild("Config")
local DefaultData = require(Config:WaitForChild("DefaultData"))
local AutoDataSavingService = {}
local DATA_TYPE_EXAMPLE_ATTRIBUTE = "ATTRIBUTE_EXAMPLE"
-- we need different for leaderstate cuz we use ordianrary data store service that stores numbers not values 
local DATA_TYPE_EXAMPLE_LEADERSTATE_1= "LEADERSTATS_EXAMPLE_1"
local DATA_TYPE_EXAMPLE_LEADERSTATE_2 = "LEADERSTATS_EXAMPLE_2"

AutoDataSavingService.SaveLeaderstatsData = function(player)
	
	if _G.DataLoaded[player.UserId.."LEADERSTATS_DATA_LOADED"] then
		local EXAMPLE_DATA_1 = player.leaderstats.EXAMPLE_DATA_1.Value
		local EXAMPLE_DATA_2 = player.leaderstats.EXAMPLE_DATA_2.Value
		OrdinaryDataService.savePlayerData(DATA_TYPE_EXAMPLE_LEADERSTATE_1 , 6, false , true , player , EXAMPLE_DATA_1)
		OrdinaryDataService.savePlayerData(DATA_TYPE_EXAMPLE_LEADERSTATE_2 , 6, false , true , player , EXAMPLE_DATA_2)
		
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

	DataService.savePlayerData(DATA_TYPE_EXAMPLE_ATTRIBUTE, 4, false, true, player, dataToSave)
end

-- FOR ITEMS OR OTHER DATA (WHEN DATA CONTAINS TABLE)
AutoDataSavingService.SaveItemsData = function(player)
	if _G.DataLoaded[player.UserId.."ITEMS_DATA_LOADED"] then
		local dataToSave = {
			Chair = player:GetAttribute("EXAMPLE_ITEMS") ,
			Death = player:GetAttribute("EXAMPLE_EFFECTS") ,
		}
		DataService.savePlayerData("PlayeritemsData", 5, false, true, player, dataToSave)
	end
end

return AutoDataSavingService







