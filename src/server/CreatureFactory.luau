--[[
    CreatureFactory.luau  (Server module)
    Generates CreatureInstance tables from species definitions.

    Stat formulas (from BattleConstants):
        General stat = floor((baseStat * 2 * level) / 100) + 5
        HP stat      = floor((baseHP * 2 * level) / 100) + level + 10
        Max MP       = floor((baseMp * level) / 50) + baseMp
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CreatureDatabase = require(Shared:WaitForChild("CreatureDatabase"))
local BattleConstants = require(Shared:WaitForChild("BattleConstants"))

local CreatureFactory = {}

------------------------------------------------------------------------
-- Internal: calculate a single stat at a given level
------------------------------------------------------------------------

local function calcStat(baseStat: number, level: number): number
    return math.floor((baseStat * 2 * level) / 100) + 5
end

local function calcHp(baseHp: number, level: number): number
    return math.floor((baseHp * 2 * level) / 100) + level + 10
end

local function calcMaxMp(baseMp: number, level: number): number
    return math.floor((baseMp * level) / 50) + baseMp
end

------------------------------------------------------------------------
-- Internal: calculate all stats for a species at a given level
------------------------------------------------------------------------

local function calculateStats(species: any, level: number): any
    return {
        hp = calcHp(species.baseStats.hp, level),
        attack = calcStat(species.baseStats.attack, level),
        defense = calcStat(species.baseStats.defense, level),
        spAttack = calcStat(species.baseStats.spAttack, level),
        spDefense = calcStat(species.baseStats.spDefense, level),
        speed = calcStat(species.baseStats.speed, level),
    }
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

--[[
    Create a creature instance at a specific level.
    Used for wild creatures, starters, or any creature generation.

    @param speciesId string — key into CreatureDatabase
    @param level number — creature level (1–100)
    @return CreatureInstance table, or nil if speciesId is invalid
]]
function CreatureFactory.createCreature(speciesId: string, level: number): any
    local species = CreatureDatabase.getSpecies(speciesId)
    if not species then
        warn("[CreatureFactory] Unknown speciesId: " .. tostring(speciesId))
        return nil
    end

    -- Clamp level
    level = math.clamp(level, 1, BattleConstants.MAX_LEVEL)

    -- Calculate stats
    local stats = calculateStats(species, level)
    local maxMp = calcMaxMp(species.baseMp, level)

    -- Determine moves known at this level
    local moves = CreatureDatabase.getMovesAtLevel(speciesId, level)

    -- Calculate XP already accumulated (as if they just reached this level)
    -- level 1 starts at 0 XP; for other levels, XP = sum of all thresholds
    local experience = 0

    local creature = {
        uid = HttpService:GenerateGUID(false),
        speciesId = speciesId,
        nickname = nil,
        level = level,
        experience = experience,

        stats = stats,
        currentHp = stats.hp,
        maxHp = stats.hp,
        currentMp = maxMp,
        maxMp = maxMp,

        element = species.element,
        moves = moves,
        heldItem = nil,
    }

    return creature
end

--[[
    Create a starter creature at the default starter level.

    @param speciesId string — key into CreatureDatabase
    @return CreatureInstance
]]
function CreatureFactory.createStarterCreature(speciesId: string): any
    return CreatureFactory.createCreature(speciesId, BattleConstants.STARTER_LEVEL)
end

--[[
    Recalculate stats for an existing creature (e.g. after level-up).
    Preserves currentHp/currentMp proportionally.

    @param creature CreatureInstance — modified in place
]]
function CreatureFactory.recalculateStats(creature: any)
    local species = CreatureDatabase.getSpecies(creature.speciesId)
    if not species then
        return
    end

    -- Store HP/MP proportions
    local hpRatio = creature.maxHp > 0 and (creature.currentHp / creature.maxHp) or 1
    local mpRatio = creature.maxMp > 0 and (creature.currentMp / creature.maxMp) or 1

    -- Recalculate
    local newStats = calculateStats(species, creature.level)
    local newMaxMp = calcMaxMp(species.baseMp, creature.level)

    creature.stats = newStats
    creature.maxHp = newStats.hp
    creature.maxMp = newMaxMp

    -- Scale current HP/MP proportionally to new maximums
    creature.currentHp = math.clamp(math.floor(newStats.hp * hpRatio), 1, newStats.hp)
    creature.currentMp = math.clamp(math.floor(newMaxMp * mpRatio), 0, newMaxMp)
end

--[[
    Get a random species ID (for random starter assignment).

    @return string — a valid speciesId
]]
function CreatureFactory.getRandomSpeciesId(): string
    local allIds = CreatureDatabase.getAllSpeciesIds()
    return allIds[math.random(1, #allIds)]
end

------------------------------------------------------------------------
-- Stat calculation accessors (exposed for LevelingSystem)
------------------------------------------------------------------------

CreatureFactory.calcStat = calcStat
CreatureFactory.calcHp = calcHp
CreatureFactory.calcMaxMp = calcMaxMp

return CreatureFactory
