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

*Generic Example of safely finding and updating an item string:*
```lua
local owned: string? = player:GetAttribute("MyOwnedItems")
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
    * **Note:** Since our robust data system ensures all data is loaded before the character spawns, if data is somehow not found when queried by another script, we should simply `return` to abort the operation instead of setting it to `0`. 
    
    *For example:*
    ```lua
    -- ❌ BAD: Defaulting to 0 can corrupt actual data if it just hasn't loaded
    local myStat: number = player:GetAttribute("MyStat") or 0 
    
    -- ✅ GOOD: Safely return and abort the script
    local myStat: number? = player:GetAttribute("MyStat") 
    if not myStat then return end
    ```

5. **Persistence:** `AutoDataSavingService` sweeps the player object periodically and on-leave, reading the live Attributes, string-based Items, and Leaderstats, securely packing them back into their respective DataStores.

---

## Core Services Overview

### 1. AutoDataSavingService
**File Overview:** Orchestrates the automatic persistence of player data across three distinct categories: Leaderstats, Attributes, and Items.
**Functions:**
*   `SaveLeaderstatsData(player: Player)`
    *   **Features:** Specifically saves numerical values attached to the `leaderstats` folder to the `OrderedDataStore`. Clears the loaded flag upon save to prevent duplicate saves.
    *   **Example Usage:** 
        ```lua
        AutoDataSavingService.SaveLeaderstatsData(player: Player)
        ```
*   `SaveAttributesData(player: Player)`
    *   **Features:** Iterates through a predefined list of attributes from the configuration and saves them as a standard dictionary via `DataStoreService`.
    *   **Example Usage:**
        ```lua
        AutoDataSavingService.SaveAttributesData(player: Player)
        ```
*   `SaveItemsData(player: Player)`
    *   **Features:** Packages inventory or cosmetic attributes into a structured table and ensures they are safely saved to the datastore.
    *   **Example Usage:**
        ```lua
        AutoDataSavingService.SaveItemsData(player: Player)
        ```

### 2. DataService
**File Overview:** Provides generalized, robust operations for standard `DataStoreService`. Handles loading, saving, retries, and data reconciliation for table-based structures.
**Functions:**
*   `loadPlayerData(DataType: string, attempts: number, kickOnFail: boolean, player: Player, defaultData: any, setAttributes: boolean)`
    *   **Features:** Attempts to load data with exponential backoff. Reconciles missing keys dynamically and can optionally set the loaded keys as attributes on the player immediately.
    *   **Example Usage:**
        ```lua
        local data: any = DataService.loadPlayerData("MyDataStore", 3, true, player, {MyStat1 = 0, MyStat2 = 5}, true)
        ```
*   `savePlayerData(DataType: string, attempts: number, kickOnFail: boolean, warnOnFail: boolean, player: Player, dataToSave: any)`
    *   **Features:** Uses `UpdateAsync` to safely write table data to the DataStore, preventing older server instances from overwriting newer data.
    *   **Example Usage:**
        ```lua
        DataService.savePlayerData("MyDataStore", 3, false, true, player, {MyStat1 = 10})
        ```

### 3. MonotizationService
**File Overview:** Centralizes all Marketplace logic. Handles the verification of GamePass ownership and processes Developer Product purchases idempotently.
**Functions:**
*   `tryUserOwnsGamePassAsync(retry: number, player: Player)`
    *   **Features:** Checks GamePass ownership asynchronously with network retry safety. If owned, triggers the internal reward granting logic.
    *   **Example Usage:**
        ```lua
        MonotizationService.tryUserOwnsGamePassAsync(3, player: Player)
        ```

### 4. NumberUtils
**File Overview:** A pure utility module for formatting UI and mathematical strings.
**Functions:**
*   `Abbreviate(n: number)`
    *   **Features:** Converts large numbers to string suffixes (e.g., 1000 becomes 1k, 1,000,000 becomes 1M) for clean UI displays.
    *   **Example Usage:**
        ```lua
        local text: string = NumberUtils.Abbreviate(15000) -- returns "15k"
        ```

### 5. OrdinaryDataService
**File Overview:** A wrapper specifically for `OrderedDataStore` used to manage single integer values, allowing for the creation of global leaderboards.
**Functions:**
*   `loadPlayerData(DataType: string, attempts: number, kickOnFail: boolean, player: Player, defaultValue: number, attributeNameToSet: string)`
    *   **Features:** Loads a single `Number` value from an OrderedDataStore and can bind it directly to an attribute or leaderstat.
    *   **Example Usage:**
        ```lua
        OrdinaryDataService.loadPlayerData("MyGlobalStat", 3, false, player, 0, "MyAttribute")
        ```
*   `savePlayerData(DataType: string, attempts: number, kickOnFail: boolean, warnOnFail: boolean, player: Player, intValue: number)`
    *   **Features:** Saves a single `Number` value securely to the OrderedDataStore.
    *   **Example Usage:**
        ```lua
        OrdinaryDataService.savePlayerData("MyGlobalStat", 3, false, true, player, 100)
        ```
*   `startGlobalLeaderboard(DataType: string, baseDelay: number, maxAttempts: number, leaderstatModel: Model, updateTime: number, retryTime: number, titleText: string)`
    *   **Features:** Spawns a persistent background thread to fetch top scores, caches usernames to save API calls, and updates a physical workspace leaderboard model.
    *   **Example Usage:**
        ```lua
        OrdinaryDataService.startGlobalLeaderboard("MyGlobalStat", 2, 20, workspace.MyBoard, 120, 30, "Top Stats")
        ```

### 6. PlayerStateService
**File Overview:** A centralized controller for modifying player statistics. It intercepts state changes to apply active multipliers (like VIP or Gamepasses).
**Functions:**
*   `Update_Stats_FROM_ATTRUBUTE(player: Player, amount: number, reset: boolean, isRbxReward: boolean, initMultiplayer: number, statName: string)`
    *   **Features:** Modifies a specific attribute. Automatically searches for a corresponding "Double" attribute (e.g., `DoubleYourStat`) and applies multipliers before saving the value.
    *   **Example Usage:**
        ```lua
        PlayerStateService.Update_Stats_FROM_ATTRUBUTE(player, 50, false, false, 1, "MyAttribute")
        ```
*   `Update_Stats_FROM_LeaderStats(player: Player, amount: number, reset: boolean, isRbxReward: boolean, initMultiplayer: number, statName: string)`
    *   **Features:** Functions identically to the attribute updater but modifies a physical `ValueBase` object inside the player's `leaderstats` folder.
    *   **Example Usage:**
        ```lua
        PlayerStateService.Update_Stats_FROM_LeaderStats(player, 1, false, false, 1, "MyLeaderstat")
        ```

### 7. RespawnHandler
**File Overview:** Controls the physical character lifecycle, including spawning and UI attachment.
**Functions:**
*   `Init(player: Player, SpawnLocation: BasePart)`
    *   **Features:** Binds to the player's death event to initiate the respawn sequence automatically.
    *   **Example Usage:**
        ```lua
        RespawnHandler.Init(player, workspace.SpawnPart)
        ```
*   `SpawnPlayer(player: Player, SpawnLocation: BasePart)`
    *   **Features:** Forces character loading and safely teleports their PrimaryPart to a specific spawn location. Dynamically attaches overhead UIs.
    *   **Example Usage:**
        ```lua
        RespawnHandler.SpawnPlayer(player, workspace.SpawnPart)
        ```

### 8. UI_Management
**File Overview:** A centralized manager for handling the visibility and state of UI screens, providing built-in animation methods and a notification system.
**Functions:**
*   `SetTheme(themeName: string)`
    *   **Features:** Updates the visual theme of the UI dynamically.
    *   **Example Usage:**
        ```lua
        UI_Management.SetTheme("Dark")
        ```
*   `ShowScreen(name: string, animation: string)` & `HideScreen(...)`
    *   **Features:** Toggles UI panel visibility with predefined tween animations (e.g., Fade, Slide, Scale).
    *   **Example Usage:**
        ```lua
        UI_Management.ShowScreen("ShopPanel", "Fade")
        ```
*   `ShowNotification(text: string, duration: number, notificationType: string)`
    *   **Features:** Displays a temporary pop-up toast notification to the user.
    *   **Example Usage:**
        ```lua
        UI_Management.ShowNotification("Purchase Successful!", 3, "Success")
        ```
*   `AnimateElement(element: GuiObject, animation: string, callback: () -> ())`
    *   **Features:** Helper to apply specific `TweenService` effects to UI elements.
    *   **Example Usage:**
        ```lua
        UI_Management.AnimateElement(myButton, "Bounce")
        ```

---

## Architecture & Initialization

### 📜 Naming & Workflow Conventions
Before examining the initialization scripts, note our standardized naming convention for initialization functions:
- **`_Init`**: Primary server-side initialization logic that runs **outside** of the `PlayerAdded` event (global startup).
- **`init`**: Player-specific initialization logic that runs **inside** of the `PlayerAdded` event.
- **`_init`**: Client-side initialization logic residing within **StarterPlayer** scripts.

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
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
-- ...require other services...

-- 2. Remote setup to confirm client event loading/race conditions
local GuiLoadedRemote: RemoteEvent = ReplicatedStorage:WaitForChild("Assets").Remotes.OnClientEventLoaded

-- 3. Defining required Modules 
-- 4. Defining variables from workspace
-- 5. Loaded data checker setup 
_G.DataLoaded = {}

-- 6. Disabling native features
Players.CharacterAutoLoads = false

-- 7. Server _Init (Initializing main functions safely via pcall wrappers)
-- Example: SafeInit("MySystem", function() MySystem._Init() end)

-- 8. Confirming onClientEvent loaded
GuiLoadedRemote.OnServerEvent:Connect(function(player: Player, data: any)
    -- Validate and flag client readiness
end)

-- 9. On Player Added
Players.PlayerAdded:Connect(function(player: Player)
    -- 10. Player init (Loading data via DataService)
    -- 10.5. Ensuring data is loaded flag (_G.DataLoaded[id] = true)
    -- 11. Initializing monetization, respawn, and other services
    -- 12. Character conditions / CharacterAdded logic
end)

-- 13. On Player Leave (Spawns independent save threads)
Players.PlayerRemoving:Connect(function(player: Player)
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
local Players: Players = game:GetService("Players")
local Player: Player = Players.LocalPlayer
-- Yield for required client folders (e.g., WaitForChild("Services", 5))

-- 2. Basic models init
-- Example: MyLocalService._init()

-- 3. Character Lifecycle Management / The "Already Loaded vs Added" Pattern
local hasInitializedOnce: boolean = false

local function OnCharacterAdded(character: Model)
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
Player.CharacterRemoving:Connect(function(character: Model)
    -- some stuff on character removal if needed
end)
```
---

## 📂 Advanced Features & Recommended File Structure

### 🏗️ File Structure
Use `WaitForChild` in local scripts. On the server, whether to use `WaitForChild` depends on the condition (e.g., if objects are created dynamically while playing or after map loading).

**ReplicatedStorage/**
*   `Config/`: Stores default data tables (e.g., `DefaultData.lua`).
*   `Assets/`:
    *   `Remotes/`: All RemoteEvents and RemoteFunctions.
    *   `Models/`: Shared models.
    *   `VFX/SFX/`: Visual and sound effects (if large or server-dependent, store in `ServerStorage`).
*   `SharedScripts/`: Modules used by both server and client.
*   `Classes/`: OOP class definitions (if needed).

**ServerScriptService/**
*   `ServerInit.server.lua`: Master entry point.
*   `Services/`: Modular server-side logic.
*   `Systems/`: Higher-level gameplay systems.

**StarterGui/**
*   `ClientMain.client.lua`: Main UI controller.

**ServerStorage/**
*   `Models/`: Server-only models.
*   `Musics/`: Audio assets.
*   `TRASH/`: To store old or unused systems for reference.

**StarterPlayer/**
*   **StarterCharacterScripts**:
    *   `CharacterInit`: Character-specific initialization.
    *   `GuiInit`: Local UI setup.
*   **StarterPlayerScripts**:
    *   `PlayerInit`: Global client initialization.
    *   `Services/`: Client-side modules.
    *   `Systems/`: Client-side gameplay logic.

### 🔧 UI & Logic Guidelines
*   **Polish:** GUI interfaces should contain tweens and sound effects to make the game look and feel "good."
*   **Control:** UI should mostly be controlled by `StarterCharacter` scripts rather than `StarterPlayer` scripts.
*   **Race Conditions:** Ensure there are no race conditions. Specifically, pay attention to `OnClientEvent` race conditions (as mentioned in the `ServerInit` architecture).

---

## 🛠️ Best Practices

### ⚡ Performance
*   **Object Pooling:** Use object pooling for frequently created/destroyed elements.
*   **Connection Cleanup:** Implement proper cleanup for all event connections.
*   **Data Caching:** Cache frequently accessed data.
*   **Heartbeat Optimization:** Use heartbeat connections sparingly.

### 🛡️ Security
*   **Server Validation:** Always validate data on the server.
*   **Rate Limiting:** Use rate limiting for all remote events.
*   **Trust No One:** Never trust client-sent data.
*   **Anti-Exploit:** Implement proper anti-exploit measures.

### 🎨 User Experience
*   **Visual Feedback:** Provide visual feedback for all interactions.
*   **Consistent Timing:** Use consistent animation timing.
*   **Error Handling:** Implement proper error handling with user-friendly messages.
*   **Accessibility:** Support both mobile and desktop interfaces.
```
