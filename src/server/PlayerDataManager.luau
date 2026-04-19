--[[
    PlayerDataManager.luau  (Server module)
    In-memory player data storage for the prototype.
    No DataStore persistence — data resets each session.

    Handles:
        - Initializing new players with a starter creature + items
        - Party management (add, remove, swap)
        - Inventory management (add, remove, check)
        - Healing
        - RemoteFunction wiring for client queries
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BattleConstants = require(Shared:WaitForChild("BattleConstants"))
local CreatureFactory = require(script.Parent:WaitForChild("CreatureFactory"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local PlayerDataManager = {}

------------------------------------------------------------------------
-- Internal storage: { [userId: number] = PlayerData }
------------------------------------------------------------------------

local playerDataStore: { [number]: any } = {}

------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

function PlayerDataManager.init()
    -- Wire up RemoteFunctions
    if Remotes.GetPlayerData then
        Remotes.GetPlayerData.OnServerInvoke = function(player: Player)
            return PlayerDataManager.getData(player)
        end
    end

    if Remotes.GetPartyInfo then
        Remotes.GetPartyInfo.OnServerInvoke = function(player: Player)
            return PlayerDataManager.getParty(player)
        end
    end

    -- Handle player joining
    Players.PlayerAdded:Connect(function(player: Player)
        PlayerDataManager._initializePlayer(player)
    end)

    -- Handle players already in game (Studio testing)
    for _, player in Players:GetPlayers() do
        if not playerDataStore[player.UserId] then
            PlayerDataManager._initializePlayer(player)
        end
    end

    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player: Player)
        playerDataStore[player.UserId] = nil
    end)

    print("[PlayerDataManager] Initialized")
end

------------------------------------------------------------------------
-- Internal: create initial data for a new player
------------------------------------------------------------------------

function PlayerDataManager._initializePlayer(player: Player)
    -- Pick a random starter creature
    local starterSpeciesId = CreatureFactory.getRandomSpeciesId()
    local starter = CreatureFactory.createStarterCreature(starterSpeciesId)

    if not starter then
        warn("[PlayerDataManager] Failed to create starter for " .. player.Name)
        return
    end

    -- Build starting inventory from BattleConstants
    local inventory: { [string]: number } = {}
    for _, item in BattleConstants.STARTER_ITEMS do
        inventory[item.itemId] = item.count
    end

    -- Create player data
    local data = {
        party = { starter },
        storage = {},
        inventory = inventory,
        currency = BattleConstants.STARTER_CURRENCY,
        badges = {},
    }

    playerDataStore[player.UserId] = data

    print("[PlayerDataManager] " .. player.Name .. " initialized with " .. starter.speciesId
        .. " (Lv." .. starter.level .. ")")
end

------------------------------------------------------------------------
-- Data access
------------------------------------------------------------------------

--- Get a player's full data table.
function PlayerDataManager.getData(player: Player): any
    return playerDataStore[player.UserId]
end

--- Get a player's party (array of CreatureInstances).
function PlayerDataManager.getParty(player: Player): { any }
    local data = playerDataStore[player.UserId]
    if not data then
        return {}
    end
    return data.party
end

--- Check if a player has data loaded.
function PlayerDataManager.hasData(player: Player): boolean
    return playerDataStore[player.UserId] ~= nil
end

------------------------------------------------------------------------
-- Party management
------------------------------------------------------------------------

--- Add a creature to the player's party. If party is full, goes to storage.
--- Returns "party" or "storage" indicating where it was placed.
function PlayerDataManager.addCreature(player: Player, creature: any): string
    local data = playerDataStore[player.UserId]
    if not data then
        return "error"
    end

    if #data.party < BattleConstants.MAX_PARTY_SIZE then
        table.insert(data.party, creature)
        return "party"
    else
        table.insert(data.storage, creature)
        return "storage"
    end
end

--- Remove a creature from the party by index. Returns the removed creature.
function PlayerDataManager.removeFromParty(player: Player, index: number): any
    local data = playerDataStore[player.UserId]
    if not data or index < 1 or index > #data.party then
        return nil
    end
    return table.remove(data.party, index)
end

--- Swap two party positions.
function PlayerDataManager.swapPartyPositions(player: Player, indexA: number, indexB: number)
    local data = playerDataStore[player.UserId]
    if not data then
        return
    end
    local party = data.party
    if indexA < 1 or indexA > #party or indexB < 1 or indexB > #party then
        return
    end
    party[indexA], party[indexB] = party[indexB], party[indexA]
end

--- Get the first non-fainted creature index in the party.
function PlayerDataManager.getFirstAliveIndex(player: Player): number?
    local data = playerDataStore[player.UserId]
    if not data then
        return nil
    end
    for i, creature in data.party do
        if creature.currentHp > 0 then
            return i
        end
    end
    return nil
end

--- Check if the player has any non-fainted creatures.
function PlayerDataManager.hasAliveCreatures(player: Player): boolean
    return PlayerDataManager.getFirstAliveIndex(player) ~= nil
end

------------------------------------------------------------------------
-- Inventory management
------------------------------------------------------------------------

--- Get the count of a specific item.
function PlayerDataManager.getItemCount(player: Player, itemId: string): number
    local data = playerDataStore[player.UserId]
    if not data then
        return 0
    end
    return data.inventory[itemId] or 0
end

--- Add items to the player's inventory.
function PlayerDataManager.addItem(player: Player, itemId: string, count: number)
    local data = playerDataStore[player.UserId]
    if not data then
        return
    end
    data.inventory[itemId] = (data.inventory[itemId] or 0) + count
end

--- Remove an item from inventory. Returns true if successful.
function PlayerDataManager.removeItem(player: Player, itemId: string, count: number?): boolean
    local removeCount = count or 1
    local data = playerDataStore[player.UserId]
    if not data then
        return false
    end

    local current = data.inventory[itemId] or 0
    if current < removeCount then
        return false
    end

    current = current - removeCount
    if current <= 0 then
        data.inventory[itemId] = nil
    else
        data.inventory[itemId] = current
    end

    return true
end

--- Get the full inventory table.
function PlayerDataManager.getInventory(player: Player): { [string]: number }
    local data = playerDataStore[player.UserId]
    if not data then
        return {}
    end
    return data.inventory
end

------------------------------------------------------------------------
-- Currency
------------------------------------------------------------------------

function PlayerDataManager.getCurrency(player: Player): number
    local data = playerDataStore[player.UserId]
    if not data then
        return 0
    end
    return data.currency
end

function PlayerDataManager.addCurrency(player: Player, amount: number)
    local data = playerDataStore[player.UserId]
    if not data then
        return
    end
    data.currency = data.currency + amount
end

function PlayerDataManager.removeCurrency(player: Player, amount: number): boolean
    local data = playerDataStore[player.UserId]
    if not data then
        return false
    end
    if data.currency < amount then
        return false
    end
    data.currency = data.currency - amount
    return true
end

------------------------------------------------------------------------
-- Healing
------------------------------------------------------------------------

--- Fully heal all creatures in the player's party (HP and MP).
function PlayerDataManager.healParty(player: Player)
    local data = playerDataStore[player.UserId]
    if not data then
        return
    end
    for _, creature in data.party do
        creature.currentHp = creature.maxHp
        creature.currentMp = creature.maxMp
    end

    -- Notify client
    if Remotes.PartyHealed then
        Remotes.PartyHealed:FireClient(player)
    end

    print("[PlayerDataManager] " .. player.Name .. "'s party healed")
end

------------------------------------------------------------------------
-- Battle helpers
------------------------------------------------------------------------

--- Update a creature in the party by uid (after battle modifies it).
function PlayerDataManager.updateCreature(player: Player, updatedCreature: any)
    local data = playerDataStore[player.UserId]
    if not data then
        return
    end
    for i, creature in data.party do
        if creature.uid == updatedCreature.uid then
            data.party[i] = updatedCreature
            return
        end
    end
end

--- Apply mercy rule: set all fainted creatures to 1 HP (after losing a battle).
function PlayerDataManager.applyMercyRule(player: Player)
    local data = playerDataStore[player.UserId]
    if not data then
        return
    end
    for _, creature in data.party do
        if creature.currentHp <= 0 then
            creature.currentHp = 1
        end
    end
end

return PlayerDataManager
