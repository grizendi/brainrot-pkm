--[[
    init.server.luau
    Server entry point — bootstraps all server systems in dependency order.
]]

print("[Server] Initializing BrainrotBattler server...")

-- 1. Remotes — must be first so other modules can reference them
local Remotes = require(script:WaitForChild("Remotes"))
Remotes.init()

-- 2. Player Data Manager — handles player join/leave, needs Remotes
local PlayerDataManager = require(script:WaitForChild("PlayerDataManager"))
PlayerDataManager.init()

-- 3. Battle Engine — wires up action/switch remotes
local BattleEngine = require(script:WaitForChild("BattleEngine"))
BattleEngine.init()

-- 4. Wild Spawn System — builds the map (must be before EncounterSystem)
local WildSpawnSystem = require(script:WaitForChild("WildSpawnSystem"))
local mapRefs = WildSpawnSystem.init()

-- 5. Encounter System — wires up trigger zones + healer
local EncounterSystem = require(script:WaitForChild("EncounterSystem"))
EncounterSystem.init(mapRefs)

print("[Server] All systems initialized!")
