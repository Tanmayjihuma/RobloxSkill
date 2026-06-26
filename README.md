# Roblox Game Development Skill Main 

**Note for AI:** This context provides pre-made modules, scripts, architectural 

guidelines, and common mistakes to avoid. While you must follow these rules to build and improve the game, always apply standard game development common sense. Do not ignore fundamental logic or industry best practices simply because they aren't explicitly mentioned here. 

## **DESCRIPTION** 

Expert Roblox game developer specializing in Luau scripting, game mechanics, UI/UX design, and monetization strategies. Assists with everything from simple scripts to complex multiplayer experiences. 

This Contains all created script modules , Common problem and error made during scripting , File structures , Way to manage scripts , Instructions for script Game engine , UI , Data Storage , and Command panel. 

## **RESOURCE LIBRARY** 

This skill includes a comprehensive collection of production-ready resources: 

- 📜 [Helper Scripts](https://github.com/Tanmayjihuma/RobloxSkill/tree/main/scripts) - Professional utility modules for data  management, Stats management , UI , game flow , Number utils and Audio with File Structure. 

- 📚 [Development Resources](https://github.com/Tanmayjihuma/RobloxSkill/tree/main/resources) - Contains Some Game templates , Asset libraries, debugging guides, performance optimization tools, and quick reference materials. 

## **CORE CAPABILITIES** 

## **LUAU PROGRAMMING** 

- **Modern Luau Features** : Utilize type annotations, generics, the New Type Solver (general release), improved type inference/autocomplete, and performance optimizations 

- **Script Architecture** : Implement clean, modular code with proper separation of concerns 

- **Performance Optimization** : Write efficient scripts that handle large player counts 

**Error Handling** : Robust error management and debugging techniques 

## **LUAU TYPE SYSTEM UPDATES** 

- **New Type Solver** : General release (no longer a Studio Beta); enabled by default for `nonstrict` and `nocheck` modes starting January 7, 2026 

- **Key Improvements** : Better type inference, fewer false positives, stronger 

- generics support, and improved autocomplete 

- **Legacy Solver Timeline** : The legacy solver remains available through 2026, but it is slated for removal 

- **Migration Guidance** : Most code works without changes, but a few edge cases may need explicit type annotations or cleanup 

- **Best Practices** : Prefer explicit annotations on public APIs, use generics where appropriate, and lean on improved autocomplete for faster iteration 

```
-- New Type Solver infers types more accurately
local functionprocessPlayer(player: Player)
    local name: string = player.Name  -- inferred correctly
    local team = player.Team  -- Team? properly inferred
end
```

## **GENERAL MISTAKE TO AVOID** 

- **No Strict Typing:** Do not use type casting or the `!strict` mode in your 

- code. 

- **Keep Comments Concise:** Avoid large, decorative comment blocks. Simply explain what the module does at the very end of the module script, and provide brief explanations for what each function does before defining function . 

- **Strict Data Handling:** Always use our custom Data Services to load and save data ( view ). 

Once loaded, store the data using `leaderstats` or `SetAttribute` . 

When retrieving data via `leaderstats` or `GetAttribute` , **never fall back to a default value** or 0 if it returns `nil` . 

_Incorrect:_ `local coins = player:GetAttribute("Coins") or 0` 

_Correct:_ `local coins = player:GetAttribute("Coins") if not coins then return end` 

- **Prevent** **`WaitForChild` Abuse:** Understand the difference between server and client loading: 

**Server Scripts:** The server loads all pre-existing static items in the Explorer before running scripts. You generally do not need `WaitForChild` for static objects. Only use it for dynamically created/destroyed items or character handling. 

**Local Scripts:** Local scripts start running as soon as they load; they do not wait for the entire server to replicate to the client's computer. Because of this, `WaitForChild` is highly recommended for UI elements and replicating 

instances. 

_**Note** :_ Avoid using `WaitForChild` with a timeout parameter in most cases. Choose between `FindFirstChild` and `WaitForChild` logically based on these loading mechanics. 

**Account for Race Conditions:** Be mindful of network timing issues. For example, the server might fire a RemoteEvent before the client has fully loaded and connected its `OnClientEvent` listener solution given in (HelperScript). And keep mind on Replication Race. 

**Do Not Abuse** **`RunService` :** Only use `RunService` when Needed. 

Misusing it or forgetting to disconnect events can cause severe memory leaks and performance drops. 
---
## **DEVELOPMENT WORKFLOW** 
---
1. **Architecture:** 

```
Root/
├──WorkSpace/
├── ReplicatedStorage/
│   ├── Config/
│   │   ├── DefaultData.lua          -- Default player stats & configs
│   │   ├── Gamepasses.lua
│   │   └── DeveloperProducts.lua          
│   ├── Assets/
│   │   ├── Remotes/                 -- All RemoteEvents & Functions
│   │   ├── Models/                  -- Shared 3D models
│   │   └── VFX_SFX/                 -- Visual/Sound effects (Shared)
│   ├── SharedScripts/
│   │   └── NumberUtils.lua          -- EX: Utilities used by both Server/Client
│   └── Classes/                     -- OOP class definitions (if needed)
│
├── ServerScriptService/
│   ├── ServerInit.lua               -- Master server entry point
│   ├── Services/                    -- Modular server-side logic
│   │   ├── DataManager/             -- DATASERVICE.LUA, AUTODATASAVINGSERVICE.LUA, ORDINARY DATA SAVING SERVICE
│   │   │   ├── DataService.lua
│   │   │   ├── AutoDataSavingService.lua
│   │   │   └── OrdinaryDataService.lua
│   │   ├── MonetizationService.lua
│   │   └── StatesService.lua        -- Player stats & multipliers
│   └── Systems/                     -- server side gameplay systems
│       └── RespawnHandler.lua       -- RESPAWN HANDLER
│
├── ServerStorage/
│   ├── Models/                      -- Server-only assets
│   ├── Musics/                      -- Audio assets
│   └── TRASH/                       -- Archive of legacy systems (TO STORE OLD SYSTEMS THAT WAS NOT USEFULL)
│
├── StarterGui/
│		├── ClientMainGui
│   └──OtherGuis         -- Main UI controller logic
│ 
│
└── StarterPlayer/
    ├── StarterCharacterScripts/     -- CHARACTER INIT, GUI INIT (Runs every time character spawns)
    │   ├── CharacterInit.lua
    │   └── GuiInit.lua
    ├── StarterPlayerScripts/        -- PLAYER INIT (Runs once when player joins)
    │   └── PlayerInit.lua           -- Master client entry point
    ├── LocalServices/                -- Client-side modules (e.g., UI_Management.lua)
    └── LocalSystems/                 -- Client-side gameplay logic
```
**Note:** some of these service and scripts are Shown  in helper Script 
---
## 2. **Data and Stats Management** 

Roblox has specific engine limitations (e.g., Attributes cannot store Lua tables, and Global Leaderboards require single numbers via OrderedDataStore). 

We solve this by feeding defaults from `ReplicatedStorage.Config.DefaultData` and splitting our data into three distinct extraction types: 

## **1. Attribute Data (Standard Stats)** 

We load a table of standard stats (like levels, experience, or standard flags) and immediately assign them as Attributes on the player. Because our [`AutoDataSavingService`](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/AutoDataSavingService.lua) dynamically reads the `DefaultData` config, any attribute listed there is automatically extracted from the player and safely saved. This ensures data is never lost. 

## **2. Items Data (String-Based Arrays & Stacks)** 

Because Roblox Attributes cannot store tables, we store player inventories and owned items as comma-separated strings. 

We support Stackable Items using the `ItemName(Count)` format: 

Example: 

```
Sword,Potion(5),Wood(10)
```

We use [`StatesService`](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/StatesService.lua) to manage these strings safely. 

## **RECOMMENDED USAGE (VIA STATESSERVICE)** 

```
local StatesService =
require(game.ServerScriptService.Services.StatesService)
--Adding items
StatesService.AddItem(player,"Inventory","Wood",true)--Wood(1)
StatesService.AddItem(player,"Inventory","Wood",true)--Wood(2)
--Checking ownership
if StatesService.HasItem(player,"Inventory","Wood") then
```

```
    local count = StatesService.GetStackAmount(player,"Inventory",
"Wood")
print("Player has ".. count .." Wood")
end
--
 Removing items
StatesService.RemoveItem(player,"Inventory","Wood",true,false)--
Wood(1)
```
---
## **3. Leaderstat Data (Ordered Data)** 

Data that needs to appear on a Global Leaderboard (such as Wins, Kills, or Highest 

Streak) cannot be stored in a normal table. 

Instead, these values are stored separately using [`OrdinaryDataService`](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/OrdinaryDataService.lua) (a wrapper around OrderedDataStore). 

When players join, these values are loaded and assigned directly to the appropriate `ValueBase` objects inside the player's `leaderstats` folder. 

## **The Lifecycle Control (ServerInit Process)** 

## **1. INITIALIZATION** 

[`ServerInit`](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/ServerInit.lua) loads all three data types from their respective DataStores. 

## **2. ASSIGNMENT** 

Loaded data is assigned to: 

- Player Attributes (standard stats) 

- String-based inventory attributes 

`leaderstats` values 

using [DataService](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/DataService.lua) and [OrdinaryDataService](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/OrdinaryDataService.lua)

## **3. VALIDATION** 

Once loading succeeds: 

```
_G.DataLoaded[player.UserId]=true
```

Only after this validation step is the player's character allowed to spawn using Custom Respawn Handler. 

## **4. MODIFICATION** 

Throughout gameplay, use `StatesService` to modify stats and inventory safely. 

Other systems should use: 

```
player:GetAttribute("StatName")
```

and 

```
leaderstats.Changed
```

to react to data updates. 

## **IMPORTANT NOTE** 

Since the framework guarantees data loads before character spawning, missing data should be treated as an error condition. 

Do NOT default values to `0` . 

Bad: 

```
local myStat = player:GetAttribute("MyStat") or 0
```

Good: 

```
local myStat = player:GetAttribute("MyStat")
if not myStat then
return
end
```

Defaulting to `0` can accidentally overwrite or corrupt real player data if something 

unexpected occurs. 

## **5. PERSISTENCE** 

[`AutoDataSavingService`](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/AutoDataSavingService.lua) periodically scans the player and also runs when the 

player leaves. 

It extracts: 

Live Attributes 

- String-based item data 

- Leaderstats values 

The data is then packed and saved back into their respective DataStores 

automatically. 

## **Summary** 

The framework separates player data into three categories: 

1. Attributes → Standard player stats. 

2. String-Based Item Data → Inventories and owned items. 

3. Ordered Data → Global leaderboard values. 

`ServerInit` loads and validates data before gameplay begins, while 

`AutoDataSavingService` continuously handles persistence in the background, 

ensuring reliable and safe data storage. 

**Note:** When retrieving data via `leaderstats` or `GetAttribute` , **never fall back** 

**to a default value** or 0 if it returns `nil` This can cause data loss. 

## 3. **Networking** 

## **DIFFERENT TYPES OF REMOTES** 

|**Type**|**Direction**|**Returns value?**|**Use when**||
|---|---|---|---|---|
|`RemoteEvent`|Any<br>direction|No (fire-and-<br>forget)|Notifying server of player action,<br>broadcasting state||
|`RemoteFunctio`<br>`n`|Client →<br>Server|Yes (yields caller)|Client needs a result back (e.g.<br>fetch inventory)||
|`UnreliableRem`<br>`oteEvent`|Any<br>direction|No|High-frequency updates where<br>dropped packets are fine||



## **COMMON MISTAKES** 

Create RemoteEvents/Functions manually in 

## `ReplicatedStorage/Assets/Remotes` (Never create Remotes using 

- scripts) 

- NEVER trust the client. Every Remote Event argument is attacker-controlled 

(Server-authoritative: the server decides outcomes and do the math ; the client is display-only). 

- Rate limit all remotes. Use a per-player cooldown table at a minimum (so 

- client just not able to spam the 100 of remote per second). 

- Add server-side calculation cooldowns or timeouts based on specific conditions. 

- Handle race conditions where the server fires a remote before the client's 

- `OnClientEvent` is fully loaded. 
---
## 4. **UI Management** 

- **How to make Responsive GUI:** ( for command panel script or create direct 

GUI by MCP server if possible) 

- Make GUI with offset and at the Parent Frame of all the Frame add a UIAspectRatioConstraint now i use my plugin that convert the Offset Gui to Scale gui (make sure u told me to do that in output) and do not make ai slop 

ui 

## **Common mistake to avoid** 

its is not recommended creating GUI using scripts better give me command pannel script that create GUI if needed always put Gui handler script in Starter Character Script 

## **Tips** 

Add Proper sound on Hover click , Tweens etc depends on how its look 

Use [Assets Resources](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/resources/asset_library.md) for sounds in UI and some pre Define function For UI Management written in This [(View)](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/UI_Management.lua)
---
## 5. **Monotization Management** 

## **Use Custom Service Monotization Service** [(view)](https://github.com/Tanmayjihuma/RobloxSkill/blob/main/scripts/MonetizationService.lua)

**Features:** `_Init() , Init(player)` ( **Use them in Server Init** ) **Features:** Checks GamePass ownership asynchronously with network retry safety. If owned, triggers the internal reward granting logic. 
---
## 6. **SFX / VFX** 

- **Optimize Instance Management:** Keep performance in mind by reusing 

existing instances rather than creating a lot of new ones for no reason. **Prevent Lag with Client-Side Control:** Make sure certain tweens and VFX are controlled by a `LocalScript` (client-side) so they don't look laggy. You will need to carefully evaluate which effects should be handled by the client versus the server. 

**Reduce Game Loading Times:** Add sounds to `SoundService` from `ServerStorage` to minimize loading times. Avoid putting  large Sounds Effect and  Music , directly into `ReplicatedStorage` , as this can significantly increase how long the game takes to load. 
---
## 7. **Animation Mangement** 

## **Object References** 

   - **`Animation` :** Asset container (holds the `AnimationId` ). **`Animator` :** The playback engine. Always lives inside a `Humanoid` 

   - or `AnimationController` . 

   - **`AnimationController` :** Replaces `Humanoid` for non-character 

   - models (props, vehicles). 

- **`AnimationTrack` :** The actual track returned by `LoadAnimation()` . Controls play, stop, speed, and events. 

- **Where to Run Code (Network Authority) Local Player Character:** `LocalScript` (StarterCharacterScripts). Animations played on the client's `Animator` automatically replicate to the server. 

**NPC / Server Model:** `Script` (Server-side). The server owns the network authority. 

## **Loading & Playing (Pro-Level Reference)** 

_AI Pitfall: Always use_ _`Animator:LoadAnimation()` . Calling this_ 

_on the Humanoid is deprecated._ 

Lua 
```
local animator = character:WaitForChild("Humanoid"):WaitForChild("Animator")
local track = animator:LoadAnimation(animationInstance)
```

```
track:Play(0.1,1,1)-- fadeTime, weight, speed
track:Stop(0.1)-- fadeOutTime
```

**Priority:** `Core < Idle < Movement < Action1-4` . Higher priority overwrites lower on shared joints. **Events:** * `track.Stopped:Once(fn)` (Cleanup). 

```
track:GetMarkerReachedSignal("MarkerName"):Connect(function())
```
(Perfect for syncing sounds/VFX). 

## **Upper-Body Animations (not part of scripting)** 

There is no script to "mask" joints at runtime. If you want a player to reload a gun while running, the reload animation **must be** 

**authored with the lower body unkeyed** in the Animation Editor. If legs are keyed, the reload animation will override the running animation, causing the player to slide across the floor. 

## **CRITICAL ANIMATION CASES & ARCHITECTURE** 

## **1. Character vs. NPC Authority** 

**Player:** Run locally. Replicates automatically. 

**NPC:** Run on the server to ensure all clients see it equally. 

## **2. Camera Cutscenes (Tweening & Network Safety)** 

When overriding the camera for a cutscene, transition the `CameraType` to 

`Scriptable` . 

**Latency Trap:** If triggering this from the server via `RemoteEvent` , always implement a timeout when forcing the camera to a static `CFrame` part. Packet drops can cause the camera to permanently hang in the void. However, apply **no timeout** when 

reverting the `CameraSubject` back to the `Humanoid` 

Lua 

```
-- Enter Cutscene
camera.CameraType = Enum.CameraType.Scriptable
TweenService:Create(camera, TweenInfo.new(duration,
Enum.EasingStyle.Quad),{CFrame = targetCFrame}):Play()
```

```
-- Exit Cutscene(Immediate reset to prevent getting stuck)
camera.CameraType = Enum.CameraType.Custom
if humanoid then camera.CameraSubject = humanoid end
```

## **3. Tools & Weapons (State Machines)** 

Handling weapon states (Idle, Reload, Shoot) requires dynamic weld manipulation and input listening. 

- **Dynamic Grip:** You May need to adjust the default `RightGrip.C1` (using `CFrame.Angles` ) on equip to fix holding orientations. 

- **Event Syncing:** Use `GetMarkerReachedSignal` within the track to play the exact mechanical sounds (e.g., magazine ejection) at the right frame. 

Lua 

```
-- Optimized Tool Logic Skeleton
tool.Equipped:Connect(function()
    local defaultWeld =
character:FindFirstChild("RightHand"):FindFirstChild("RightGrip")
--
// this depends whether or not we need to adject its depends
on model and animation
if defaultWeld then defaultWeld.C1*= CFrame.Angles(0,
math.rad(90),0) end
    idleTrack:Play()
end)
tool.Unequipped:Connect(function()
    idleTrack:Stop()
end)
UserInputService.InputBegan:Connect(function(input, processed)
if processed or not character:FindFirstChild("gun") then return
end
```

## **4. Multi-Character Scenes (Grapples & Takedowns)** 

When 2-3 characters (e.g., attacker and victim) interact physically, playing separate animations rarely syncs up perfectly due to replication delay. 

- **The Pro Approach:** Dynamically instance a `Motor6D` via script mid-fight, linking the attacker and victim together ( `Part0` and `Part1` ). Apply precise `CFrame` offsets. Because they are mechanically linked, a single 

- synchronized animation track will govern both models flawlessly. 

## **5. Procedural Animation & IK Control (Advanced)** 

Beyond static tracks, `IKControl` instances allow for procedural adjustments (e.g., forcing a character's head to look at a part, or feet to align with uneven terrain dynamically) using real-time math. 

## **Common Mistakes Quick-Check** 

**Playing local animations from a Server Script:** Will not replicate back to the local client smoothly. 

## **Loading Animation Track on Humanoid:** Deprecated. Always 

load on the `Animator` . 

- **Weird Blending/Sliding:** Tracks are fighting. Assign different 

- `Enum.AnimationPriority` values or ensure irrelevant joints are 

- unkeyed. 

- **Marker Events Not Firing:** Animation wasn't re-published after adding markers in the editor, or the string name is misspelled. **AnimationController Fails:** You forgot to instance an `Animator` inside the `AnimationController` before calling load. 
---
## 8. **Optimization and Performance QUICK REFERENCE** 

|**Technique**|**Impact**|**When to Use**|
|---|---|---|
|Streaming Enabled|High|Large open worlds|
|Object pooling|High|Frequent spawn/destroy|
|Cache references outside loops|High|Heartbeat/Render Stepped|
|Anchor static parts when needed<br>or necessary|Medium|Reduce physics budget|
|Limit Point Lights when needed<br>or necessary|High|Any scene with many lights|



## **Common Mistake and Tips** 

**Object Pooling:** Before Reusing items make sure reset the stats and disconnect all the Threads or Events (ex Runservice connect to gui of object) and use Object Pooling when Frequent spawn/destroy object needed 

- `workspace:FindFirstChild` every frame in RunService when not needed 

- Particle Emitters enabled off-screen 
---
## 9. **Testing And Debugging** 

if u can test using MCP SERVER THEN DO it Find bugs , error , Memory Leak etc 

