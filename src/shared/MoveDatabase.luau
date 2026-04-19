--[[
    MoveDatabase.luau
    Defines all moves/skills available in the game.

    Per element: 1 Physical, 1 Special, 1 Status move (24 elemental moves).
    Plus 1 universal free Physical move (Tackle).
    Total: 25 moves.

    Category determines which battle menu shows the move:
        "Physical" → Attack menu  (uses Attack vs Defense)
        "Special"  → Skills menu  (uses SpAttack vs SpDefense)
        "Status"   → Skills menu  (applies buffs/debuffs, 0 power)
]]

local MoveDatabase = {}

MoveDatabase.Moves = {

    --------------------------------------------------------------------------
    -- UNIVERSAL (no element — always available as fallback)
    --------------------------------------------------------------------------

    tackle = {
        id = "tackle",
        name = "Tackle",
        element = "Stone",       -- neutral-flavored; Stone for lack of "Normal"
        category = "Physical",
        power = 40,
        accuracy = 100,
        mpCost = 0,              -- FREE — always usable
        effect = nil,
        description = "A basic charge attack. Costs no MP.",
    },

    --------------------------------------------------------------------------
    -- EMBER  🔥
    --------------------------------------------------------------------------

    flame_bite = {
        id = "flame_bite",
        name = "Flame Bite",
        element = "Ember",
        category = "Physical",
        power = 55,
        accuracy = 95,
        mpCost = 5,
        effect = nil,
        description = "Clamp down with fiery jaws.",
    },

    inferno_blast = {
        id = "inferno_blast",
        name = "Inferno Blast",
        element = "Ember",
        category = "Special",
        power = 70,
        accuracy = 85,
        mpCost = 12,
        effect = nil,
        description = "Unleash a scorching wave of fire.",
    },

    heat_aura = {
        id = "heat_aura",
        name = "Heat Aura",
        element = "Ember",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "attack",
            stages = 1,
        },
        description = "Surround yourself in heat, raising Attack.",
    },

    --------------------------------------------------------------------------
    -- TORRENT  💧
    --------------------------------------------------------------------------

    aqua_strike = {
        id = "aqua_strike",
        name = "Aqua Strike",
        element = "Torrent",
        category = "Physical",
        power = 55,
        accuracy = 95,
        mpCost = 5,
        effect = nil,
        description = "Slam the foe with a water-coated limb.",
    },

    tidal_surge = {
        id = "tidal_surge",
        name = "Tidal Surge",
        element = "Torrent",
        category = "Special",
        power = 70,
        accuracy = 85,
        mpCost = 12,
        effect = nil,
        description = "Crash a massive wave into the opponent.",
    },

    shell_guard = {
        id = "shell_guard",
        name = "Shell Guard",
        element = "Torrent",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "defense",
            stages = 1,
        },
        description = "Harden your shell, raising Defense.",
    },

    --------------------------------------------------------------------------
    -- VERDANT  🌿
    --------------------------------------------------------------------------

    vine_whip = {
        id = "vine_whip",
        name = "Vine Whip",
        element = "Verdant",
        category = "Physical",
        power = 55,
        accuracy = 95,
        mpCost = 5,
        effect = nil,
        description = "Lash the foe with a thorny vine.",
    },

    solar_beam = {
        id = "solar_beam",
        name = "Solar Beam",
        element = "Verdant",
        category = "Special",
        power = 75,
        accuracy = 80,
        mpCost = 14,
        effect = nil,
        description = "Channel sunlight into a brilliant beam.",
    },

    growth_pulse = {
        id = "growth_pulse",
        name = "Growth Pulse",
        element = "Verdant",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "spAttack",
            stages = 1,
        },
        description = "Absorb natural energy, raising Sp. Attack.",
    },

    --------------------------------------------------------------------------
    -- VOLT  ⚡
    --------------------------------------------------------------------------

    spark_fang = {
        id = "spark_fang",
        name = "Spark Fang",
        element = "Volt",
        category = "Physical",
        power = 55,
        accuracy = 95,
        mpCost = 5,
        effect = nil,
        description = "Bite with electrically charged fangs.",
    },

    thunderbolt = {
        id = "thunderbolt",
        name = "Thunderbolt",
        element = "Volt",
        category = "Special",
        power = 70,
        accuracy = 90,
        mpCost = 12,
        effect = nil,
        description = "Hurl a crackling bolt of lightning.",
    },

    charge_up = {
        id = "charge_up",
        name = "Charge Up",
        element = "Volt",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "speed",
            stages = 1,
        },
        description = "Build up static charge, raising Speed.",
    },

    --------------------------------------------------------------------------
    -- STONE  🪨
    --------------------------------------------------------------------------

    rock_slam = {
        id = "rock_slam",
        name = "Rock Slam",
        element = "Stone",
        category = "Physical",
        power = 60,
        accuracy = 90,
        mpCost = 6,
        effect = nil,
        description = "Smash the foe with a heavy stone limb.",
    },

    boulder_toss = {
        id = "boulder_toss",
        name = "Boulder Toss",
        element = "Stone",
        category = "Special",
        power = 65,
        accuracy = 85,
        mpCost = 10,
        effect = nil,
        description = "Hurl a chunk of rock with crushing force.",
    },

    fortify = {
        id = "fortify",
        name = "Fortify",
        element = "Stone",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "defense",
            stages = 2,
        },
        description = "Coat yourself in stone, sharply raising Defense.",
    },

    --------------------------------------------------------------------------
    -- FROST  ❄️
    --------------------------------------------------------------------------

    ice_fang = {
        id = "ice_fang",
        name = "Ice Fang",
        element = "Frost",
        category = "Physical",
        power = 55,
        accuracy = 95,
        mpCost = 5,
        effect = nil,
        description = "Bite down with freezing cold fangs.",
    },

    blizzard_pulse = {
        id = "blizzard_pulse",
        name = "Blizzard Pulse",
        element = "Frost",
        category = "Special",
        power = 70,
        accuracy = 85,
        mpCost = 12,
        effect = nil,
        description = "Release a pulse of arctic wind and ice.",
    },

    frost_veil = {
        id = "frost_veil",
        name = "Frost Veil",
        element = "Frost",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "spDefense",
            stages = 1,
        },
        description = "Wrap yourself in frost, raising Sp. Defense.",
    },

    --------------------------------------------------------------------------
    -- GALE  🌪️
    --------------------------------------------------------------------------

    wing_slash = {
        id = "wing_slash",
        name = "Wing Slash",
        element = "Gale",
        category = "Physical",
        power = 55,
        accuracy = 95,
        mpCost = 5,
        effect = nil,
        description = "Slice with razor-sharp wind-laced wings.",
    },

    cyclone = {
        id = "cyclone",
        name = "Cyclone",
        element = "Gale",
        category = "Special",
        power = 70,
        accuracy = 85,
        mpCost = 12,
        effect = nil,
        description = "Conjure a violent whirlwind to batter the foe.",
    },

    tailwind = {
        id = "tailwind",
        name = "Tailwind",
        element = "Gale",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 8,
        effect = {
            effectType = "boostStat",
            target = "self",
            stat = "speed",
            stages = 1,
        },
        description = "Ride a gust of wind, raising Speed.",
    },

    --------------------------------------------------------------------------
    -- SHADOW  🌑
    --------------------------------------------------------------------------

    shadow_claw = {
        id = "shadow_claw",
        name = "Shadow Claw",
        element = "Shadow",
        category = "Physical",
        power = 60,
        accuracy = 90,
        mpCost = 6,
        effect = nil,
        description = "Slash with claws shrouded in darkness.",
    },

    dark_pulse = {
        id = "dark_pulse",
        name = "Dark Pulse",
        element = "Shadow",
        category = "Special",
        power = 70,
        accuracy = 90,
        mpCost = 12,
        effect = nil,
        description = "Emit a wave of sinister dark energy.",
    },

    dread_gaze = {
        id = "dread_gaze",
        name = "Dread Gaze",
        element = "Shadow",
        category = "Status",
        power = 0,
        accuracy = 100,
        mpCost = 6,
        effect = {
            effectType = "lowerStat",
            target = "opponent",
            stat = "attack",
            stages = 1,
        },
        description = "Fix the foe with a terrifying glare, lowering their Attack.",
    },
}

------------------------------------------------------------------------
-- Helper: get move by ID
------------------------------------------------------------------------

function MoveDatabase.getMove(moveId: string)
    return MoveDatabase.Moves[moveId]
end

------------------------------------------------------------------------
-- Helper: get all moves of a given category (for menu filtering)
------------------------------------------------------------------------

function MoveDatabase.filterByCategory(moveIds: { string }, category: string): { string }
    local result = {}
    for _, moveId in moveIds do
        local move = MoveDatabase.Moves[moveId]
        if move and move.category == category then
            table.insert(result, moveId)
        end
    end
    return result
end

--- Get Physical moves from a list (for Attack menu).
--- Always includes "tackle" if not already present.
function MoveDatabase.getPhysicalMoves(moveIds: { string }): { string }
    local result = MoveDatabase.filterByCategory(moveIds, "Physical")
    -- Ensure Tackle is always available
    local hasTackle = false
    for _, id in result do
        if id == "tackle" then
            hasTackle = true
            break
        end
    end
    if not hasTackle then
        table.insert(result, 1, "tackle")
    end
    return result
end

--- Get Special + Status moves from a list (for Skills menu).
function MoveDatabase.getSkillMoves(moveIds: { string }): { string }
    local result = {}
    for _, moveId in moveIds do
        local move = MoveDatabase.Moves[moveId]
        if move and (move.category == "Special" or move.category == "Status") then
            table.insert(result, moveId)
        end
    end
    return result
end

return MoveDatabase
