local RespawnHandler = {}
local Players = game:GetService("Players")
local RESPAWN_DELAY = 1.25
local NumberUtils = require(game.ReplicatedStorage.SharedScripts.NumberUtils)
local MonetizationConfig = require(game.ReplicatedStorage.Config.MonetizationData)

local RetryAttempt = 10

-- createOverheadUI
local function createOverheadUI(player, character)
	local head = character:WaitForChild("Head")

	-- 1. Create the Main Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadGUI"
	billboard.Adornee = head
	billboard.Size = UDim2.new(5, 0, 2.8, 0)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0) -- Height above head
	billboard.AlwaysOnTop = true -- Makes it visible through walls/other players
	billboard.MaxDistance = 75

	-- 2. Create the invisible container
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = billboard

	-- 3. Add a layout to stack the streak and name perfectly
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = mainFrame
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.Padding = UDim.new(0, 5) 

	-- ==========================================
	-- PLAYER NAME SETUP (Bottom)
	-- ==========================================
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne -- Matches the rounded look in your image
	nameLabel.TextScaled = true
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = mainFrame

	-- Thick Black Outline for Name
	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 4.5
	nameStroke.Parent = nameLabel

	billboard.Parent = head

	-- ==========================================
	-- [NEW]: DYNAMIC VIP TAG UPDATER
	-- ==========================================
	local function updateVIPTag()
		if player:GetAttribute("Pass_VIP") then
			nameLabel.Text = MonetizationConfig.VIPConfig.Tag .. " " .. player.Name
			nameLabel.TextColor3 = MonetizationConfig.VIPConfig.TagColor -- Makes it Gold!
		else
			nameLabel.Text = player.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Pure White
		end
	end

	-- 1. Check immediately when the UI is built
	updateVIPTag()

	-- 2. Listen for changes (Handles slow data loading AND in-game purchases!)
	local connection
	connection = player:GetAttributeChangedSignal("Pass_VIP"):Connect(function()
		---- Prevent memory leaks if the character died and the UI was destroyed
		--if not nameLabel or not nameLabel.Parent then 
		--	connection:Disconnect()
		--	return
		--end
		updateVIPTag()
	end)
	nameLabel.Destroying:Connect(function()
		connection:Disconnect()
	end)
	
end

RespawnHandler.SpawnPlayer = function(player , SpawnLocation)
	
	local Zone = player:GetAttribute("Zone")
	local SpawnLocation 


	if not SpawnLocation then
		warn("⚠️ Critical Error: Default spawn is missing!")
		return
	end
	
	local spawnX = SpawnLocation.Position.X + (math.random() - 0.5) * SpawnLocation.Size.X
	local spawnY = SpawnLocation.Position.Y + (math.random() - 0.5) * SpawnLocation.Size.Y
	local spawnZ = SpawnLocation.Position.Z + (math.random() - 0.5) * SpawnLocation.Size.Z
	local spawnPoint = Vector3.new(spawnX, spawnY, spawnZ) + Vector3.new(0, 5, 0)
	local targetCFrame = CFrame.lookAt(spawnPoint, spawnPoint + SpawnLocation.CFrame.LookVector)
	local Success = true
	for i = 1 , RetryAttempt do 
		if not Success  then
			task.wait(1)
		end
		local streamSuccess, streamErr = pcall(function()
			player:RequestStreamAroundAsync(spawnPoint)
		end)
		if not streamSuccess then
			warn("[Respawn] Stream failed for " .. player.Name .. ": " .. tostring(streamErr))
			Success = false
			continue
		end

		local loadSuccess, loadErr = pcall(function() 
			player:LoadCharacterAsync() 
		end)
		if not loadSuccess then 
			warn("[Respawn] Loading failed for " .. player.Name .. ": " .. tostring(loadErr))
			Success = false
			continue
		end

		Success = true
		break
	end 

	if not Success then 
		player:Kick("Try Joining Again Failed to Load Data")
		return
	end
	local character = player.Character or player.CharacterAdded:Wait()

	character:PivotTo(targetCFrame)
	
end

RespawnHandler.Init = function(player)

	player.CharacterAdded:Connect(function(character)
		
		createOverheadUI(player, character)
		
		
		local humanoid = character:WaitForChild("Humanoid")
				
		local isDead = false 
		if humanoid then
			humanoid.BreakJointsOnDeath = false

			humanoid.Died:Connect(function()
				if isDead then return end
				isDead = true 
				--humanoid.Sit = false
				print("💀 " .. player.Name .. " Died.")
				task.wait(RESPAWN_DELAY)
				if player.Parent then
					RespawnHandler.SpawnPlayer(player)
				end
			end)
		end
	end)
end

return RespawnHandler

