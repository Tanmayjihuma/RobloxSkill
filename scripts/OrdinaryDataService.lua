local OrdinaryDataService = {}
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RETRY_DELAY = 2
local usernameCache = {}

local function warnPlayer(player, err)
	warn("⛔ [GlobalDataModule] SAVE FAILED for " .. player.Name .. ": " .. tostring(err))
end

function OrdinaryDataService.loadPlayerData(DataType, attempts, kickOnFail, player, defaultValue, attributeNameToSet)
	local store = DataStoreService:GetOrderedDataStore(DataType)
	local key = "User_" .. player.UserId

	local data = nil
	local success = false
	local result = nil

	for i = 1, attempts do
		success, result = pcall(function() return store:GetAsync(key) end)
		if success then
			data = result
			break
		else
			warn("⚠️ [GlobalDataModule] Load attempt " .. i .. " failed for " .. player.Name)
			task.wait(math.clamp(RETRY_DELAY^(i-1), 1, 30))
		end
	end

	if not success then
		warn("⛔ [GlobalDataModule] CRITICAL: Failed to load data for " .. player.Name)
		if kickOnFail then player:Kick("Global Leaderboard Load Failed. Please rejoin.") end
		return nil
	end

	if data == nil then
		data = defaultValue or 0
	end
	
	if attributeNameToSet then
		player:SetAttribute(attributeNameToSet, data)
	end

	return data
end

function OrdinaryDataService.savePlayerData(DataType, attempts, kickOnFail, warnOnFail, player, intValue)
	local safeIntValue = math.floor(tonumber(intValue) or 0)

	local store = DataStoreService:GetOrderedDataStore(DataType)
	local key = "User_" .. player.UserId

	local success = false
	local err = nil

	for i = 1, attempts do
		success, err = pcall(function()
			return store:UpdateAsync(key, function(oldData)
				return safeIntValue
			end)
		end)

		if success then break end
		warn("⚠️ [GlobalDataModule] Save attempt " .. i .. " failed for " .. player.Name)
		task.wait(RETRY_DELAY)
	end

	if success then
		print("🏆 [GlobalDataModule] Global Score Saved for " .. player.Name .. " (" .. safeIntValue .. ")")
		return true
	else
		if warnOnFail then warnPlayer(player, err) end
		if kickOnFail then player:Kick("Global Save Failed. Please screenshot this and report to dev.") end
		return false
	end
end

function OrdinaryDataService.startGlobalLeaderboard(DataType, baseDelay, maxAttempts, leaderstatModel, updateTime, retryTime, titleText)
	local store = DataStoreService:GetOrderedDataStore(DataType)
	
	local leaderboardPart = leaderstatModel:WaitForChild("LeaderboardPart")
	local container = leaderboardPart:WaitForChild("SurfaceGui"):WaitForChild("ScrollingFrame"):WaitForChild("Container")
	local template = container:WaitForChild("Template")
	template.Visible = false 

	local titlePart = leaderstatModel:WaitForChild("Title")
	local titleLabel = titlePart:WaitForChild("SurfaceGui"):WaitForChild("Title")
	titleLabel.Text = titleText -- Set the custom title (e.g., "Top Wins" or "Top Streaks")

	task.spawn(function()
		while true do
			local success = false
			local pages = nil

			for attempt = 1, maxAttempts do
				success, pages = pcall(function()
					return store:GetSortedAsync(false, 50 , 1) -- false = descending order, top 50 , min is 1
				end)

				if success then
					break -- Break out of the retry loop if it worked!
				else
					warn("⚠️ Leaderboard fetch failed. Attempt " .. attempt .. " of " .. maxAttempts)
					task.wait(baseDelay * (2 ^ (attempt - 1))) 
				end
			end

			if success and pages then
				local topPlayers = pages:GetCurrentPage()

				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Frame") and child.Name ~= "Template" then
						child:Destroy()
					end
				end

				for rank, data in ipairs(topPlayers) do
					local rawKey = data.key
					local cleanUserId = tonumber(string.match(rawKey, "%d+"))
					local statValue = data.value
					local username = usernameCache[cleanUserId]

					if not username then
						local nameSuccess, nameResult = pcall(function()
							return Players:GetNameFromUserIdAsync(cleanUserId)
						end)
						if nameSuccess then
							username = nameResult
							usernameCache[cleanUserId] = username 
						else
							username = "Player_" .. tostring(cleanUserId) 
						end
					end

					local clone = template:Clone()
					clone.Name = "Rank_" .. rank
					clone.NameLabel.Text = username
					clone.NumberLabel.Text = tostring(statValue)
					clone.RankLabel.Text = "#" .. tostring(rank)
					clone.Visible = true
					clone.Parent = container
				end

				task.wait(updateTime) 
			else
				warn("⛔ Leaderboard completely failed to update. Retrying in " .. retryTime .. " seconds.")
				task.wait(retryTime) 
			end
		end
	end)
end

return OrdinaryDataService
