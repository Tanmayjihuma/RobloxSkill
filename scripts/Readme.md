# Roblox Development Helper Scripts

**System Prompt / AI Context:**
This repository contains a modular, general-purpose framework for Roblox game development. The services provided are designed to handle any arbitrary data structure, stat, or item. When utilizing these scripts, replace generic placeholders like `YourData`, `YourAttribute`, or `YourStat` with your specific game logic.

---

## 🌊 The Data Flow Architecture

Before diving into individual scripts, it is crucial to understand how data moves through this framework. Roblox has specific engine limitations (e.g., Attributes cannot store Lua tables, and Global Leaderboards require single numbers via OrderedDataStore). 

We solve this by feeding defaults from `ReplicatedStorage.Config.DefaultData` and splitting our data into three distinct extraction types:

### 1. Attribute Data (Standard Stats)
We load a table of standard stats (like levels, experience, or standard flags) and immediately assign them as Attributes on the player. Because our `AutoDataSavingService` dynamically reads the `DefaultData` config, any attribute listed there is automatically extracted from the player and safely saved. This ensures data is never lost.

### 2. Items Data (String-Based Arrays)
Because **Roblox Attributes cannot store tables**, we store player inventories and owned items as comma-separated strings (e.g., `"item1,item2,item3"`). This data is loaded from its own specific DataStore name, separate from standard attributes, and saved by manually packaging the strings back into a table in the saving service.
*Generic Example of safely granting an item:*
```lua
local owned = player:GetAttribute("MyOwnedItems")
if not owned then return end -- Prevent data loss if data hasn't loaded yet!

-- Check if the player already owns the item to prevent duplicates
if not string.find(owned, "NewItemName") then
    player:SetAttribute("MyOwnedItems", owned .. ",NewItemName")
end
```

### 3. Leaderstat Data (Ordered Data)
Data that needs to be displayed on a Global Leaderboard (like Wins or Highest Streak) cannot be stored in a normal table. It must be saved as standalone numbers using `OrdinaryDataService` (a wrapper for `OrderedDataStore`). These numbers are loaded and assigned directly to the `ValueBase` objects inside the player's `leaderstats` folder.

### The Lifecycle Control (ServerInit Process)
1. **Initialization:** `ServerInit` loads all 3 data types from the DataStores.
2. **Assignment:** It assigns the loaded data to Attributes (for standard stats and string-based item lists) and to the `leaderstats` folder. 
3. **Validation:** It flags the data as successfully loaded (`_G.DataLoaded`). Only then does it allow the physical character to spawn.
4. **Modification:** Throughout gameplay, use `PlayerStateService` to change these stats safely (it handles multipliers automatically). Use `GetAttribute()` and `.Changed` on leaderstats to allow other scripts to react to data changes.
    * **Note:** Now since we used so good data system and all data loaded for all other script if data not find somehow we can just return instead of making it 0 or default (not use like `local DataStats = player:GetAttribute("Stats") or 0` instead like `local DataStats = player:GetAttribute("DataStats")  if not DataStats then return end`)
5. **Persistence:** `AutoDataSavingService` sweeps the player object periodically and on-leave, reading the live Attributes, string-based Items, and Leaderstats, securely packing them back into their respective DataStores.

---

## Core Services Overview

### 1. AutoDataSavingService
**File Overview:** Orchestrates the automatic persistence of player data across three distinct categories: Leaderstats, Attributes, and Items.
**Functions:**
*   `SaveLeaderstatsData(player)`
    *   **Features:** Specifically saves numerical values attached to the `leaderstats` folder to the `OrderedDataStore`. Clears the loaded flag upon save to prevent duplicate saves.
    *   **Example Usage:** `AutoDataSavingService.SaveLeaderstatsData(player)`
*   `SaveAttributesData(player)`
    *   **Features:** Iterates through a predefined list of attributes from the configuration and saves them as a standard dictionary via `DataStoreService`.
    *   **Example Usage:** `AutoDataSavingService.SaveAttributesData(player)`
*   `SaveItemsData(player)`
    *   **Features:** Packages inventory or cosmetic attributes into a structured table and ensures they are safely saved to the datastore.
    *   **Example Usage:** `AutoDataSavingService.SaveItemsData(player)`

### 2. DataService
**File Overview:** Provides generalized, robust operations for standard `DataStoreService`. Handles loading, saving, retries, and data reconciliation for table-based structures.
**Functions:**
*   `loadPlayerData(DataType, attempts, kickOnFail, player, defaultData, setAttributes)`
    *   **Features:** Attempts to load data with exponential backoff. Reconciles missing keys dynamically and can optionally set the loaded keys as attributes on the player immediately.
    *   **Example Usage:** `local data = DataService.loadPlayerData("MyDataStore", 3, true, player, {MyStat1 = 0, MyStat2 = 5}, true)`
*   `savePlayerData(DataType, attempts, kickOnFail, warnOnFail, player, dataToSave)`
    *   **Features:** Uses `UpdateAsync` to safely write table data to the DataStore, preventing older server instances from overwriting newer data.
    *   **Example Usage:** `DataService.savePlayerData("MyDataStore", 3, false, true, player, {MyStat1 = 10})`

### 3. MonotizationService
**File Overview:** Centralizes all Marketplace logic. Handles the verification of GamePass ownership and processes Developer Product purchases idempotently.
**Functions:**
*   `tryUserOwnsGamePassAsync(retry, player)`
    *   **Features:** Checks GamePass ownership asynchronously with network retry safety. If owned, triggers the internal reward granting logic.
    *   **Example Usage:** `MonotizationService.tryUserOwnsGamePassAsync(3, player)`

### 4. NumberUtils
**File Overview:** A pure utility module for formatting UI and mathematical strings.
**Functions:**
*   `Abbreviate(n)`
    *   **Features:** Converts large numbers to string suffixes (e.g., 1000 becomes 1k, 1,000,000 becomes 1M) for clean UI displays.
    *   **Example Usage:** `local text = NumberUtils.Abbreviate(15000) -- returns "15k"`

### 5. OrdinaryDataService
**File Overview:** A wrapper specifically for `OrderedDataStore` used to manage single integer values, allowing for the creation of global leaderboards.
**Functions:**
*   `loadPlayerData(DataType, attempts, kickOnFail, player, defaultValue, attributeNameToSet)`
    *   **Features:** Loads a single `Number` value from an OrderedDataStore and can bind it directly to an attribute or leaderstat.
    *   **Example Usage:** `OrdinaryDataService.loadPlayerData("MyGlobalStat", 3, false, player, 0, "MyAttribute")`
*   `savePlayerData(DataType, attempts, kickOnFail, warnOnFail, player, intValue)`
    *   **Features:** Saves a single `Number` value securely to the OrderedDataStore.
    *   **Example Usage:** `OrdinaryDataService.savePlayerData("MyGlobalStat", 3, false, true, player, 100)`
*   `startGlobalLeaderboard(DataType, baseDelay, maxAttempts, leaderstatModel, updateTime, retryTime, titleText)`
    *   **Features:** Spawns a persistent background thread to fetch top scores, caches usernames to save API calls, and updates a physical workspace leaderboard model.
    *   **Example Usage:** `OrdinaryDataService.startGlobalLeaderboard("MyGlobalStat", 2, 20, workspace.MyBoard, 120, 30, "Top Stats")`

### 6. PlayerStateService
**File Overview:** A centralized controller for modifying player statistics. It intercepts state changes to apply active multipliers (like VIP or Gamepasses).
**Functions:**
*   `Update_Stats_FROM_ATTRUBUTE(player, amount, reset, isRbxReward, initMultiplayer, statName)`
    *   **Features:** Modifies a specific attribute. Automatically searches for a corresponding "Double" attribute (e.g., `DoubleYourStat`) and applies multipliers before saving the value.
    *   **Example Usage:** `PlayerStateService.Update_Stats_FROM_ATTRUBUTE(player, 50, false, false, 1, "MyAttribute")`
*   `Update_Stats_FROM_LeaderStats(player, amount, reset, isRbxReward, initMultiplayer, statName)`
    *   **Features:** Functions identically to the attribute updater but modifies a physical `ValueBase` object inside the player's `leaderstats` folder.
    *   **Example Usage:** `PlayerStateService.Update_Stats_FROM_LeaderStats(player, 1, false, false, 1, "MyLeaderstat")`

### 7. RespawnHandler
**File Overview:** Controls the physical character lifecycle, including spawning and UI attachment.
**Functions:**
*   `Init(player, SpawnLocation)`
    *   **Features:** Binds to the player's death event to initiate the respawn sequence automatically.
    *   **Example Usage:** `RespawnHandler.Init(player, workspace.SpawnPart)`
*   `SpawnPlayer(player, SpawnLocation)`
    *   **Features:** Forces character loading and safely teleports their PrimaryPart to a specific spawn location. Dynamically attaches overhead UIs.
    *   **Example Usage:** `RespawnHandler.SpawnPlayer(player, workspace.SpawnPart)`

### 8. UI_Management
**File Overview:** A centralized manager for handling the visibility and state of UI screens, providing built-in animation methods and a notification system.
**Functions:**
*   `SetTheme(themeName)`
    *   **Features:** Updates the visual theme of the UI dynamically.
    *   **Example Usage:** `UI_Management.SetTheme("Dark")`
*   `ShowScreen(name, animation)` & `HideScreen(...)`
    *   **Features:** Toggles UI panel visibility with predefined tween animations (e.g., Fade, Slide, Scale).
    *   **Example Usage:** `UI_Management.ShowScreen("ShopPanel", "Fade")`
*   `ShowNotification(text, duration, notificationType)`
    *   **Features:** Displays a temporary pop-up toast notification to the user.
    *   **Example Usage:** `UI_Management.ShowNotification("Purchase Successful!", 3, "Success")`
*   `AnimateElement(element, animation, callback)`
    *   **Features:** Helper to apply specific `TweenService` effects to UI elements.
    *   **Example Usage:** `UI_Management.AnimateElement(myButton, "Bounce")`

---

## Architecture & Initialization

### 9. ServerInit
**Location:** `ServerScriptService`
**File Overview:** The master server entry point. It orchestrates the startup of all server-side services and strictly controls the player data lifecycle.

**Execution Steps:**
1. Defining Basic Services
2. Remote setup to confirm client event loading/race conditions (e.g., GuiLoadedRemote)
3. Defining required Modules
4. Defining variables from workspace
5. Loaded data checker setup (`_G.DataLoaded`)
6. Disabling native features (e.g., `CharacterAutoLoads = false`)
7. Server `_Init` (Initializing main functions safely via pcall wrappers)
8. Confirming `onClientEvent` loaded
9. On Player Added (Includes sub-steps 10, 10.5, 11, and 12 for loading data, setting attributes, initializing monetization/respawn, and handling character additions)
13. On Player Leave (Spawns independent save threads)
14. On Game Crash / Server Shutdown (`BindToClose` logic)
15. Some other stuff (Reserved for future systems)
16. Auto Data Saving Loop (Saves all player data periodically)

**Structural Template:**
```lua
-- 1. Defining Basic Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- ...require other services...

-- 2. Remote setup to confirm client event loading/race conditions
local GuiLoadedRemote = ReplicatedStorage:WaitForChild("Assets").Remotes.OnClientEventLoaded

-- 3. Defining required Modules 
-- 4. Defining variables from workspace
-- 5. Loaded data checker setup 
_G.DataLoaded = {}

-- 6. Disabling native features
Players.CharacterAutoLoads = false

-- 7. Server _Init (Initializing main functions safely via pcall wrappers)
-- Example: SafeInit("MySystem", function() MySystem._Init() end)

-- 8. Confirming onClientEvent loaded
GuiLoadedRemote.OnServerEvent:Connect(function(player, data)
    -- Validate and flag client readiness
end)

-- 9. On Player Added
Players.PlayerAdded:Connect(function(player)
    -- 10. Player init (Loading data via DataService)
    -- 10.5. Ensuring data is loaded flag (_G.DataLoaded[id] = true)
    -- 11. Initializing monetization, respawn, and other services
    -- 12. Character conditions / CharacterAdded logic
end)

-- 13. On Player Leave (Spawns independent save threads)
Players.PlayerRemoving:Connect(function(player)
    -- task.spawn save functions
end)

-- 14. On Game Crash / Server Shutdown
game:BindToClose(function()
    -- Loop through active players, spawn saves, and yield to ensure completion
end)

-- 15. Some other stuff (Reserved)

-- 16. Auto Data Saving Loop
task.spawn(function()
    while true do
        task.wait(600)
        -- Loop through players and save
    end
end)
```

### 10. PlayerInit
**Location:** `StarterPlayer > StarterPlayerScripts` (or `StarterPlayer`)
**File Overview:** The master client entry point. Boots up local services when the client environment loads and ensures logic fires correctly relative to the character spawning.

**Execution Steps:**
1. Loading basic things and services (Yields for required client-side folders)
2. Basic models init
3. Character Lifecycle Management / The "Already Loaded vs Added" Pattern (Handling the lock to ensure "run once" scripts don't double-fire, and "run every respawn" scripts execute properly)
4. Cleanup on death/removal (Destroying specific UI elements or effects when the character is removed)

**Structural Template:**
```lua
-- 1. Loading basic things and services
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
-- Yield for required client folders (e.g., WaitForChild("Services", 5))

-- 2. Basic models init
-- Example: MyLocalService._Init()

-- 3. Character Lifecycle Management / The "Already Loaded vs Added" Pattern
local hasInitializedOnce = false

local function OnCharacterAdded(character)
    -- [RUN EVERY RESPAWN LOGIC GOES HERE]
    
    if not hasInitializedOnce then
        hasInitializedOnce = true
        -- [RUN ONCE (FIRST SPAWN) LOGIC GOES HERE]
    end
end

-- Catch the character if it already loaded before the script ran
if Player.Character then 
    task.spawn(OnCharacterAdded, Player.Character) 
end

-- Listen for all future respawns
Player.CharacterAdded:Connect(OnCharacterAdded)

-- 4. Cleanup on death/removal
Player.CharacterRemoving:Connect(function(character)
    -- Destroy specific UI elements or reset visual effects
end)
```
