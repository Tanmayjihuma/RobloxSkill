-- Help load player data and save player data safily (only for tables for now)

-- yieling functions 
local DataService = {}
local DataStoreService = game:GetService("DataStoreService")
local RETRY_DELAY = 2

local function warnPlayer(player, err)
	warn("⛔ [DataModule] SAVE FAILED for " .. player.Name .. ": " .. tostring(err))
end

function DataService.reconcileData(currentData, defaultData)
	local newData = currentData or {}
	for key, value in pairs(defaultData) do
		if newData[key] == nil then
			newData[key] = value
		end
	end
	return newData
end

function DataService.loadPlayerData(DataType, attempts, kickOnFail, player, defaultData, setAttributes)
	local store = DataStoreService:GetDataStore(DataType)
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
			warn("⚠️ [DataModule] Load attempt " .. i .. " failed for " .. player.Name)
			task.wait(math.clamp(RETRY_DELAY^(i-1), 1, 30))
		end
	end

	if not success then
		warn("⛔ [DataModule] CRITICAL: Failed to load data for " .. player.Name)
		if kickOnFail then player:Kick("Data Load Failed. Please rejoin.") end
		return nil
	end

	data = DataService.reconcileData(data, defaultData)

	if setAttributes then
		for statName, statValue in pairs(data) do
			player:SetAttribute(statName, statValue)
		end
	end

	return data
end

function DataService.savePlayerData(DataType, attempts, kickOnFail, warnOnFail, player, dataToSave)
	local store = DataStoreService:GetDataStore(DataType)
	local key = "User_" .. player.UserId

	local success = false
	local err = nil

	for i = 1, attempts do
		success, err = pcall(function()
			return store:UpdateAsync(key, function(oldData)
				local finalData = oldData or {}
				for k, v in pairs(dataToSave) do
					finalData[k] = v
				end
				return finalData
			end)
		end)

		if success then break end
		warn("⚠️ [DataModule] Save attempt " .. i .. " failed for " .. player.Name)
		task.wait(RETRY_DELAY)
	end

	if success then
		print("💾 [DataModule] Partial Save Success for " .. player.UserId)
		return true
	else
		if warnOnFail then warnPlayer(player, err) end
		if kickOnFail then player:Kick("Data Save Failed. Please screenshot this and report to dev.") end
		return false
	end
end

return DataService
