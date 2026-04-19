--[[
    DamageCalculator.luau
    Shared damage formula used by the server (authoritative) and
    optionally by the client for damage previews.

    Damage formula (Pokémon-style):
        baseDamage = ((2 * level / 5 + 2) * power * A / D) / 50 + 2
        finalDamage = baseDamage * typeEffectiveness * STAB * randomRoll

    Where:
        A/D = Attack/Defense  for Physical moves
        A/D = SpAttack/SpDefense  for Special moves
    
    Stat stages are applied as multipliers to the raw stat before the
    formula runs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BattleConstants = require(Shared:WaitForChild("BattleConstants"))
local ElementTypes = require(Shared:WaitForChild("ElementTypes"))

local DamageCalculator = {}

------------------------------------------------------------------------
-- Internal: apply stat stage multiplier
------------------------------------------------------------------------

local function applyStatStage(baseStat: number, stage: number): number
    local clampedStage = math.clamp(stage, BattleConstants.MIN_STAT_STAGE, BattleConstants.MAX_STAT_STAGE)
    local index = clampedStage - BattleConstants.MIN_STAT_STAGE + 1  -- map -4..+4 → 1..9
    local multiplier = BattleConstants.STAT_STAGE_MULTIPLIERS[index]
    return math.floor(baseStat * multiplier)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

export type DamageResult = {
    damage: number,
    effectiveness: number,    -- 0.5, 1.0, or 2.0
    isSTAB: boolean,
    rawDamage: number,        -- before random variance
    attackStat: number,       -- effective A used
    defenseStat: number,      -- effective D used
}

--[[
    Calculate damage for a move.

    @param attacker   CreatureInstance — the creature using the move
    @param defender   CreatureInstance — the creature being hit
    @param move       Move — the move being used
    @param options    optional table:
        attackerStages: StatStages  (default all 0)
        defenderStages: StatStages  (default all 0)
        isDefending: boolean        (default false) — did defender use Defend?
    @return DamageResult
]]
function DamageCalculator.calculateDamage(
    attacker: any,
    defender: any,
    move: any,
    options: any?
): DamageResult
    local opts = options or {}
    local attackerStages = opts.attackerStages or {}
    local defenderStages = opts.defenderStages or {}
    local isDefending = opts.isDefending or false

    -- Status moves deal no damage
    if move.category == "Status" then
        return {
            damage = 0,
            effectiveness = 1.0,
            isSTAB = false,
            rawDamage = 0,
            attackStat = 0,
            defenseStat = 0,
        }
    end

    -- Determine which stats to use
    local attackStat: number
    local defenseStat: number

    if move.category == "Physical" then
        local atkStage = attackerStages.attack or 0
        local defStage = defenderStages.defense or 0
        attackStat = applyStatStage(attacker.stats.attack, atkStage)
        defenseStat = applyStatStage(defender.stats.defense, defStage)
    else -- "Special"
        local spAtkStage = attackerStages.spAttack or 0
        local spDefStage = defenderStages.spDefense or 0
        attackStat = applyStatStage(attacker.stats.spAttack, spAtkStage)
        defenseStat = applyStatStage(defender.stats.spDefense, spDefStage)
    end

    -- Prevent division by zero
    attackStat = math.max(attackStat, 1)
    defenseStat = math.max(defenseStat, 1)

    -- Base damage formula
    local level = attacker.level
    local power = move.power
    local baseDamage = ((2 * level / 5 + 2) * power * attackStat / defenseStat) / 50 + 2

    -- Type effectiveness
    local effectiveness = ElementTypes.getEffectiveness(move.element, defender.element)
    baseDamage = baseDamage * effectiveness

    -- STAB (Same-Type Attack Bonus)
    local isSTAB = (move.element == attacker.element)
    if isSTAB then
        baseDamage = baseDamage * BattleConstants.STAB_MULTIPLIER
    end

    -- Store raw damage before random variance
    local rawDamage = math.floor(baseDamage)

    -- Random variance (0.85 – 1.0)
    local roll = BattleConstants.DAMAGE_RANDOM_MIN
        + math.random() * (BattleConstants.DAMAGE_RANDOM_MAX - BattleConstants.DAMAGE_RANDOM_MIN)
    local finalDamage = math.floor(baseDamage * roll)

    -- Defend halves damage
    if isDefending then
        finalDamage = math.floor(finalDamage * BattleConstants.DEFEND_REDUCTION)
    end

    -- Ensure at least 1 damage for any damaging move
    finalDamage = math.max(finalDamage, 1)

    return {
        damage = finalDamage,
        effectiveness = effectiveness,
        isSTAB = isSTAB,
        rawDamage = rawDamage,
        attackStat = attackStat,
        defenseStat = defenseStat,
    }
end

------------------------------------------------------------------------
-- Utility: check if a move will hit (accuracy roll)
------------------------------------------------------------------------

function DamageCalculator.rollAccuracy(move: any): boolean
    if move.accuracy >= 100 then
        return true
    end
    return math.random(1, 100) <= move.accuracy
end

return DamageCalculator
