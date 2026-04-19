--[[
    WildSpawnSystem.luau  (Server module)
    Programmatically builds the prototype map and encounter zones.

    Map layout:
        - Starter Town (center) — safe zone with healer NPC
        - Route 1 East — tall grass zone (Cinderpup, Thornvine)
        - Route 1 West — tall grass zone (Tidesnap, Zapfox)
        - Route 1 North — tall grass zone (Bouldig, Gustwing, Glacipeck, Umbrawl)
        - Paths connecting the areas

    Each tall grass zone consists of:
        1. Visual green parts (clusters of tufts)
        2. An invisible trigger volume tagged with CollectionService
]]

local CollectionService = game:GetService("CollectionService")

local WildSpawnSystem = {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local ENCOUNTER_ZONE_TAG = "EncounterZone"

local GROUND_COLOR = Color3.fromRGB(120, 160, 90)      -- grassy green ground
local PATH_COLOR = Color3.fromRGB(180, 165, 130)        -- dirt path
local TOWN_COLOR = Color3.fromRGB(190, 185, 170)        -- stone/town
local GRASS_COLOR = Color3.fromRGB(50, 170, 60)          -- encounter grass tufts
local HEALER_COLOR = Color3.fromRGB(220, 80, 80)        -- healer NPC
local WATER_COLOR = Color3.fromRGB(70, 130, 200)        -- decorative

-- Grass zone definitions: position, size, zoneId
local GRASS_ZONES = {
    {
        name = "Route1_East_Grass",
        zoneId = "route1_east",
        position = Vector3.new(80, 0.5, 0),
        size = Vector3.new(50, 1, 40),
        grassCount = 25,
    },
    {
        name = "Route1_West_Grass",
        zoneId = "route1_west",
        position = Vector3.new(-80, 0.5, 0),
        size = Vector3.new(50, 1, 40),
        grassCount = 25,
    },
    {
        name = "Route1_North_Grass",
        zoneId = "route1_north",
        position = Vector3.new(0, 0.5, -100),
        size = Vector3.new(60, 1, 50),
        grassCount = 35,
    },
}

------------------------------------------------------------------------
-- Internal: create a simple part
------------------------------------------------------------------------

local function createPart(parent: Instance, props: any): Part
    local part = Instance.new("Part")
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    if props.name then part.Name = props.name end
    if props.size then part.Size = props.size end
    if props.position then part.Position = props.position end
    if props.color then part.Color = props.color end
    if props.transparency then part.Transparency = props.transparency end
    if props.canCollide ~= nil then part.CanCollide = props.canCollide end
    if props.material then part.Material = props.material end

    part.Parent = parent
    return part
end

------------------------------------------------------------------------
-- Internal: create a billboard text label on a part
------------------------------------------------------------------------

local function createBillboard(parent: Instance, text: string, color: Color3?)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Label"
    billboard.Size = UDim2.new(8, 0, 2, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
end

------------------------------------------------------------------------
-- Build: Starter Town
------------------------------------------------------------------------

local function buildStarterTown(mapFolder: Folder)
    local town = Instance.new("Folder")
    town.Name = "StarterTown"
    town.Parent = mapFolder

    -- Town ground platform
    createPart(town, {
        name = "TownGround",
        size = Vector3.new(60, 1, 60),
        position = Vector3.new(0, 0, 0),
        color = TOWN_COLOR,
        material = Enum.Material.Cobblestone,
    })

    -- Healer NPC (just a colored part with a billboard)
    local healer = createPart(town, {
        name = "HealerNPC",
        size = Vector3.new(3, 6, 3),
        position = Vector3.new(10, 3.5, 10),
        color = HEALER_COLOR,
        material = Enum.Material.SmoothPlastic,
    })
    createBillboard(healer, "🏥 Healer\nTouch to heal!", Color3.fromRGB(255, 200, 200))

    -- Decorative fountain (center of town)
    createPart(town, {
        name = "Fountain",
        size = Vector3.new(6, 2, 6),
        position = Vector3.new(0, 1, 0),
        color = WATER_COLOR,
        material = Enum.Material.Glass,
        transparency = 0.3,
    })

    -- Town sign
    local sign = createPart(town, {
        name = "TownSign",
        size = Vector3.new(4, 3, 0.5),
        position = Vector3.new(-15, 2, 25),
        color = Color3.fromRGB(139, 90, 43),
        material = Enum.Material.Wood,
    })
    createBillboard(sign, "🏘️ Starter Town", Color3.fromRGB(255, 240, 200))

    return healer
end

------------------------------------------------------------------------
-- Build: Paths / Routes
------------------------------------------------------------------------

local function buildPaths(mapFolder: Folder)
    local paths = Instance.new("Folder")
    paths.Name = "Paths"
    paths.Parent = mapFolder

    -- Ground extending in all directions
    -- East path
    createPart(paths, {
        name = "PathEast",
        size = Vector3.new(80, 0.5, 12),
        position = Vector3.new(50, 0.1, 0),
        color = PATH_COLOR,
        material = Enum.Material.Sand,
    })

    -- West path
    createPart(paths, {
        name = "PathWest",
        size = Vector3.new(80, 0.5, 12),
        position = Vector3.new(-50, 0.1, 0),
        color = PATH_COLOR,
        material = Enum.Material.Sand,
    })

    -- North path
    createPart(paths, {
        name = "PathNorth",
        size = Vector3.new(12, 0.5, 80),
        position = Vector3.new(0, 0.1, -50),
        color = PATH_COLOR,
        material = Enum.Material.Sand,
    })

    -- Surrounding ground (grass color)
    createPart(paths, {
        name = "GroundEast",
        size = Vector3.new(120, 0.3, 80),
        position = Vector3.new(80, -0.1, 0),
        color = GROUND_COLOR,
        material = Enum.Material.Grass,
    })

    createPart(paths, {
        name = "GroundWest",
        size = Vector3.new(120, 0.3, 80),
        position = Vector3.new(-80, -0.1, 0),
        color = GROUND_COLOR,
        material = Enum.Material.Grass,
    })

    createPart(paths, {
        name = "GroundNorth",
        size = Vector3.new(80, 0.3, 120),
        position = Vector3.new(0, -0.1, -100),
        color = GROUND_COLOR,
        material = Enum.Material.Grass,
    })
end

------------------------------------------------------------------------
-- Build: Tall Grass Encounter Zones
------------------------------------------------------------------------

local function buildGrassZone(mapFolder: Folder, zoneDef: any)
    local zoneFolder = Instance.new("Folder")
    zoneFolder.Name = zoneDef.name
    zoneFolder.Parent = mapFolder

    local zonePos = zoneDef.position
    local zoneSize = zoneDef.size

    -- Create individual grass tuft parts (visual)
    for i = 1, zoneDef.grassCount do
        local offsetX = (math.random() - 0.5) * zoneSize.X * 0.9
        local offsetZ = (math.random() - 0.5) * zoneSize.Z * 0.9
        local height = 1.5 + math.random() * 1.5

        createPart(zoneFolder, {
            name = "GrassTuft_" .. i,
            size = Vector3.new(1.5 + math.random() * 1, height, 1.5 + math.random() * 1),
            position = Vector3.new(
                zonePos.X + offsetX,
                height / 2 + 0.2,
                zonePos.Z + offsetZ
            ),
            color = GRASS_COLOR,
            material = Enum.Material.Grass,
            transparency = 0.2,
            canCollide = false,
        })
    end

    -- Create invisible trigger volume
    local trigger = createPart(zoneFolder, {
        name = "Trigger_" .. zoneDef.zoneId,
        size = Vector3.new(zoneSize.X, 8, zoneSize.Z),  -- tall enough to catch players
        position = Vector3.new(zonePos.X, 4, zonePos.Z),
        transparency = 1,
        canCollide = false,
    })

    -- Tag for CollectionService & set zoneId attribute
    CollectionService:AddTag(trigger, ENCOUNTER_ZONE_TAG)
    trigger:SetAttribute("zoneId", zoneDef.zoneId)

    -- Zone sign
    local sign = createPart(zoneFolder, {
        name = "ZoneSign",
        size = Vector3.new(3, 2, 0.4),
        position = Vector3.new(
            zonePos.X,
            1.5,
            zonePos.Z + zoneSize.Z / 2 + 2
        ),
        color = Color3.fromRGB(139, 90, 43),
        material = Enum.Material.Wood,
    })
    createBillboard(sign, "⚠ Wild Area\n" .. zoneDef.zoneId, Color3.fromRGB(255, 220, 100))

    return trigger
end

------------------------------------------------------------------------
-- Public: initialize the entire map
------------------------------------------------------------------------

function WildSpawnSystem.init()
    -- Create map folder in Workspace
    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "Map"
    mapFolder.Parent = workspace

    -- Build all areas
    local healer = buildStarterTown(mapFolder)
    buildPaths(mapFolder)

    -- Build encounter zones
    local triggers = {}
    for _, zoneDef in GRASS_ZONES do
        local trigger = buildGrassZone(mapFolder, zoneDef)
        table.insert(triggers, trigger)
    end

    print("[WildSpawnSystem] Map built: Starter Town + 3 encounter zones (" .. #triggers .. " triggers)")

    -- Return healer reference for EncounterSystem to wire up
    return {
        healer = healer,
        triggers = triggers,
    }
end

--- Get the encounter zone tag name (used by EncounterSystem)
function WildSpawnSystem.getEncounterZoneTag(): string
    return ENCOUNTER_ZONE_TAG
end

return WildSpawnSystem
