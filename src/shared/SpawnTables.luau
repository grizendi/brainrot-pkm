--[[
    SpawnTables.luau
    Defines which creatures can be encountered in each zone,
    along with their level ranges and spawn weights.

    Zones for the prototype map:
        route1_east  — Cinderpup & Thornvine  (levels 3–6)
        route1_west  — Tidesnap & Zapfox      (levels 3–6)
        route1_north — Bouldig, Gustwing, Glacipeck, Umbrawl (levels 5–8)

    Weights are relative within a zone — higher = more common.
]]

local SpawnTables = {}

------------------------------------------------------------------------
-- Zone definitions
------------------------------------------------------------------------

SpawnTables.Zones = {

    route1_east = {
        zoneId = "route1_east",
        encounters = {
            { speciesId = "Cinderpup", minLevel = 3, maxLevel = 6, weight = 50 },
            { speciesId = "Thornvine", minLevel = 3, maxLevel = 6, weight = 50 },
        },
    },

    route1_west = {
        zoneId = "route1_west",
        encounters = {
            { speciesId = "Tidesnap", minLevel = 3, maxLevel = 6, weight = 50 },
            { speciesId = "Zapfox",   minLevel = 3, maxLevel = 6, weight = 50 },
        },
    },

    route1_north = {
        zoneId = "route1_north",
        encounters = {
            { speciesId = "Bouldig",   minLevel = 5, maxLevel = 8, weight = 30 },
            { speciesId = "Gustwing",  minLevel = 5, maxLevel = 8, weight = 30 },
            { speciesId = "Glacipeck", minLevel = 5, maxLevel = 8, weight = 20 },
            { speciesId = "Umbrawl",   minLevel = 5, maxLevel = 8, weight = 20 },
        },
    },
}

------------------------------------------------------------------------
-- Helper: get all zone IDs
------------------------------------------------------------------------

function SpawnTables.getZoneIds(): { string }
    local ids = {}
    for id in SpawnTables.Zones do
        table.insert(ids, id)
    end
    return ids
end

------------------------------------------------------------------------
-- Core: roll a random encounter from a zone
------------------------------------------------------------------------

--[[
    Pick a random creature from the given zone's spawn table
    using weighted random selection.

    @param zoneId string — which zone to roll from
    @return { speciesId: string, level: number } | nil
]]
function SpawnTables.rollEncounter(zoneId: string): { speciesId: string, level: number }?
    local zone = SpawnTables.Zones[zoneId]
    if not zone then
        warn("[SpawnTables] Unknown zoneId: " .. tostring(zoneId))
        return nil
    end

    local encounters = zone.encounters
    if #encounters == 0 then
        return nil
    end

    -- Calculate total weight
    local totalWeight = 0
    for _, entry in encounters do
        totalWeight = totalWeight + entry.weight
    end

    -- Weighted random pick
    local roll = math.random() * totalWeight
    local cumulative = 0
    local picked = encounters[1]  -- fallback

    for _, entry in encounters do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            picked = entry
            break
        end
    end

    -- Random level within range
    local level = math.random(picked.minLevel, picked.maxLevel)

    return {
        speciesId = picked.speciesId,
        level = level,
    }
end

return SpawnTables
