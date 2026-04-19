--[[
    BattleConstants.luau
    Central tuning constants for the battle system.
    All balance-related numbers live here for easy adjustment.
]]

local BattleConstants = {}

------------------------------------------------------------------------
-- Party & Battle Limits
------------------------------------------------------------------------

-- Maximum creatures a player can carry in their party
BattleConstants.MAX_PARTY_SIZE = 6

-- Maximum creatures per side in a battle (architecture supports 3v3)
BattleConstants.MAX_BATTLE_SIZE = 3

-- Maximum moves a creature can know at once
BattleConstants.MAX_MOVES = 4

------------------------------------------------------------------------
-- Stat Stage Multipliers
------------------------------------------------------------------------

-- Stat stages range from -4 to +4 (index 1–9 in this table).
-- Stage 0 = index 5 = multiplier 1.0 (no change).
-- Usage: multiplier = STAT_STAGE_MULTIPLIERS[stage + 5]
BattleConstants.STAT_STAGE_MULTIPLIERS = {
    -- -4    -3    -2    -1     0    +1    +2    +3    +4
    0.25, 0.28, 0.33, 0.50, 1.00, 1.50, 2.00, 3.00, 4.00,
}

-- Minimum and maximum stage values
BattleConstants.MIN_STAT_STAGE = -4
BattleConstants.MAX_STAT_STAGE = 4

------------------------------------------------------------------------
-- Damage & Combat
------------------------------------------------------------------------

-- Damage multiplier when a creature uses Defend action
BattleConstants.DEFEND_REDUCTION = 0.5

-- Same-Type Attack Bonus: multiplier when move element matches creature element
BattleConstants.STAB_MULTIPLIER = 1.5

-- Damage random variance range (final damage multiplied by random in this range)
BattleConstants.DAMAGE_RANDOM_MIN = 0.85
BattleConstants.DAMAGE_RANDOM_MAX = 1.00

-- Type effectiveness multipliers (applied by ElementTypes module)
BattleConstants.SUPER_EFFECTIVE = 2.0
BattleConstants.NOT_VERY_EFFECTIVE = 0.5
BattleConstants.NEUTRAL = 1.0

------------------------------------------------------------------------
-- Action Priority
------------------------------------------------------------------------

-- Higher number = goes first. Within same priority, Speed stat decides.
BattleConstants.ACTION_PRIORITY = {
    defend = 3,     -- Defend always goes first
    switch = 2,     -- Switching has second priority
    attack = 1,     -- Attacks resolve by Speed
    skill  = 1,     -- Skills resolve by Speed (same tier as attack)
    item   = 1,     -- Items resolve by Speed
}

------------------------------------------------------------------------
-- Capture
------------------------------------------------------------------------

-- Base capture rate before HP and level modifiers
BattleConstants.CAPTURE_BASE_RATE = 0.50

-- Minimum and maximum level penalty clamp
BattleConstants.CAPTURE_LEVEL_PENALTY_MIN = 0.5
BattleConstants.CAPTURE_LEVEL_PENALTY_MAX = 2.0

------------------------------------------------------------------------
-- XP & Leveling
------------------------------------------------------------------------

-- Base XP awarded per defeated creature (before level scaling)
BattleConstants.BASE_XP_REWARD = 50

-- XP required for next level: level^2 * XP_SCALE_FACTOR
BattleConstants.XP_SCALE_FACTOR = 10

-- Maximum creature level
BattleConstants.MAX_LEVEL = 100

------------------------------------------------------------------------
-- Stat Formulas  (used by CreatureFactory & LevelingSystem)
------------------------------------------------------------------------

-- General stat formula: floor((baseStat * 2 * level) / 100) + 5
-- HP stat formula:      floor((baseHP * 2 * level) / 100) + level + 10
-- MP formula:           floor((baseMp * level) / 50) + baseMp

------------------------------------------------------------------------
-- Encounter Timing
------------------------------------------------------------------------

-- Seconds range before a wild encounter triggers in tall grass
BattleConstants.ENCOUNTER_DELAY_MIN = 3.0
BattleConstants.ENCOUNTER_DELAY_MAX = 8.0

-- Cooldown after a battle before encounters can trigger again (seconds)
BattleConstants.ENCOUNTER_COOLDOWN = 5.0

------------------------------------------------------------------------
-- Starter
------------------------------------------------------------------------

-- Level at which new players receive their starter creature
BattleConstants.STARTER_LEVEL = 5

-- Starting items granted to new players
BattleConstants.STARTER_ITEMS = {
    { itemId = "health_potion", count = 5 },
    { itemId = "mana_elixir",   count = 3 },
    { itemId = "capture_orb",   count = 5 },
}

-- Starting currency
BattleConstants.STARTER_CURRENCY = 100

return BattleConstants
