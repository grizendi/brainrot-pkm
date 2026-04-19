--[[
    Remotes.luau  (Server module)
    Creates and exposes all RemoteEvents and RemoteFunctions used for
    client⇄server communication.

    Usage (server):
        local Remotes = require(path.to.Remotes)
        Remotes.BattleStart:FireClient(player, data)

    Usage (client):
        local Remotes = ReplicatedStorage:WaitForChild("Remotes")
        Remotes.BattleStart.OnClientEvent:Connect(function(data) ... end)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

------------------------------------------------------------------------
-- Remote definitions
------------------------------------------------------------------------

-- All RemoteEvents to create
local REMOTE_EVENTS = {
    -- Battle flow
    "BattleStart",           -- Server → Client: battle begins (sends both sides' data)
    "BattleRequestAction",   -- Server → Client: prompt player to choose an action
    "BattleSubmitAction",    -- Client → Server: player sends chosen action
    "BattleTurnResult",      -- Server → Client: results of the turn (damage, effects, etc.)
    "BattleCreatureFainted", -- Server → Client: a creature fainted, may need switch
    "BattleSwitchCreature",  -- Client → Server: player picks replacement creature
    "BattleEnd",             -- Server → Client: battle is over (result, XP, etc.)

    -- Encounter / overworld
    "EncounterTriggered",    -- Server → Client: wild encounter starting (creature info)
    "EncounterZoneChanged",  -- Server → Client: player entered/exited encounter zone

    -- Leveling
    "CreatureLevelUp",       -- Server → Client: creature leveled up (stats, new moves)

    -- Healing
    "PartyHealed",           -- Server → Client: party was fully healed
}

-- All RemoteFunctions to create
local REMOTE_FUNCTIONS = {
    "GetPlayerData",         -- Client → Server: request full player data
    "GetPartyInfo",          -- Client → Server: request party summary
}

------------------------------------------------------------------------
-- Initialization: create all remotes under ReplicatedStorage/Remotes
------------------------------------------------------------------------

function Remotes.init()
    -- Create or find the Remotes folder
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    -- Create RemoteEvents
    for _, name in REMOTE_EVENTS do
        if not remotesFolder:FindFirstChild(name) then
            local remote = Instance.new("RemoteEvent")
            remote.Name = name
            remote.Parent = remotesFolder
        end
    end

    -- Create RemoteFunctions
    for _, name in REMOTE_FUNCTIONS do
        if not remotesFolder:FindFirstChild(name) then
            local remote = Instance.new("RemoteFunction")
            remote.Name = name
            remote.Parent = remotesFolder
        end
    end

    -- Cache references on this module for easy server-side access
    for _, name in REMOTE_EVENTS do
        Remotes[name] = remotesFolder:FindFirstChild(name)
    end
    for _, name in REMOTE_FUNCTIONS do
        Remotes[name] = remotesFolder:FindFirstChild(name)
    end

    print("[Remotes] Initialized " .. #REMOTE_EVENTS .. " events + " .. #REMOTE_FUNCTIONS .. " functions")
    return Remotes
end

------------------------------------------------------------------------
-- Client helper: wait for remotes folder and return references
-- (Not used by server — provided for convenience if needed)
------------------------------------------------------------------------

function Remotes.waitForRemotes()
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotesFolder then
        warn("[Remotes] Timed out waiting for Remotes folder")
        return nil
    end

    local refs = {}
    for _, child in remotesFolder:GetChildren() do
        refs[child.Name] = child
    end
    return refs
end

return Remotes
