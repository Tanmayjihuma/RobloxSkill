--- this is just an example generally we save player data in 3 things first is attributes , second is from leaderstate and third is table or global table 
--- and sometime we need to calculate multiplayer by vip and other gamepassed so its depends 
local StatesService = {}

StatesService.UpdateCash = function(player, amount , reset ,isRbxReward)
	if not player or not amount or not player.Parent then return end
	local Cash = player:GetAttribute("Cash")
	if Cash then
		if amount > 0 and not isRbxReward then
			local multiplier = 0
			if player:GetAttribute("DoubleCash") then multiplier += 2 end
			if player:GetAttribute("10xCash") then multiplier += 10 end
			if player:GetAttribute("VIP") then multiplier += 2 end

			if multiplier == 0 then multiplier = 1 end

			amount *= multiplier
		end

		if reset then
			player:SetAttribute("Cash", 0)
		else
			player:SetAttribute("Cash", math.max(0, Cash + amount))
		end
	end

end

StatesService.UpdateSteak = function(player, amount, reset , isRbxReward)
	if not player or not amount or not player.Parent then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local streak = leaderstats:FindFirstChild("Streak")
		if amount > 0 and not isRbxReward then
			local multiplier = 0
			if player:GetAttribute("DoubleStreak") then multiplier += 2 end
			if multiplier == 0 then multiplier = 1 end
			amount *= multiplier
		end
		if reset then
			streak.Value = 0
		else
			streak.Value = math.max(0, streak.Value + amount)
		end
	end
end

StatesService.UpdateWin = function(player, amount, reset , isRbxReward)
	if not player or not amount or not player.Parent then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local win = leaderstats:FindFirstChild("Wins")
		if not win then return end
		if amount > 0 and not isRbxReward then
			local multiplier = 0
			if player:GetAttribute("DoubleWins") then multiplier += 2 end
			if player:GetAttribute("10xWins") then multiplier += 10 end

			if multiplier == 0 then multiplier = 1 end

			amount *= multiplier
		end

		if reset then
			win.Value = 0
		else
			win.Value = math.max(0, win.Value + amount)
		end
	end
end

-- or add a function to update the table 


return StatesService


