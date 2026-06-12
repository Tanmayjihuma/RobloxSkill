-- this is just example 

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
	if passId == PASS_IDS["DoubleCash"] then 
		player:SetAttribute("DoubleCash", true)
	elseif passId == PASS_IDS["DoubleWins"] then 
		player:SetAttribute("DoubleWins", true)
	elseif passId == PASS_IDS["DoubleStreak"] then 
		player:SetAttribute("DoubleStreak", true)
	elseif passId == PASS_IDS["10x Cash"] then 
		player:SetAttribute("10xCash", true)
	elseif passId == PASS_IDS["10x Wins"] then 
		player:SetAttribute("10xWins", true)
	elseif passId == PASS_IDS["VIP"] then
		player:SetAttribute("VIP", true)
		local owned = player:GetAttribute("OwnedChairs") 
		--print(owned)
		if not owned then return end
		
		if not string.find(owned, "VIPChair") then
			player:SetAttribute("OwnedChairs", owned .. ",VIPChair")
		end

	elseif passId == PASS_IDS["Starter_Pack"] then
		local ownedChair = player:GetAttribute("OwnedChairs")
		local ownedDeath = player:GetAttribute("OwnedDeath")
		if not ownedChair or not ownedDeath  then return end
		
		if not string.find(ownedChair, "CrystalChair") then
			player:SetAttribute("OwnedChairs", ownedChair .. ",CrystalChair")
		end
		
		if not string.find(ownedDeath, "Freeze") then
			player:SetAttribute("OwnedDeath", ownedDeath .. ",Freeze")
		end
		if not player:GetAttribute("GetStarterCash") then
			player:SetAttribute("GetStarterCash", true)
			StateService.UpdateCash(player, 500, false, false)
			StateService.UpdateWins(player, 5, false, false)

		end
	elseif passId == PASS_IDS["Void Chair"] then
		local owned = player:GetAttribute("OwnedChairs")
		if not owned then return end
		if not string.find(owned, "VoidChair") then
			player:SetAttribute("OwnedChairs", owned.. ",VoidChair")
		end

	elseif passId == PASS_IDS["Void Death"] then
		local owned = player:GetAttribute("OwnedDeath")
		if not owned then return end
		if not string.find(owned, "VoidEffect") then
			player:SetAttribute("OwnedDeath", owned.. ",VoidEffect")
		end
	end
	
end

-- ==========================================
-- DEVELOPER PRODUCT LOGIC (Consumables)
-- ==========================================
local productHandlers = {
	-- this part is just for understanding cuz diffrent game need different types of data
	[PROD_IDS["300Cash"]]  = function(p) StateService.UpdateCash(p, 300, false, true) return true end,
	[PROD_IDS["1000Cash"]] = function(p) StateService.UpdateCash(p, 1000, false, true) return true end,
	[PROD_IDS["2500Cash"]] = function(p) StateService.UpdateCash(p, 2500, false, true) return true end,
	[PROD_IDS["5000Cash"]] = function(p) StateService.UpdateCash(p, 5000, false, true) return true end,

	[PROD_IDS["10Wins"]]  = function(p) StateService.UpdateWin(p, 10, false, true) return true end,
	[PROD_IDS["25Wins"]]  = function(p) StateService.UpdateWin(p, 25, false, true) return true end,
	[PROD_IDS["50Wins"]]  = function(p) StateService.UpdateWin(p, 50, false, true) return true end,
	[PROD_IDS["100Wins"]] = function(p) StateService.UpdateWin(p, 100, false, true) return true end,

	[PROD_IDS["ReviveStreak"]] = function(p)
		local lastStreak = p:GetAttribute("SavedLostStreak") or 0
		if lastStreak > 0 then
			local leaderstats = p:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Streak") then
				local currentValue = leaderstats.Streak.Value
				if currentValue  then
					if currentValue < lastStreak then
						leaderstats.Streak.Value = lastStreak 
					end
				else
					leaderstats.Streak.Value = lastStreak -- Restores the streak!
				end
			end
			p:SetAttribute("SavedLostStreak", 0) -- Clear it out so they can't exploit it
		end
		return true
	end,
}

-- ==========================================
-- CORE MONETIZATION LOGIC
-- ==========================================
local function tryUserOwnsGamePassAsync(retry, player)
	for _, passId in pairs(PASS_IDS) do
		task.spawn(function()
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
		end)
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
	tryUserOwnsGamePassAsync(5, player) 

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, success)
		if success then grantPassReward(player, id) end
	end)
	
end
return MonotizationService
