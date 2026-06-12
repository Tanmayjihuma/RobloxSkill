--- This service provides generic functions to update player data,
--- dynamically applying multipliers based on attributes.

local StatesService = {}

StatesService.Update_Stats_FROM_ATTRUBUTE = function(player, amount, reset, isRbxReward, initMultiplayer, statName)
	if not player or not amount or not player.Parent then return end
	
	-- We rename the parameter to `statName` to avoid confusing it with the actual numerical value.
	local currentStatValue = player:GetAttribute(statName)
	
	if currentStatValue ~= nil then
		amount *= (initMultiplayer or 1) -- Safeguard in case initMultiplayer is nil
		
		if amount > 0 and not isRbxReward then
			-- Correct Multiplier Logic: Initialize to 1 FIRST.
			local multiplier = 1
			
			-- Dynamically check for a "Double" attribute.
			-- E.g., if statName is "Cash", it looks for attribute "DoubleCash"
			if player:GetAttribute("Double" .. statName) then 
				multiplier *= 2 
			end
			
			amount *= multiplier
		end

		if reset then
			player:SetAttribute(statName, 0)
		else
			player:SetAttribute(statName, math.max(0, currentStatValue + amount))
		end
	end
end

StatesService.Update_Stats_FROM_LeaderStats = function(player, amount, reset, isRbxReward, initMultiplayer, statName)
	if not player or not amount or not player.Parent then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		-- Find the IntValue/NumberValue object inside leaderstats
		local statObject = leaderstats:FindFirstChild(statName)
		
		if statObject then
			amount *= (initMultiplayer or 1)
			
			if amount > 0 and not isRbxReward then
				local multiplier = 1
				
				if player:GetAttribute("Double" .. statName) then 
					multiplier *= 2 
				end
				
				amount *= multiplier
			end
			
			if reset then
				statObject.Value = 0
			else
				-- Fixed the 'streak.Value' typo here
				statObject.Value = math.max(0, statObject.Value + amount)
			end
		end
	end
end

return StatesService
