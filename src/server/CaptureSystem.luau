--[[
    CaptureSystem.luau  (Server module)
    Handles capture attempts when a player uses a Capture Orb.

    Formula:
        hpFactor     = 1 - (currentHp / maxHp)         -- 0.0 at full, ~1.0 at 1 HP
        levelPenalty = clamp(wildLevel / avgPlayerLevel, 0.5, 2.0)
        captureChance = baseRate * (0.3 + 0.7 * hpFactor) / levelPenalty

    At full HP:   chance ≈ 15–30%
    At 1 HP:      chance ≈ 50–100%
    Higher-level wild creatures are harder to catch.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BattleConstants = require(Shared:WaitForChild("BattleConstants"))

-- Lazy-loaded to avoid circular dependency
local PlayerDataManager = nil

local CaptureSystem = {}

------------------------------------------------------------------------
-- Lazy dependency loading
------------------------------------------------------------------------

local function ensureDependencies()
    if not PlayerDataManager then
        PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    end
end

------------------------------------------------------------------------
-- Core: attempt to capture the wild creature
------------------------------------------------------------------------

--[[
    Attempt to capture the opponent's active creature.

    @param player Player — the player attempting capture
    @param battle BattleState — current battle state
    @return { success: boolean, chance: number }
]]
function CaptureSystem.attemptCapture(player: Player, battle: any): { success: boolean, chance: number }
    ensureDependencies()

    -- Can only capture in wild battles
    if not battle.isWild then
        return { success = false, chance = 0 }
    end

    local wildSide = battle.sides[2]
    local wildCreature = wildSide.creatures[wildSide.activeIndex]
    local playerSide = battle.sides[1]
    local playerCreature = playerSide.creatures[playerSide.activeIndex]

    -- Calculate HP factor (lower HP = easier capture)
    local hpFactor = 1 - (wildCreature.currentHp / math.max(wildCreature.maxHp, 1))

    -- Calculate level penalty (higher wild level = harder)
    local levelRatio = wildCreature.level / math.max(playerCreature.level, 1)
    local levelPenalty = math.clamp(
        levelRatio,
        BattleConstants.CAPTURE_LEVEL_PENALTY_MIN,
        BattleConstants.CAPTURE_LEVEL_PENALTY_MAX
    )

    -- Final capture chance
    local captureChance = BattleConstants.CAPTURE_BASE_RATE * (0.3 + 0.7 * hpFactor) / levelPenalty

    -- Clamp to 0–1 range
    captureChance = math.clamp(captureChance, 0.05, 1.0)

    -- Roll
    local roll = math.random()
    local success = roll < captureChance

    if success then
        -- Add the wild creature to the player's party (or storage)
        local placement = PlayerDataManager.addCreature(player, wildCreature)
        print("[CaptureSystem] " .. player.Name .. " captured " .. wildCreature.speciesId
            .. " (Lv." .. wildCreature.level .. ") → " .. placement
            .. " | chance=" .. string.format("%.1f%%", captureChance * 100))
    else
        print("[CaptureSystem] " .. player.Name .. " failed to capture " .. wildCreature.speciesId
            .. " | chance=" .. string.format("%.1f%%", captureChance * 100)
            .. " roll=" .. string.format("%.3f", roll))
    end

    return {
        success = success,
        chance = math.floor(captureChance * 100 + 0.5),  -- percentage for display
    }
end

return CaptureSystem
