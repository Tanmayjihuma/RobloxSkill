local SessionLockService = {}
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")

local SessionMap = MemoryStoreService:GetSortedMap("ActivePlayerSessions")
local SESSION_TTL = 45

SessionLockService.AcquireLock = function(player)
	local userIdStr = tostring(player.UserId)
	local attempts = 0
	local maxAttempts = 8
	local apiFailed = false 

	while attempts < maxAttempts do
		if not player or not player.Parent then return false end

		local lockedByUs = false
		local success, err = pcall(function()
			SessionMap:UpdateAsync(userIdStr, function(currentJobId)
				if currentJobId == nil or currentJobId == game.JobId then
					lockedByUs = true
					return game.JobId 
				end

				lockedByUs = false
				return nil 
			end, SESSION_TTL)
		end)

		if success then
			if lockedByUs then
				player:SetAttribute("SessionLocked", true)
				return true
			end
			apiFailed = false 
		else
			apiFailed = true 
			warn("MemoryStore error while locking " .. player.Name .. ": " .. tostring(err))
		end

		attempts += 1
		task.wait(2)
	end

	if apiFailed then
		player:Kick("Roblox Data Services are experiencing issues. Please try again.")
	else
		player:Kick("Your data is still saving in another server. Please rejoin.")
	end

	return false
end

SessionLockService.ReleaseLock = function(player)
	if not player:GetAttribute("SessionLocked") then return end
	local userIdStr = tostring(player.UserId)

	local releaseAttempts = 0
	while releaseAttempts < 3 do
		local success, err = pcall(function()
			local currentJobId = SessionMap:GetAsync(userIdStr)
			if currentJobId == game.JobId then
				SessionMap:RemoveAsync(userIdStr)
			end
		end)

		if success then
			break -- Successfully released, exit the loop
		end

		releaseAttempts += 1
		warn("Failed to release lock for " .. player.Name .. ", retrying... " .. tostring(err))
		task.wait(1)
	end

	player:SetAttribute("SessionLocked", false)
end

-- Heartbeat Loop
task.spawn(function()
	while true do
		task.wait(15)
		for _, player in pairs(Players:GetPlayers()) do
			if player:GetAttribute("SessionLocked") then

				local lockLost = false

				local success = pcall(function()
					SessionMap:UpdateAsync(tostring(player.UserId), function(currentJobId)
						if currentJobId == nil or currentJobId == game.JobId then
							return game.JobId
						end

						-- Another server stole it? Abort update and flag it!
						lockLost = true
						return nil 
					end, SESSION_TTL)
				end)

				if success and lockLost then
					player:Kick("Session compromised. Please rejoin.")
				end

				task.wait(0.1) 
			end
		end
	end
end)

return SessionLockService

