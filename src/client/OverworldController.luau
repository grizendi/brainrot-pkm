--[[
    OverworldController.luau  (Client module)
    Manages non-battle client state:
        - Fetches and displays party info in OverworldHUD
        - Responds to zone enter/exit events
        - Handles party healed notification
        - Hides overworld HUD during battles
        - Refreshes party after battle ends
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for remotes
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not RemotesFolder then
    warn("[OverworldController] Remotes folder not found!")
    return
end

local EncounterZoneChanged = RemotesFolder:WaitForChild("EncounterZoneChanged")
local PartyHealed = RemotesFolder:WaitForChild("PartyHealed")
local BattleStart = RemotesFolder:WaitForChild("BattleStart")
local BattleEnd = RemotesFolder:WaitForChild("BattleEnd")
local CreatureLevelUp = RemotesFolder:WaitForChild("CreatureLevelUp")
local GetPlayerData = RemotesFolder:WaitForChild("GetPlayerData")

-- UI
local uiFolder = script.Parent:WaitForChild("ui")
local OverworldHUD = require(uiFolder:WaitForChild("OverworldHUD"))

local OverworldController = {}

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

local hud = nil

------------------------------------------------------------------------
-- Internal: refresh party display from server
------------------------------------------------------------------------

local function refreshParty()
    if not hud then return end

    local data = GetPlayerData:InvokeServer()
    if data and data.party then
        hud:updateParty(data.party)
    end
end

------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

function OverworldController.init()
    -- Create the HUD
    hud = OverworldHUD.new()

    -- Initial party load (small delay to let server initialize)
    task.delay(1.0, function()
        refreshParty()
    end)

    -- Zone enter/exit
    EncounterZoneChanged.OnClientEvent:Connect(function(data)
        if data.inZone then
            hud:showZoneIndicator(data.zoneId)
        else
            hud:hideZoneIndicator()
        end
    end)

    -- Party healed
    PartyHealed.OnClientEvent:Connect(function()
        hud:showNotification("🏥 Your party has been fully healed!", 2.5)
        refreshParty()
    end)

    -- Hide HUD during battle
    BattleStart.OnClientEvent:Connect(function()
        hud:hide()
        hud:hideZoneIndicator()
    end)

    -- Show HUD + refresh party after battle
    BattleEnd.OnClientEvent:Connect(function()
        task.delay(3.5, function()  -- wait for battle end screen to clear
            hud:show()
            refreshParty()
        end)
    end)

    -- Level up — refresh party to show new level
    CreatureLevelUp.OnClientEvent:Connect(function(data)
        hud:showNotification(
            "⬆ Level Up! Now Lv." .. tostring(data.newLevel) .. "!",
            3.0
        )
        refreshParty()
    end)

    print("[OverworldController] Initialized")
end

------------------------------------------------------------------------
-- Public
------------------------------------------------------------------------

function OverworldController.getHUD()
    return hud
end

return OverworldController
