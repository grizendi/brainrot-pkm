--[[
    init.client.luau
    Client entry point — bootstraps all client systems.
]]

print("[Client] Initializing BrainrotBattler client...")

-- 1. Battle Controller — wires battle UI to server remotes
-- (Requires itself on load — connects all events immediately)
local BattleController = require(script:WaitForChild("BattleController"))

-- 2. Overworld Controller — mini party HUD, zone indicator, notifications
local OverworldController = require(script:WaitForChild("OverworldController"))
OverworldController.init()

print("[Client] All systems initialized!")
