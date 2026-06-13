local MonotizationService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local purchaseHistory = DataStoreService:GetDataStore("PurchaseHistory")

local Config = require(game.ReplicatedStorage.Config)
local StatesService = require(game.ServerScriptService.Services.StatesService)

local PASS_IDS = Config.Gamepasses
local PROD_IDS = Config.DeveloperProducts

-- ==========================================
-- GAMEPASS LOGIC (Permanent Unlocks)
-- ==========================================
local function grantPassReward(player, passId)
	-- this part is just for understanding cuz different games need different types of data
	-- THIS IS EXAMPLE PART
	if passId == PASS_IDS["EXAMPLE_DoubleMoney"] then 
		player:SetAttribute("DoubleMoney", true) -- so we can use in StatesService
	elseif passId == PASS_IDS["EXAMPLE_VIP_ITEM"] then
		-- use player stats service to update the items string list
	end
end

-- ==========================================
-- DEVELOPER PRODUCT LOGIC (Consumables)
-- ==========================================
local productHandlers = {
	-- this part is just for understanding cuz different game need different types of data
	[PROD_IDS["EXAMPLE_MONEY_AMOUNT"]]  = function(p) StatesService.UpdateStatsFromAttribute(p, 100, false, true , 1 , "EXAMPLE_MONEY") return true end,

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
					break
				else
					warn("Gamepass check failed: " .. tostring(owns)) -- 'owns' holds the error message here
					task.wait(1)
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



--serverinit
MonotizationService._Init = function()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, success)
		if success then grantPassReward(player, id) end
	end)
end
-- player added init
MonotizationService.Init = function(player) 
	task.spawn(function() 
		tryUserOwnsGamePassAsync(5, player) 
	end)
end




return MonotizationService
