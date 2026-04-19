--[[
    EncounterSystem.luau  (Server module)
    Manages wild encounter triggering when players walk through tall grass.

    Flow:
        1. On init, finds all parts tagged "EncounterZone" via CollectionService
        2. Connects .Touched / .TouchEnded on each trigger volume
        3. When player enters a zone, starts a random timer (3–8 seconds)
        4. If timer fires and player is still in the zone:
            - Roll a creature from the zone's spawn table
            - Create it via CreatureFactory
            - Start a battle via BattleEngine
        5. After battle, enforce a cooldown before new encounters
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BattleConstants = require(Shared:WaitForChild("BattleConstants"))
local SpawnTables = require(Shared:WaitForChild("SpawnTables"))

-- Lazy-loaded
local CreatureFactory = nil
local BattleEngine = nil
local PlayerDataManager = nil
local Remotes = nil
local WildSpawnSystem = nil

local EncounterSystem = {}

------------------------------------------------------------------------
-- Per-player tracking state
------------------------------------------------------------------------

type PlayerEncounterState = {
    inZone: boolean,
    zoneId: string?,
    timerThread: thread?,
    cooldownUntil: number,
}

local playerStates: { [number]: PlayerEncounterState } = {}

------------------------------------------------------------------------
-- Lazy dependency loading
------------------------------------------------------------------------

local function ensureDependencies()
    if not CreatureFactory then
        CreatureFactory = require(script.Parent:WaitForChild("CreatureFactory"))
    end
    if not BattleEngine then
        BattleEngine = require(script.Parent:WaitForChild("BattleEngine"))
    end
    if not PlayerDataManager then
        PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    end
    if not Remotes then
        Remotes = require(script.Parent:WaitForChild("Remotes"))
    end
    if not WildSpawnSystem then
        WildSpawnSystem = require(script.Parent:WaitForChild("WildSpawnSystem"))
    end
end

------------------------------------------------------------------------
-- Internal: get or create player state
------------------------------------------------------------------------

local function getState(player: Player): PlayerEncounterState
    local userId = player.UserId
    if not playerStates[userId] then
        playerStates[userId] = {
            inZone = false,
            zoneId = nil,
            timerThread = nil,
            cooldownUntil = 0,
        }
    end
    return playerStates[userId]
end

------------------------------------------------------------------------
-- Internal: cancel any pending encounter timer
------------------------------------------------------------------------

local function cancelTimer(state: PlayerEncounterState)
    if state.timerThread then
        task.cancel(state.timerThread)
        state.timerThread = nil
    end
end

------------------------------------------------------------------------
-- Internal: get player from a touched part
------------------------------------------------------------------------

local function getPlayerFromHit(hit: BasePart): Player?
    if not hit or not hit.Parent then
        return nil
    end
    -- Check if it's a character's HumanoidRootPart or any body part
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    return Players:GetPlayerFromCharacter(character)
end

------------------------------------------------------------------------
-- Internal: trigger an encounter
------------------------------------------------------------------------

local function triggerEncounter(player: Player, zoneId: string)
    ensureDependencies()

    local state = getState(player)

    -- Double-check: still in zone, not in battle, not on cooldown
    if not state.inZone then
        return
    end
    if BattleEngine.isInBattle(player) then
        return
    end
    if tick() < state.cooldownUntil then
        return
    end
    if not PlayerDataManager.hasData(player) then
        return
    end
    if not PlayerDataManager.hasAliveCreatures(player) then
        return
    end

    -- Roll a wild creature
    local encounter = SpawnTables.rollEncounter(zoneId)
    if not encounter then
        warn("[EncounterSystem] Failed to roll encounter for zone: " .. zoneId)
        return
    end

    -- Create the wild creature
    local wildCreature = CreatureFactory.createCreature(encounter.speciesId, encounter.level)
    if not wildCreature then
        return
    end

    -- Get the player's first alive creature for the battle
    local party = PlayerDataManager.getParty(player)
    local battleParty = {}
    local firstAliveIndex = PlayerDataManager.getFirstAliveIndex(player)
    if not firstAliveIndex then
        return
    end

    -- For 1v1 prototype: send the full party but set activeIndex to first alive
    for _, creature in party do
        table.insert(battleParty, creature)
    end

    -- Notify client that encounter is starting
    Remotes.EncounterTriggered:FireClient(player, {
        speciesId = wildCreature.speciesId,
        level = wildCreature.level,
        element = wildCreature.element,
    })

    -- Small delay for transition animation
    task.wait(1.0)

    -- Start the battle (1v1: player party vs single wild creature)
    BattleEngine.startBattle(player, battleParty, { wildCreature }, true)

    -- Set cooldown after battle ends
    state.cooldownUntil = tick() + BattleConstants.ENCOUNTER_COOLDOWN
    cancelTimer(state)

    print("[EncounterSystem] " .. player.Name .. " encountered wild "
        .. wildCreature.speciesId .. " Lv." .. wildCreature.level
        .. " in zone " .. zoneId)
end

------------------------------------------------------------------------
-- Internal: start encounter timer for a player in a zone
------------------------------------------------------------------------

local function startEncounterTimer(player: Player, zoneId: string)
    local state = getState(player)

    -- Cancel any existing timer
    cancelTimer(state)

    -- Random delay
    local delay = BattleConstants.ENCOUNTER_DELAY_MIN
        + math.random() * (BattleConstants.ENCOUNTER_DELAY_MAX - BattleConstants.ENCOUNTER_DELAY_MIN)

    state.timerThread = task.delay(delay, function()
        state.timerThread = nil
        if state.inZone and state.zoneId == zoneId then
            triggerEncounter(player, zoneId)

            -- If still in zone after battle, start a new timer
            task.wait(BattleConstants.ENCOUNTER_COOLDOWN)
            if state.inZone and state.zoneId == zoneId and not BattleEngine.isInBattle(player) then
                startEncounterTimer(player, zoneId)
            end
        end
    end)
end

------------------------------------------------------------------------
-- Internal: wire up a single trigger zone
------------------------------------------------------------------------

local function wireTrigger(trigger: BasePart)
    local zoneId = trigger:GetAttribute("zoneId")
    if not zoneId then
        warn("[EncounterSystem] Trigger missing zoneId attribute: " .. trigger:GetFullName())
        return
    end

    -- Track which players are inside (debounce Touched)
    local playersInside: { [number]: boolean } = {}

    trigger.Touched:Connect(function(hit: BasePart)
        local player = getPlayerFromHit(hit)
        if not player then
            return
        end

        local userId = player.UserId
        if playersInside[userId] then
            return  -- already tracked
        end
        playersInside[userId] = true

        ensureDependencies()
        local state = getState(player)

        -- Skip if in battle or on cooldown
        if BattleEngine.isInBattle(player) then
            return
        end

        state.inZone = true
        state.zoneId = zoneId

        -- Notify client (zone indicator)
        Remotes.EncounterZoneChanged:FireClient(player, {
            inZone = true,
            zoneId = zoneId,
        })

        -- Start encounter timer (only if not on cooldown)
        if tick() >= state.cooldownUntil then
            startEncounterTimer(player, zoneId)
        end
    end)

    trigger.TouchEnded:Connect(function(hit: BasePart)
        local player = getPlayerFromHit(hit)
        if not player then
            return
        end

        local userId = player.UserId
        if not playersInside[userId] then
            return
        end
        playersInside[userId] = nil

        local state = getState(player)
        state.inZone = false
        state.zoneId = nil
        cancelTimer(state)

        -- Notify client
        ensureDependencies()
        Remotes.EncounterZoneChanged:FireClient(player, {
            inZone = false,
            zoneId = nil,
        })
    end)
end

------------------------------------------------------------------------
-- Internal: wire up healer NPC
------------------------------------------------------------------------

local function wireHealer(healer: BasePart)
    if not healer then
        return
    end

    local healCooldowns: { [number]: number } = {}

    healer.Touched:Connect(function(hit: BasePart)
        local player = getPlayerFromHit(hit)
        if not player then
            return
        end

        -- Cooldown to prevent spam
        local now = tick()
        if healCooldowns[player.UserId] and now - healCooldowns[player.UserId] < 3 then
            return
        end
        healCooldowns[player.UserId] = now

        ensureDependencies()
        if BattleEngine.isInBattle(player) then
            return
        end

        PlayerDataManager.healParty(player)
    end)
end

------------------------------------------------------------------------
-- Public: initialize the encounter system
------------------------------------------------------------------------

function EncounterSystem.init(mapRefs: any?)
    ensureDependencies()

    -- Wire up all encounter zone triggers
    local triggers = CollectionService:GetTagged(WildSpawnSystem.getEncounterZoneTag())
    for _, trigger in triggers do
        if trigger:IsA("BasePart") then
            wireTrigger(trigger)
        end
    end

    -- Also listen for any new tagged triggers (future-proof)
    CollectionService:GetInstanceAddedSignal(WildSpawnSystem.getEncounterZoneTag()):Connect(function(instance)
        if instance:IsA("BasePart") then
            wireTrigger(instance)
        end
    end)

    -- Wire up healer
    if mapRefs and mapRefs.healer then
        wireHealer(mapRefs.healer)
    end

    -- Clean up on player leaving
    Players.PlayerRemoving:Connect(function(player: Player)
        local state = playerStates[player.UserId]
        if state then
            cancelTimer(state)
            playerStates[player.UserId] = nil
        end
    end)

    print("[EncounterSystem] Initialized with " .. #triggers .. " encounter zones")
end

return EncounterSystem
