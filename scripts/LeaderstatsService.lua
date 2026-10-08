local LeaderstatsService = {}
local ServerScriptService = game:GetService("ServerScriptService")
local Config = game:GetService("ReplicatedStorage"):WaitForChild("Config")
local DefaultData = require(Config:WaitForChild("DefaultData"))
local OrdinaryDataService = require(ServerScriptService.Services.DataManager.OrdinaryDataService)

local DATA_TYPE_Scrap = "ABC"

LeaderstatsService.LoadLeaderstats = function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "ABC_NAME"
	money.Parent = leaderstats

	local loadedMoney = OrdinaryDataService.loadPlayerData(DATA_TYPE_Scrap, 5, true, player,DefaultData.Leaderstats.Scrap , nil)

	if loadedMoney ~= nil then
		money.Value = loadedMoney
		return true
	else
		warn("⛔ [LeaderstatsService] Failed to load data for " .. player.Name)
		return false
	end
end

return LeaderstatsService

