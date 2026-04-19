--[[
    ItemDatabase.luau
    Defines all usable items in the game.

    Categories:
        "Healing"  — Restore HP and/or MP
        "Battle"   — Temporary stat boosts during battle
        "Capture"  — Attempt to capture a wild creature
]]

local ItemDatabase = {}

ItemDatabase.Items = {

    --------------------------------------------------------------------------
    -- HEALING
    --------------------------------------------------------------------------

    health_potion = {
        id = "health_potion",
        name = "Health Potion",
        category = "Healing",
        effect = {
            restoreHp = 50,
        },
        description = "A basic potion that restores 50 HP.",
    },

    mana_elixir = {
        id = "mana_elixir",
        name = "Mana Elixir",
        category = "Healing",
        effect = {
            restoreMp = 30,
        },
        description = "A small elixir that restores 30 MP.",
    },

    full_restore = {
        id = "full_restore",
        name = "Full Restore",
        category = "Healing",
        effect = {
            restoreHp = 9999,
            restoreMp = 9999,
        },
        description = "A powerful remedy that fully restores HP and MP.",
    },

    --------------------------------------------------------------------------
    -- CAPTURE
    --------------------------------------------------------------------------

    capture_orb = {
        id = "capture_orb",
        name = "Capture Orb",
        category = "Capture",
        effect = {
            capture = true,
        },
        description = "Throw at a weakened wild creature to attempt capture.",
    },

    --------------------------------------------------------------------------
    -- BATTLE  (stat boosts)
    --------------------------------------------------------------------------

    attack_boost = {
        id = "attack_boost",
        name = "Attack Boost",
        category = "Battle",
        effect = {
            boostStat = "attack",
            stages = 1,
        },
        description = "Raises the active creature's Attack by 1 stage.",
    },

    defense_boost = {
        id = "defense_boost",
        name = "Defense Boost",
        category = "Battle",
        effect = {
            boostStat = "defense",
            stages = 1,
        },
        description = "Raises the active creature's Defense by 1 stage.",
    },
}

------------------------------------------------------------------------
-- Helper: get item by ID
------------------------------------------------------------------------

function ItemDatabase.getItem(itemId: string)
    return ItemDatabase.Items[itemId]
end

------------------------------------------------------------------------
-- Helper: check if an item can be used in battle
------------------------------------------------------------------------

function ItemDatabase.isUsableInBattle(itemId: string): boolean
    local item = ItemDatabase.Items[itemId]
    if not item then
        return false
    end
    -- All item categories are currently usable in battle
    return true
end

------------------------------------------------------------------------
-- Helper: get all item IDs
------------------------------------------------------------------------

function ItemDatabase.getAllItemIds(): { string }
    local ids = {}
    for id in ItemDatabase.Items do
        table.insert(ids, id)
    end
    return ids
end

return ItemDatabase
