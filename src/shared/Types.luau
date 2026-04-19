--[[
    Types.luau
    Central type definitions for BrainrotBattler.
    All modules should reference these types for consistency.
]]

local Types = {}

------------------------------------------------------------------------
-- Element
------------------------------------------------------------------------

export type ElementType =
    "Ember"
    | "Torrent"
    | "Verdant"
    | "Volt"
    | "Stone"
    | "Frost"
    | "Gale"
    | "Shadow"

------------------------------------------------------------------------
-- Stats
------------------------------------------------------------------------

export type Stats = {
    hp: number,
    attack: number,
    defense: number,
    spAttack: number,
    spDefense: number,
    speed: number,
}

------------------------------------------------------------------------
-- Creature Species  (shared database entry — immutable template)
------------------------------------------------------------------------

export type LearnableMove = {
    level: number,
    moveId: string,
}

export type CreatureSpecies = {
    id: string,
    name: string,
    element: ElementType,
    baseStats: Stats,
    baseMp: number,
    learnableMoves: { LearnableMove },
    description: string,
}

------------------------------------------------------------------------
-- Creature Instance  (a specific creature owned by a player or wild)
------------------------------------------------------------------------

export type CreatureInstance = {
    uid: string,               -- unique GUID
    speciesId: string,         -- key into CreatureDatabase
    nickname: string?,         -- optional player-given name
    level: number,             -- 1–100
    experience: number,        -- current XP toward next level

    stats: Stats,              -- calculated from base + level
    currentHp: number,
    maxHp: number,
    currentMp: number,
    maxMp: number,

    element: ElementType,
    moves: { string },         -- array of moveIds (up to 4)
    heldItem: string?,         -- optional itemId
}

------------------------------------------------------------------------
-- Move
------------------------------------------------------------------------

export type MoveCategory = "Physical" | "Special" | "Status"

export type MoveEffect = {
    effectType: string,        -- e.g. "boostStat", "lowerStat", "dot"
    target: "self" | "opponent",
    stat: string?,             -- which stat to affect (if applicable)
    stages: number?,           -- how many stages to raise/lower
    duration: number?,         -- turns (for duration-based effects)
}

export type Move = {
    id: string,
    name: string,
    element: ElementType,
    category: MoveCategory,
    power: number,             -- 0 for status moves
    accuracy: number,          -- 1–100
    mpCost: number,            -- 0 = free (e.g. Tackle)
    effect: MoveEffect?,       -- optional status effect
    description: string,
}

------------------------------------------------------------------------
-- Item
------------------------------------------------------------------------

export type ItemCategory = "Healing" | "Battle" | "Capture"

export type ItemEffect = {
    restoreHp: number?,
    restoreMp: number?,
    capture: boolean?,
    boostStat: string?,
    stages: number?,
}

export type Item = {
    id: string,
    name: string,
    category: ItemCategory,
    effect: ItemEffect,
    description: string,
}

------------------------------------------------------------------------
-- Player Data
------------------------------------------------------------------------

export type Inventory = { [string]: number }   -- { [itemId] = count }

export type PlayerData = {
    party: { CreatureInstance },          -- up to 6
    storage: { CreatureInstance },        -- overflow / PC box
    inventory: Inventory,
    currency: number,
    badges: { string },
}

------------------------------------------------------------------------
-- Battle
------------------------------------------------------------------------

export type ActionType = "attack" | "skill" | "defend" | "item" | "switch"

export type BattleAction = {
    actionType: ActionType,
    moveId: string?,           -- for attack / skill
    itemId: string?,           -- for item
    targetIndex: number?,      -- which opponent creature (for multi-battle)
    switchIndex: number?,      -- party index to switch to
}

export type BattleSide = {
    creatures: { CreatureInstance },
    activeIndex: number,
    owner: Player?,            -- nil for wild / AI side
}

export type StatStages = {
    attack: number,
    defense: number,
    spAttack: number,
    spDefense: number,
    speed: number,
}

export type BattleState = {
    id: string,
    sides: { BattleSide },             -- [1] = player, [2] = opponent
    turnNumber: number,
    status: string,                     -- "waiting_action" | "resolving" | "finished"
    pendingActions: { [number]: BattleAction? },  -- keyed by side index
    statStages: { [string]: StatStages },         -- keyed by creature uid
    isDefending: { [string]: boolean },            -- keyed by creature uid
    isWild: boolean,
}

------------------------------------------------------------------------
-- Turn Result  (sent from server → client after each turn resolves)
------------------------------------------------------------------------

export type TurnEvent = {
    eventType: string,
    -- Common fields (populated as needed per eventType):
    sourceSide: number?,
    sourceCreatureName: string?,
    targetSide: number?,
    targetCreatureName: string?,
    moveName: string?,
    moveElement: ElementType?,
    damage: number?,
    effectiveness: number?,      -- 0.5, 1.0, or 2.0
    isSTAB: boolean?,
    hpBefore: number?,
    hpAfter: number?,
    mpBefore: number?,
    mpAfter: number?,
    itemName: string?,
    statName: string?,
    stages: number?,
    fainted: boolean?,
    switchedTo: string?,         -- creature name switched to
    captureSuccess: boolean?,
    captureChance: number?,
    message: string?,            -- fallback display text
}

export type TurnResult = {
    turnNumber: number,
    events: { TurnEvent },
    -- Snapshot of both sides' active creatures after the turn
    sides: {
        {
            activeIndex: number,
            currentHp: number,
            maxHp: number,
            currentMp: number,
            maxMp: number,
        }
    },
}

------------------------------------------------------------------------
-- Battle End
------------------------------------------------------------------------

export type BattleEndResult = {
    outcome: string,              -- "win" | "lose" | "captured" | "fled"
    xpGained: number?,
    levelsGained: number?,
    newMoves: { string }?,        -- moveIds learned
    capturedCreature: CreatureInstance?,
}

------------------------------------------------------------------------
-- Spawn Table
------------------------------------------------------------------------

export type SpawnEntry = {
    speciesId: string,
    minLevel: number,
    maxLevel: number,
    weight: number,
}

export type ZoneSpawnTable = {
    zoneId: string,
    encounters: { SpawnEntry },
}

return Types
