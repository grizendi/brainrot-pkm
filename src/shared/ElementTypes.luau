--[[
    ElementTypes.luau
    Defines the 8 element types and their effectiveness relationships.

    Effectiveness values:
        2.0  = super effective
        0.5  = not very effective
        1.0  = neutral

    Each element is strong against exactly 2 others and weak against exactly 2.

    Chart:
        Ember   → strong vs Verdant, Frost   | weak vs Torrent, Stone
        Torrent → strong vs Ember, Stone     | weak vs Verdant, Volt
        Verdant → strong vs Torrent, Stone   | weak vs Ember, Frost
        Volt    → strong vs Torrent, Gale    | weak vs Stone, Verdant
        Stone   → strong vs Ember, Volt      | weak vs Torrent, Verdant
        Frost   → strong vs Verdant, Gale    | weak vs Ember, Shadow
        Gale    → strong vs Verdant, Shadow  | weak vs Volt, Frost
        Shadow  → strong vs Frost, Gale      | weak vs Ember, Stone
]]

local ElementTypes = {}

------------------------------------------------------------------------
-- Element enum
------------------------------------------------------------------------

ElementTypes.Elements = {
    "Ember",
    "Torrent",
    "Verdant",
    "Volt",
    "Stone",
    "Frost",
    "Gale",
    "Shadow",
}

-- Quick lookup set: ElementTypes.IsElement["Ember"] == true
ElementTypes.IsElement = {}
for _, element in ElementTypes.Elements do
    ElementTypes.IsElement[element] = true
end

------------------------------------------------------------------------
-- Element display colors (for UI badges, move labels, etc.)
------------------------------------------------------------------------

ElementTypes.Colors = {
    Ember   = Color3.fromRGB(230, 90, 40),    -- fiery orange-red
    Torrent = Color3.fromRGB(50, 140, 220),    -- ocean blue
    Verdant = Color3.fromRGB(60, 180, 75),     -- forest green
    Volt    = Color3.fromRGB(240, 200, 40),    -- electric yellow
    Stone   = Color3.fromRGB(160, 130, 95),    -- earthy brown
    Frost   = Color3.fromRGB(130, 210, 240),   -- icy light blue
    Gale    = Color3.fromRGB(170, 210, 190),   -- misty teal-gray
    Shadow  = Color3.fromRGB(90, 60, 120),     -- deep purple
}

------------------------------------------------------------------------
-- Type Effectiveness Matrix
------------------------------------------------------------------------

-- Keys: EFFECTIVENESS[attackingElement][defendingElement] = multiplier
-- Only non-neutral (≠ 1.0) matchups are stored; getEffectiveness()
-- defaults to 1.0 for anything not listed.

local EFFECTIVENESS = {
    Ember = {
        Verdant = 2.0,
        Frost   = 2.0,
        Torrent = 0.5,
        Stone   = 0.5,
    },
    Torrent = {
        Ember = 2.0,
        Stone = 2.0,
        Verdant = 0.5,
        Volt    = 0.5,
    },
    Verdant = {
        Torrent = 2.0,
        Stone   = 2.0,
        Ember = 0.5,
        Frost = 0.5,
    },
    Volt = {
        Torrent = 2.0,
        Gale    = 2.0,
        Stone   = 0.5,
        Verdant = 0.5,
    },
    Stone = {
        Ember = 2.0,
        Volt  = 2.0,
        Torrent = 0.5,
        Verdant = 0.5,
    },
    Frost = {
        Verdant = 2.0,
        Gale    = 2.0,
        Ember  = 0.5,
        Shadow = 0.5,
    },
    Gale = {
        Verdant = 2.0,
        Shadow  = 2.0,
        Volt  = 0.5,
        Frost = 0.5,
    },
    Shadow = {
        Frost = 2.0,
        Gale  = 2.0,
        Ember = 0.5,
        Stone = 0.5,
    },
}

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

--- Returns the type effectiveness multiplier for an attack.
--- @param attackElement string — the element of the move being used
--- @param defendElement string — the element of the defending creature
--- @return number — 2.0 (super effective), 0.5 (not very effective), or 1.0 (neutral)
function ElementTypes.getEffectiveness(attackElement: string, defendElement: string): number
    local attackTable = EFFECTIVENESS[attackElement]
    if attackTable then
        local value = attackTable[defendElement]
        if value then
            return value
        end
    end
    return 1.0 -- neutral
end

--- Returns a human-readable label for the effectiveness value.
--- @param effectiveness number
--- @return string
function ElementTypes.getEffectivenessLabel(effectiveness: number): string
    if effectiveness >= 2.0 then
        return "It's super effective!"
    elseif effectiveness <= 0.5 then
        return "It's not very effective..."
    end
    return ""
end

--- Returns the display Color3 for an element.
--- @param element string
--- @return Color3
function ElementTypes.getColor(element: string): Color3
    return ElementTypes.Colors[element] or Color3.fromRGB(200, 200, 200)
end

return ElementTypes
