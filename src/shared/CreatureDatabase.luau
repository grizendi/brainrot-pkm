--[[
    CreatureDatabase.luau
    Defines all creature species in the game.

    8 placeholder creatures — one per element.
    Base stat totals are in the 280–320 range for balance.

    learnableMoves: array of {level, moveId} sorted by level.
    Creatures learn moves at levels 1, 3, 5, 8, and 12.
    They can know up to 4 moves at a time (oldest replaced).
]]

local CreatureDatabase = {}

CreatureDatabase.Species = {

    --------------------------------------------------------------------------
    -- EMBER 🔥 — Cinderpup (balanced attacker)
    --------------------------------------------------------------------------

    Cinderpup = {
        id = "Cinderpup",
        name = "Cinderpup",
        element = "Ember",
        baseStats = {
            hp = 55,
            attack = 60,
            defense = 45,
            spAttack = 55,
            spDefense = 40,
            speed = 50,
        },
        -- Total: 305
        baseMp = 40,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "flame_bite" },
            { level = 5,  moveId = "heat_aura" },
            { level = 8,  moveId = "inferno_blast" },
            { level = 12, moveId = "rock_slam" },    -- coverage move
        },
        description = "A fiery wolf pup with embers dancing on its fur. Its playful nips leave scorch marks.",
    },

    --------------------------------------------------------------------------
    -- TORRENT 💧 — Tidesnap (tanky, high Def)
    --------------------------------------------------------------------------

    Tidesnap = {
        id = "Tidesnap",
        name = "Tidesnap",
        element = "Torrent",
        baseStats = {
            hp = 65,
            attack = 50,
            defense = 65,
            spAttack = 45,
            spDefense = 50,
            speed = 35,
        },
        -- Total: 310
        baseMp = 35,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "aqua_strike" },
            { level = 5,  moveId = "shell_guard" },
            { level = 8,  moveId = "tidal_surge" },
            { level = 12, moveId = "ice_fang" },      -- coverage move
        },
        description = "A stubborn snapping turtle with a shell that glistens like wet stone. Slow but very tough.",
    },

    --------------------------------------------------------------------------
    -- VERDANT 🌿 — Thornvine (Sp. Attack focused)
    --------------------------------------------------------------------------

    Thornvine = {
        id = "Thornvine",
        name = "Thornvine",
        element = "Verdant",
        baseStats = {
            hp = 50,
            attack = 40,
            defense = 50,
            spAttack = 65,
            spDefense = 55,
            speed = 45,
        },
        -- Total: 305
        baseMp = 45,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "vine_whip" },
            { level = 5,  moveId = "growth_pulse" },
            { level = 8,  moveId = "solar_beam" },
            { level = 12, moveId = "dark_pulse" },     -- coverage move
        },
        description = "A sentient mass of thorny vines with glowing seed-eyes. It draws power from sunlight.",
    },

    --------------------------------------------------------------------------
    -- VOLT ⚡ — Zapfox (high Speed)
    --------------------------------------------------------------------------

    Zapfox = {
        id = "Zapfox",
        name = "Zapfox",
        element = "Volt",
        baseStats = {
            hp = 45,
            attack = 50,
            defense = 35,
            spAttack = 60,
            spDefense = 45,
            speed = 70,
        },
        -- Total: 305
        baseMp = 40,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "spark_fang" },
            { level = 5,  moveId = "charge_up" },
            { level = 8,  moveId = "thunderbolt" },
            { level = 12, moveId = "wing_slash" },     -- coverage move
        },
        description = "A sleek fox crackling with static electricity. Its speed makes it almost impossible to catch.",
    },

    --------------------------------------------------------------------------
    -- STONE 🪨 — Bouldig (very high Def)
    --------------------------------------------------------------------------

    Bouldig = {
        id = "Bouldig",
        name = "Bouldig",
        element = "Stone",
        baseStats = {
            hp = 60,
            attack = 55,
            defense = 70,
            spAttack = 35,
            spDefense = 55,
            speed = 30,
        },
        -- Total: 305
        baseMp = 30,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "rock_slam" },
            { level = 5,  moveId = "fortify" },
            { level = 8,  moveId = "boulder_toss" },
            { level = 12, moveId = "flame_bite" },     -- coverage move
        },
        description = "A stout armadillo with boulders embedded in its armor plating. Nearly immovable once dug in.",
    },

    --------------------------------------------------------------------------
    -- FROST ❄️ — Glacipeck (Sp. Attack focused)
    --------------------------------------------------------------------------

    Glacipeck = {
        id = "Glacipeck",
        name = "Glacipeck",
        element = "Frost",
        baseStats = {
            hp = 50,
            attack = 40,
            defense = 45,
            spAttack = 65,
            spDefense = 60,
            speed = 45,
        },
        -- Total: 305
        baseMp = 45,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "ice_fang" },
            { level = 5,  moveId = "frost_veil" },
            { level = 8,  moveId = "blizzard_pulse" },
            { level = 12, moveId = "aqua_strike" },    -- coverage move
        },
        description = "A regal penguin coated in perpetual frost. Its breath freezes the air around it.",
    },

    --------------------------------------------------------------------------
    -- GALE 🌪️ — Gustwing (high Speed)
    --------------------------------------------------------------------------

    Gustwing = {
        id = "Gustwing",
        name = "Gustwing",
        element = "Gale",
        baseStats = {
            hp = 45,
            attack = 55,
            defense = 40,
            spAttack = 55,
            spDefense = 45,
            speed = 65,
        },
        -- Total: 305
        baseMp = 40,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "wing_slash" },
            { level = 5,  moveId = "tailwind" },
            { level = 8,  moveId = "cyclone" },
            { level = 12, moveId = "spark_fang" },     -- coverage move
        },
        description = "A fierce hawk that rides storm fronts. Its wingbeats create cutting gusts of wind.",
    },

    --------------------------------------------------------------------------
    -- SHADOW 🌑 — Umbrawl (high Attack)
    --------------------------------------------------------------------------

    Umbrawl = {
        id = "Umbrawl",
        name = "Umbrawl",
        element = "Shadow",
        baseStats = {
            hp = 50,
            attack = 65,
            defense = 45,
            spAttack = 55,
            spDefense = 40,
            speed = 55,
        },
        -- Total: 310
        baseMp = 40,
        learnableMoves = {
            { level = 1,  moveId = "tackle" },
            { level = 3,  moveId = "shadow_claw" },
            { level = 5,  moveId = "dread_gaze" },
            { level = 8,  moveId = "dark_pulse" },
            { level = 12, moveId = "ice_fang" },       -- coverage move
        },
        description = "A sleek shadow cat that phases in and out of darkness. Its eyes glow with an eerie light.",
    },
}

------------------------------------------------------------------------
-- Helper: get species by ID
------------------------------------------------------------------------

function CreatureDatabase.getSpecies(speciesId: string)
    return CreatureDatabase.Species[speciesId]
end

------------------------------------------------------------------------
-- Helper: get all species IDs
------------------------------------------------------------------------

function CreatureDatabase.getAllSpeciesIds(): { string }
    local ids = {}
    for id in CreatureDatabase.Species do
        table.insert(ids, id)
    end
    return ids
end

------------------------------------------------------------------------
-- Helper: get moves a creature would know at a given level
-- Returns up to MAX_MOVES (4) moveIds — the latest learned moves.
------------------------------------------------------------------------

function CreatureDatabase.getMovesAtLevel(speciesId: string, level: number): { string }
    local species = CreatureDatabase.Species[speciesId]
    if not species then
        return { "tackle" }
    end

    local learned = {}
    for _, entry in species.learnableMoves do
        if entry.level <= level then
            table.insert(learned, entry.moveId)
        end
    end

    -- Keep only the last 4 (most recently learned)
    local maxMoves = 4
    if #learned > maxMoves then
        local trimmed = {}
        for i = #learned - maxMoves + 1, #learned do
            table.insert(trimmed, learned[i])
        end
        return trimmed
    end

    -- Ensure at least Tackle
    if #learned == 0 then
        return { "tackle" }
    end

    return learned
end

return CreatureDatabase
