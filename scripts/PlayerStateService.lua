--- This service provides generic functions to update player data,
--- dynamically applying multipliers based on attributes.

local StatesService = {}

StatesService.UpdateStatsFromAttribute = function(player, amount, reset, isRbxReward, initMultiplayer, statName)
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

StatesService.UpdateStatsFromLeaderStats = function(player, amount, reset, isRbxReward, initMultiplayer, statName)
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

-- item data logics 

local function parseEntry(entry)
	local name, count = string.match(entry, "^(.+)%((%d+)%)$")
	if name and count then
		return name, tonumber(count)
	else
		return entry, 1
	end
end

local function rebuildString(items)
	local final = {}
	for _, v in ipairs(items) do
		if v ~= "" and v ~= nil then
			table.insert(final, v)
		end
	end
	return table.concat(final, ",")
end

StatesService.HasItem = function(player: Player, attributeName: string, itemName: string): boolean
	local str = player:GetAttribute(attributeName)
	if not str or typeof(str) ~= "string" or str == "" then return false end
	
	local items = string.split(str, ",")
	for _, entry in ipairs(items) do
		local name, _ = parseEntry(entry)
		if name == itemName then return true end
	end
	return false
end

--- Returns the current stack amount of a specific item.
StatesService.GetStackAmount = function(player: Player, attributeName: string, itemName: string): number
	local str = player:GetAttribute(attributeName)
	if not str or typeof(str) ~= "string" or str == "" then return 0 end
	
	local items = string.split(str, ",")
	for _, entry in ipairs(items) do
		local name, count = parseEntry(entry)
		if name == itemName then return count end
	end
	return 0
end

--- Adds an item. If isStackable is true, it increments the (n) value.
StatesService.AddItem = function(player: Player, attributeName: string, itemName: string, isStackable: boolean)
	local str = player:GetAttribute(attributeName)
	if not str then return end
	
	local items = string.split(str, ",")
	local foundIndex = nil
	
	-- Look for existing item
	for i, entry in ipairs(items) do
		local name, count = parseEntry(entry)
		if name == itemName then
			if not isStackable then return end -- Already has it, not stackable, so abort
			foundIndex = i
			break
		end
	end
	
	if foundIndex then
		local name, count = parseEntry(items[foundIndex])
		items[foundIndex] = name .. "(" .. (count + 1) .. ")"
	else
		-- Add New
		local entry = isStackable and (itemName .. "(1)") or itemName
		if str == "" then
			table.insert(items, entry)
		else
			table.insert(items, entry)
		end
	end
	
	player:SetAttribute(attributeName, rebuildString(items))
end

--- Removes an item. If isStackable is true, it decrements the count.
--- Set removeAll to true to delete the whole stack regardless of count.
StatesService.RemoveItem = function(player: Player, attributeName: string, itemName: string, isStackable: boolean, removeAll: boolean)
	local str = player:GetAttribute(attributeName)
	if not str or str == "" then return end
	
	local items = string.split(str, ",")
	local foundIndex = nil
	
	for i, entry in ipairs(items) do
		local name, _ = parseEntry(entry)
		if name == itemName then
			foundIndex = i
			break
		end
	end
	
	if not foundIndex then return end
	
	if isStackable and not removeAll then
		local name, count = parseEntry(items[foundIndex])
		if count > 1 then
			items[foundIndex] = name .. "(" .. (count - 1) .. ")"
		else
			table.remove(items, foundIndex)
		end
	else
		table.remove(items, foundIndex)
	end
	
	player:SetAttribute(attributeName, rebuildString(items))
end

--- Returns total count of unique entries.
StatesService.CountUniqueItems = function(player: Player, attributeName: string): number
	local str = player:GetAttribute(attributeName)
	if not str or str == "" then return 0 end
	local items = string.split(str, ",")
	local count = 0
	for _, v in ipairs(items) do if v ~= "" then count += 1 end end
	return count
end


return StatesService
