local MonotizationService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local purchaseHistory = DataStoreService:GetDataStore("PurchaseHistory")

local Config = require(game.ReplicatedStorage.Config.IDs)
local StateService = require(game.ReplicatedStorage.Services.PlayerStatesService)

local PASS_IDS = Config.Gamepasses
local PROD_IDS = Config.DeveloperProducts

-- ==========================================
-- GAMEPASS LOGIC (Permanent Unlocks)
-- ==========================================
local function grantPassReward(player, passId)
	-- this part is just for understandins cuz different games need different types of data
	-- THIS IS EXAMPLE PART
	if passId == PASS_IDS["EXAMPLE_DoubleMoney"] then 
		player:SetAttribute("DoubleMoney", true) -- so we can use in playerStatsService
	elseif passId == PASS_IDS["EXAMPLE_VIP_ITEM"] then
		player:SetAttribute("VIP_ITEM", true) -- SO WE CAN USE IN OTHER SCRIPT 
		local owned = player:GetAttribute("EXAMPLE_Owned_ITEMS") 
		if not owned then return end -- Always return when data not found to prevent data loss
		--FOR EXAMPLE 
		if not string.find(owned, "EXAMPLE_Owned_ITEMS") then
			player:SetAttribute("EXAMPLE_Owned_ITEMS", owned .. ",VIP_ITEMS")
		end
	end
end

-- ==========================================
-- DEVELOPER PRODUCT LOGIC (Consumables)
-- ==========================================
local productHandlers = {
	-- this part is just for understanding cuz diffrent game need different types of data
	[PROD_IDS["EXAMPLE_MONEY_AMOUNT"]]  = function(p) StateService.UpdateCash(p, AMOUNT, false, true) return true end,

	[PROD_IDS["EXAMPLE_OTHERSTUFF"]] = function(p)
		--OTHER STUFF CODE
		return true
	end,
}

-- ==========================================
-- CORE MONETIZATION LOGIC
-- ==========================================
local function tryUserOwnsGamePassAsync(retry, player)
	for _, passId in pairs(PASS_IDS) do
			for attempt = 1, retry do
				if not player or not player.Parent then return end
				local success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
				if success then
					if owns then grantPassReward(player, passId) end
					return
				else
					warn("Error checking Pass " .. passId .. ": " .. tostring(owns))
					task.wait(2)
				end
			end
	end
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player or not player.Parent then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId

	local success, alreadyPurchased = pcall(function()
		return purchaseHistory:GetAsync(purchaseKey)
	end)

	if not success then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if alreadyPurchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if not player or not player.Parent then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = productHandlers[receiptInfo.ProductId]
	if handler then
		local handlerSuccess, granted = pcall(function()
			return handler(player)
		end)
		if not handlerSuccess or not granted then
			if not handlerSuccess then
				warn("CRITICAL: Error in Product Handler for ID " .. receiptInfo.ProductId .. ": " .. tostring(granted))
			end
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local saved, err = pcall(function()
		purchaseHistory:SetAsync(purchaseKey, true)
	end)

	if not saved then
		warn("player got item but problem in saving purchase history"..tostring(err)..tostring(player.UserId))
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt




MonotizationService._Init = function(player)
	task.spawn(function() 
		tryUserOwnsGamePassAsync(5, player) 
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, success)
		if success then grantPassReward(player, id) end
	end)
end
return MonotizationService
