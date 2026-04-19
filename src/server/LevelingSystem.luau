--[[
    LevelingSystem.luau  (Server module)
    Handles XP gain and level-up processing after battles.

    XP gain:     xpGained = floor(BASE_XP * defeatedLevel / creatureLevel)
    Level-up at: requiredXP = level^2 * XP_SCALE_FACTOR
    Supports multi-level-up in a single call.

    On level-up:
        - Stats recalculated (HP/MP scale proportionally)
        - Check for new moves at the new level(s)
        - If creature already knows 4 moves, replace the oldest
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BattleConstants = require(Shared:WaitForChild("BattleConstants"))
local CreatureDatabase = require(Shared:WaitForChild("CreatureDatabase"))
local CreatureFactory = require(script.Parent:WaitForChild("CreatureFactory"))

local LevelingSystem = {}

------------------------------------------------------------------------
-- Internal: XP required to go from `level` to `level + 1`
------------------------------------------------------------------------

local function xpForLevel(level: number): number
    return level * level * BattleConstants.XP_SCALE_FACTOR
end

------------------------------------------------------------------------
-- Internal: total cumulative XP needed to reach a given level
------------------------------------------------------------------------

local function totalXpForLevel(level: number): number
    -- Sum of xpForLevel(1) + xpForLevel(2) + ... + xpForLevel(level - 1)
    -- We only need the threshold for the CURRENT level
    -- Creature stores XP toward the next level, not cumulative
    return xpForLevel(level)
end

------------------------------------------------------------------------
-- Core: award XP and process level-ups
------------------------------------------------------------------------

--[[
    Award XP to a creature after defeating an opponent.
    Modifies the creature in place.

    @param creature CreatureInstance — the creature gaining XP (modified in place)
    @param defeatedLevel number — level of the defeated creature
    @return {
        xpGained: number,
        levelsGained: number,
        newLevel: number,
        newMoves: { string },   -- moveIds learned during level-ups
    }
]]
function LevelingSystem.awardXP(creature: any, defeatedLevel: number): any
    -- Don't gain XP at max level
    if creature.level >= BattleConstants.MAX_LEVEL then
        return {
            xpGained = 0,
            levelsGained = 0,
            newLevel = creature.level,
            newMoves = {},
        }
    end

    -- Calculate XP gained
    local xpGained = math.floor(BattleConstants.BASE_XP_REWARD * defeatedLevel / math.max(creature.level, 1))
    xpGained = math.max(xpGained, 1)  -- always gain at least 1 XP

    creature.experience = creature.experience + xpGained

    -- Check for level-ups (possibly multiple)
    local startLevel = creature.level
    local newMoves: { string } = {}

    while creature.level < BattleConstants.MAX_LEVEL do
        local required = xpForLevel(creature.level)
        if creature.experience >= required then
            creature.experience = creature.experience - required
            creature.level = creature.level + 1

            -- Check for new moves at this level
            local learnedAtLevel = LevelingSystem._getMovesLearnedAtLevel(creature.speciesId, creature.level)
            for _, moveId in learnedAtLevel do
                LevelingSystem._teachMove(creature, moveId)
                table.insert(newMoves, moveId)
            end
        else
            break
        end
    end

    local levelsGained = creature.level - startLevel

    -- Recalculate stats if leveled up
    if levelsGained > 0 then
        CreatureFactory.recalculateStats(creature)
        print("[LevelingSystem] " .. creature.speciesId .. " leveled up! "
            .. startLevel .. " → " .. creature.level
            .. " (+" .. xpGained .. " XP, " .. levelsGained .. " levels)")
    end

    return {
        xpGained = xpGained,
        levelsGained = levelsGained,
        newLevel = creature.level,
        newMoves = newMoves,
    }
end

------------------------------------------------------------------------
-- Internal: get moves learned at a specific level
------------------------------------------------------------------------

function LevelingSystem._getMovesLearnedAtLevel(speciesId: string, level: number): { string }
    local species = CreatureDatabase.getSpecies(speciesId)
    if not species then
        return {}
    end

    local moves = {}
    for _, entry in species.learnableMoves do
        if entry.level == level then
            table.insert(moves, entry.moveId)
        end
    end
    return moves
end

------------------------------------------------------------------------
-- Internal: teach a move to a creature
------------------------------------------------------------------------

function LevelingSystem._teachMove(creature: any, moveId: string)
    -- Check if creature already knows this move
    for _, existingId in creature.moves do
        if existingId == moveId then
            return  -- already known
        end
    end

    if #creature.moves < BattleConstants.MAX_MOVES then
        -- Has room — just add it
        table.insert(creature.moves, moveId)
    else
        -- Replace the oldest move (index 1)
        table.remove(creature.moves, 1)
        table.insert(creature.moves, moveId)
    end

    print("[LevelingSystem] " .. creature.speciesId .. " learned " .. moveId .. "!")
end

------------------------------------------------------------------------
-- Utility: get XP progress info for display
------------------------------------------------------------------------

--[[
    Get XP progress information for a creature.

    @param creature CreatureInstance
    @return { currentXP: number, requiredXP: number, percentage: number }
]]
function LevelingSystem.getXPProgress(creature: any): any
    if creature.level >= BattleConstants.MAX_LEVEL then
        return {
            currentXP = 0,
            requiredXP = 0,
            percentage = 100,
        }
    end

    local required = xpForLevel(creature.level)
    local percentage = math.floor((creature.experience / math.max(required, 1)) * 100)

    return {
        currentXP = creature.experience,
        requiredXP = required,
        percentage = math.clamp(percentage, 0, 100),
    }
end

return LevelingSystem
