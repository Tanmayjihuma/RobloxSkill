-- this is kinda example can need modifications 
local RespawnHandler = {}
local Players = game:GetService("Players")
local RESPAWN_DELAY = 1.25
local NumberUtils = require(game.ReplicatedStorage.SharedScripts.NumberUtils)


-- createOverheadUI(EXAMPLE) only if needed  ask 
local function createOverheadUI(player, character)
	local head = character:WaitForChild("Head")
	-- local Leaderstats = player:WaitForChild("leaderstats")
	-- if Leaderstats then
	-- end
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
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Pure White
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
end

RespawnHandler.SpawnPlayer = function(player, SpawnLocation)
	local success, err = pcall(function() 
		player:LoadCharacterAsync() 
	end)

	if not success then 
		warn("⚠️ LoadCharacter Failed for " .. player.Name .. ": " .. tostring(err)) 
		return 
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")

	if root and SpawnLocation then
		-- ADD SOME SPECIAL FUNTIONS FOR EXAMPLE :-
		--createOverheadUI(player, character) 
		root.Anchored = true 
		root.CFrame = SpawnLocation.CFrame + Vector3.new(0, 5, 0)
		task.wait(0.2)
		root.Anchored = false

	else
		warn("⚠️ Assigned spawn for " .. player.Name .. " is missing a 'SpawnPoint' part!")

	end
end

RespawnHandler.Init = function(player, SpawnLocation)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart")

		local isDead = false 

		if humanoid and root then
			humanoid.BreakJointsOnDeath = false

			humanoid.Died:Connect(function()
				if isDead then return end
				isDead = true 
				--humanoid.Sit = false
				print("💀 " .. player.Name .. " Died.")
				task.wait(RESPAWN_DELAY)
				if player.Parent then
					RespawnHandler.SpawnPlayer(player, SpawnLocation)
				end
			end)
		end
	end)
	
	
end

return RespawnHandler
