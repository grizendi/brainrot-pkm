--[[
    BattleEngine.luau  (Server module)
    Server-authoritative turn-based battle engine.

    Supports 1v1 through 3v3 (architecture uses array-based sides).
    Prototype focuses on 1v1 wild encounters.

    Battle flow:
        1. BattleEngine.startBattle() creates a BattleState
        2. Server fires BattleStart to client
        3. Each turn:
            a. Server fires BattleRequestAction to player
            b. Player sends BattleSubmitAction
            c. AI picks action (if wild side)
            d. Engine resolves turn (priority + speed order)
            e. Server fires BattleTurnResult with events
            f. Check for faints → prompt switch or end
        4. Battle ends → fire BattleEnd with results
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BattleConstants = require(Shared:WaitForChild("BattleConstants"))
local DamageCalculator = require(Shared:WaitForChild("DamageCalculator"))
local MoveDatabase = require(Shared:WaitForChild("MoveDatabase"))
local ItemDatabase = require(Shared:WaitForChild("ItemDatabase"))
local ElementTypes = require(Shared:WaitForChild("ElementTypes"))

-- Lazy-loaded to avoid circular dependencies
local Remotes = nil
local PlayerDataManager = nil
local BattleAI = nil
local CaptureSystem = nil
local LevelingSystem = nil

local BattleEngine = {}

------------------------------------------------------------------------
-- Active battles storage: { [battleId] = BattleState }
------------------------------------------------------------------------

local activeBattles: { [string]: any } = {}

-- Map player → battleId for quick lookups
local playerBattleMap: { [number]: string } = {}

------------------------------------------------------------------------
-- Lazy dependency loading
------------------------------------------------------------------------

local function ensureDependencies()
    if not Remotes then
        Remotes = require(script.Parent:WaitForChild("Remotes"))
    end
    if not PlayerDataManager then
        PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    end
    if not BattleAI then
        BattleAI = require(script.Parent:WaitForChild("BattleAI"))
    end
    if not CaptureSystem then
        CaptureSystem = require(script.Parent:WaitForChild("CaptureSystem"))
    end
    if not LevelingSystem then
        LevelingSystem = require(script.Parent:WaitForChild("LevelingSystem"))
    end
end

------------------------------------------------------------------------
-- Helper: get active creature for a side
------------------------------------------------------------------------

local function getActiveCreature(battle: any, sideIndex: number): any
    local side = battle.sides[sideIndex]
    return side.creatures[side.activeIndex]
end

------------------------------------------------------------------------
-- Helper: get stat stages for a creature
------------------------------------------------------------------------

local function getStatStages(battle: any, creatureUid: string): any
    if not battle.statStages[creatureUid] then
        battle.statStages[creatureUid] = {
            attack = 0,
            defense = 0,
            spAttack = 0,
            spDefense = 0,
            speed = 0,
        }
    end
    return battle.statStages[creatureUid]
end

------------------------------------------------------------------------
-- Helper: get effective speed (with stat stages)
------------------------------------------------------------------------

local function getEffectiveSpeed(creature: any, stages: any): number
    local speedStage = stages.speed or 0
    local clampedStage = math.clamp(speedStage, BattleConstants.MIN_STAT_STAGE, BattleConstants.MAX_STAT_STAGE)
    local index = clampedStage - BattleConstants.MIN_STAT_STAGE + 1
    local multiplier = BattleConstants.STAT_STAGE_MULTIPLIERS[index]
    return math.floor(creature.stats.speed * multiplier)
end

------------------------------------------------------------------------
-- Helper: build a safe creature snapshot for the client
------------------------------------------------------------------------

local function creatureSnapshot(creature: any): any
    return {
        uid = creature.uid,
        speciesId = creature.speciesId,
        nickname = creature.nickname,
        name = creature.speciesId,  -- display name fallback
        level = creature.level,
        element = creature.element,
        currentHp = creature.currentHp,
        maxHp = creature.maxHp,
        currentMp = creature.currentMp,
        maxMp = creature.maxMp,
        moves = creature.moves,
        stats = creature.stats,
    }
end

local function sideSnapshot(side: any): any
    local creatures = {}
    for _, c in side.creatures do
        table.insert(creatures, creatureSnapshot(c))
    end
    return {
        creatures = creatures,
        activeIndex = side.activeIndex,
    }
end

------------------------------------------------------------------------
-- START BATTLE
------------------------------------------------------------------------

--[[
    Start a new battle.

    @param player Player — the human player
    @param playerCreatures {CreatureInstance} — player's battle team
    @param opponentCreatures {CreatureInstance} — wild/trainer creatures
    @param isWild boolean — true for wild encounters
    @return battleId string
]]
function BattleEngine.startBattle(
    player: Player,
    playerCreatures: { any },
    opponentCreatures: { any },
    isWild: boolean
): string
    ensureDependencies()

    local battleId = HttpService:GenerateGUID(false)

    local battle = {
        id = battleId,
        sides = {
            [1] = {
                creatures = playerCreatures,
                activeIndex = 1,
                owner = player,
            },
            [2] = {
                creatures = opponentCreatures,
                activeIndex = 1,
                owner = nil,  -- AI-controlled
            },
        },
        turnNumber = 0,
        status = "waiting_action",
        pendingActions = {},
        statStages = {},
        isDefending = {},
        isWild = isWild,
    }

    activeBattles[battleId] = battle
    playerBattleMap[player.UserId] = battleId

    -- Send battle data to client
    Remotes.BattleStart:FireClient(player, {
        battleId = battleId,
        playerSide = sideSnapshot(battle.sides[1]),
        opponentSide = sideSnapshot(battle.sides[2]),
        isWild = isWild,
    })

    -- Start first turn
    task.defer(function()
        BattleEngine._requestActions(battleId)
    end)

    print("[BattleEngine] Battle started: " .. battleId)
    return battleId
end

------------------------------------------------------------------------
-- REQUEST ACTIONS
------------------------------------------------------------------------

function BattleEngine._requestActions(battleId: string)
    local battle = activeBattles[battleId]
    if not battle or battle.status == "finished" then
        return
    end

    battle.turnNumber = battle.turnNumber + 1
    battle.status = "waiting_action"
    battle.pendingActions = {}

    -- Clear defend flags from previous turn
    battle.isDefending = {}

    -- Request action from player
    local playerSide = battle.sides[1]
    if playerSide.owner then
        local activeCreature = getActiveCreature(battle, 1)
        Remotes.BattleRequestAction:FireClient(playerSide.owner, {
            battleId = battleId,
            turnNumber = battle.turnNumber,
            activeCreature = creatureSnapshot(activeCreature),
            party = sideSnapshot(playerSide),
        })
    end

    -- AI picks action immediately
    local aiAction = BattleAI.chooseAction(battle, 2)
    battle.pendingActions[2] = aiAction
end

------------------------------------------------------------------------
-- SUBMIT ACTION (from client)
------------------------------------------------------------------------

function BattleEngine.submitAction(player: Player, data: any)
    local battleId = playerBattleMap[player.UserId]
    if not battleId then
        return
    end

    local battle = activeBattles[battleId]
    if not battle or battle.status ~= "waiting_action" then
        return
    end

    -- Validate this player owns side 1
    if battle.sides[1].owner ~= player then
        return
    end

    -- Store the action
    local action = {
        actionType = data.actionType,
        moveId = data.moveId,
        itemId = data.itemId,
        targetIndex = data.targetIndex or 1,
        switchIndex = data.switchIndex,
    }

    battle.pendingActions[1] = action

    -- Check if both sides have submitted
    if battle.pendingActions[1] and battle.pendingActions[2] then
        BattleEngine._resolveTurn(battleId)
    end
end

------------------------------------------------------------------------
-- RESOLVE TURN
------------------------------------------------------------------------

function BattleEngine._resolveTurn(battleId: string)
    local battle = activeBattles[battleId]
    if not battle then
        return
    end

    battle.status = "resolving"

    -- Build action list with side info
    local actions = {}
    for sideIndex = 1, 2 do
        local action = battle.pendingActions[sideIndex]
        if action then
            local activeCreature = getActiveCreature(battle, sideIndex)
            local stages = getStatStages(battle, activeCreature.uid)
            table.insert(actions, {
                sideIndex = sideIndex,
                action = action,
                creature = activeCreature,
                speed = getEffectiveSpeed(activeCreature, stages),
                priority = BattleConstants.ACTION_PRIORITY[action.actionType] or 1,
            })
        end
    end

    -- Sort by priority (descending), then speed (descending), then random tiebreak
    table.sort(actions, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        if a.speed ~= b.speed then
            return a.speed > b.speed
        end
        return math.random() > 0.5
    end)

    -- Execute actions in order, collecting events
    local events: { any } = {}

    for _, entry in actions do
        -- Skip if this creature has fainted mid-turn
        local creature = getActiveCreature(battle, entry.sideIndex)
        if creature.currentHp <= 0 then
            continue
        end

        local action = entry.action

        if action.actionType == "defend" then
            BattleEngine._executeDefend(battle, entry.sideIndex, events)
        elseif action.actionType == "switch" then
            BattleEngine._executeSwitch(battle, entry.sideIndex, action.switchIndex, events)
        elseif action.actionType == "attack" or action.actionType == "skill" then
            BattleEngine._executeMove(battle, entry.sideIndex, action.moveId, events)
        elseif action.actionType == "item" then
            BattleEngine._executeItem(battle, entry.sideIndex, action.itemId, events)
        end

        -- Check for faints after each action
        local faintResult = BattleEngine._checkFaints(battle, events)
        if faintResult == "battle_over" then
            break
        end
    end

    -- Build turn result
    local turnResult = {
        turnNumber = battle.turnNumber,
        events = events,
        sides = {},
    }

    for sideIndex = 1, 2 do
        local active = getActiveCreature(battle, sideIndex)
        turnResult.sides[sideIndex] = {
            activeIndex = battle.sides[sideIndex].activeIndex,
            currentHp = active.currentHp,
            maxHp = active.maxHp,
            currentMp = active.currentMp,
            maxMp = active.maxMp,
        }
    end

    -- Send result to player
    local player = battle.sides[1].owner
    if player then
        Remotes.BattleTurnResult:FireClient(player, turnResult)
    end

    -- Handle post-turn: check if battle should end or continue
    task.defer(function()
        if battle.status == "finished" then
            return
        end

        -- Check if any side needs a forced switch (creature fainted but has more)
        local needsSwitch = false
        for sideIndex = 1, 2 do
            local active = getActiveCreature(battle, sideIndex)
            if active.currentHp <= 0 then
                local hasAlive = BattleEngine._sideHasAlive(battle, sideIndex)
                if hasAlive then
                    if sideIndex == 1 and player then
                        -- Player needs to pick a replacement
                        needsSwitch = true
                        Remotes.BattleCreatureFainted:FireClient(player, {
                            battleId = battleId,
                            party = sideSnapshot(battle.sides[1]),
                        })
                    else
                        -- AI auto-switches to first alive
                        local newIndex = BattleEngine._getFirstAliveIndex(battle, sideIndex)
                        if newIndex then
                            battle.sides[sideIndex].activeIndex = newIndex
                        end
                    end
                end
            end
        end

        -- If no switch needed, continue to next turn
        if not needsSwitch and battle.status ~= "finished" then
            task.wait(0.5)  -- Brief pause between turns
            BattleEngine._requestActions(battleId)
        end
    end)
end

------------------------------------------------------------------------
-- EXECUTE: Move (Attack or Skill)
------------------------------------------------------------------------

function BattleEngine._executeMove(battle: any, sideIndex: number, moveId: string, events: { any })
    local attacker = getActiveCreature(battle, sideIndex)
    local defenderSideIndex = sideIndex == 1 and 2 or 1
    local defender = getActiveCreature(battle, defenderSideIndex)

    local move = MoveDatabase.getMove(moveId)
    if not move then
        -- Fallback to tackle
        move = MoveDatabase.getMove("tackle")
    end

    -- Check MP cost
    if move.mpCost > 0 and attacker.currentMp < move.mpCost then
        -- Not enough MP — fallback to tackle
        table.insert(events, {
            eventType = "no_mp",
            sourceSide = sideIndex,
            sourceCreatureName = attacker.speciesId,
            moveName = move.name,
            message = attacker.speciesId .. " doesn't have enough MP for " .. move.name .. "!",
        })
        move = MoveDatabase.getMove("tackle")
    end

    -- Deduct MP
    if move.mpCost > 0 then
        local mpBefore = attacker.currentMp
        attacker.currentMp = math.max(0, attacker.currentMp - move.mpCost)
        table.insert(events, {
            eventType = "mp_used",
            sourceSide = sideIndex,
            sourceCreatureName = attacker.speciesId,
            mpBefore = mpBefore,
            mpAfter = attacker.currentMp,
        })
    end

    -- Status moves apply effects instead of dealing damage
    if move.category == "Status" then
        BattleEngine._executeStatusMove(battle, sideIndex, move, events)
        return
    end

    -- Accuracy check
    if not DamageCalculator.rollAccuracy(move) then
        table.insert(events, {
            eventType = "miss",
            sourceSide = sideIndex,
            sourceCreatureName = attacker.speciesId,
            moveName = move.name,
            message = attacker.speciesId .. "'s " .. move.name .. " missed!",
        })
        return
    end

    -- Calculate damage
    local attackerStages = getStatStages(battle, attacker.uid)
    local defenderStages = getStatStages(battle, defender.uid)
    local isDefending = battle.isDefending[defender.uid] or false

    local result = DamageCalculator.calculateDamage(attacker, defender, move, {
        attackerStages = attackerStages,
        defenderStages = defenderStages,
        isDefending = isDefending,
    })

    -- Apply damage
    local hpBefore = defender.currentHp
    defender.currentHp = math.max(0, defender.currentHp - result.damage)

    -- Build event
    local event: any = {
        eventType = "damage",
        sourceSide = sideIndex,
        sourceCreatureName = attacker.speciesId,
        targetSide = defenderSideIndex,
        targetCreatureName = defender.speciesId,
        moveName = move.name,
        moveElement = move.element,
        damage = result.damage,
        effectiveness = result.effectiveness,
        isSTAB = result.isSTAB,
        hpBefore = hpBefore,
        hpAfter = defender.currentHp,
        message = attacker.speciesId .. " used " .. move.name .. "!",
    }

    table.insert(events, event)

    -- Effectiveness message
    local effLabel = ElementTypes.getEffectivenessLabel(result.effectiveness)
    if effLabel ~= "" then
        table.insert(events, {
            eventType = "effectiveness",
            message = effLabel,
        })
    end

    -- Faint check
    if defender.currentHp <= 0 then
        table.insert(events, {
            eventType = "faint",
            targetSide = defenderSideIndex,
            targetCreatureName = defender.speciesId,
            fainted = true,
            message = defender.speciesId .. " fainted!",
        })
    end
end

------------------------------------------------------------------------
-- EXECUTE: Status Move
------------------------------------------------------------------------

function BattleEngine._executeStatusMove(battle: any, sideIndex: number, move: any, events: { any })
    local user = getActiveCreature(battle, sideIndex)
    local effect = move.effect
    if not effect then
        return
    end

    -- Announce move usage
    table.insert(events, {
        eventType = "status_move",
        sourceSide = sideIndex,
        sourceCreatureName = user.speciesId,
        moveName = move.name,
        message = user.speciesId .. " used " .. move.name .. "!",
    })

    local targetSideIndex = sideIndex
    local targetCreature = user
    if effect.target == "opponent" then
        targetSideIndex = sideIndex == 1 and 2 or 1
        targetCreature = getActiveCreature(battle, targetSideIndex)
    end

    local stages = getStatStages(battle, targetCreature.uid)

    if effect.effectType == "boostStat" and effect.stat then
        local oldStage = stages[effect.stat] or 0
        local newStage = math.clamp(oldStage + (effect.stages or 1),
            BattleConstants.MIN_STAT_STAGE, BattleConstants.MAX_STAT_STAGE)
        stages[effect.stat] = newStage

        local change = newStage - oldStage
        local label = change > 0 and "rose" or "can't go any higher"
        if change > 1 then label = "sharply rose" end

        table.insert(events, {
            eventType = "stat_change",
            targetSide = targetSideIndex,
            targetCreatureName = targetCreature.speciesId,
            statName = effect.stat,
            stages = change,
            message = targetCreature.speciesId .. "'s " .. effect.stat .. " " .. label .. "!",
        })

    elseif effect.effectType == "lowerStat" and effect.stat then
        local oldStage = stages[effect.stat] or 0
        local newStage = math.clamp(oldStage - (effect.stages or 1),
            BattleConstants.MIN_STAT_STAGE, BattleConstants.MAX_STAT_STAGE)
        stages[effect.stat] = newStage

        local change = oldStage - newStage
        local label = change > 0 and "fell" or "can't go any lower"
        if change > 1 then label = "sharply fell" end

        table.insert(events, {
            eventType = "stat_change",
            targetSide = targetSideIndex,
            targetCreatureName = targetCreature.speciesId,
            statName = effect.stat,
            stages = -change,
            message = targetCreature.speciesId .. "'s " .. effect.stat .. " " .. label .. "!",
        })
    end
end

------------------------------------------------------------------------
-- EXECUTE: Defend
------------------------------------------------------------------------

function BattleEngine._executeDefend(battle: any, sideIndex: number, events: { any })
    local creature = getActiveCreature(battle, sideIndex)
    battle.isDefending[creature.uid] = true

    table.insert(events, {
        eventType = "defend",
        sourceSide = sideIndex,
        sourceCreatureName = creature.speciesId,
        message = creature.speciesId .. " braced for impact!",
    })
end

------------------------------------------------------------------------
-- EXECUTE: Switch
------------------------------------------------------------------------

function BattleEngine._executeSwitch(battle: any, sideIndex: number, newIndex: number, events: { any })
    local side = battle.sides[sideIndex]
    local oldCreature = getActiveCreature(battle, sideIndex)

    -- Validate new index
    if newIndex < 1 or newIndex > #side.creatures then
        return
    end
    local newCreature = side.creatures[newIndex]
    if newCreature.currentHp <= 0 then
        return
    end
    if newIndex == side.activeIndex then
        return
    end

    -- Clear stat stages for the old creature
    battle.statStages[oldCreature.uid] = nil
    battle.isDefending[oldCreature.uid] = nil

    side.activeIndex = newIndex

    table.insert(events, {
        eventType = "switch",
        sourceSide = sideIndex,
        sourceCreatureName = oldCreature.speciesId,
        switchedTo = newCreature.speciesId,
        message = oldCreature.speciesId .. " was withdrawn! Go, " .. newCreature.speciesId .. "!",
    })
end

------------------------------------------------------------------------
-- EXECUTE: Item
------------------------------------------------------------------------

function BattleEngine._executeItem(battle: any, sideIndex: number, itemId: string, events: { any })
    local side = battle.sides[sideIndex]
    local creature = getActiveCreature(battle, sideIndex)
    local player = side.owner

    local item = ItemDatabase.getItem(itemId)
    if not item then
        return
    end

    -- Only player side can use items
    if not player then
        return
    end

    -- Check inventory
    if PlayerDataManager.getItemCount(player, itemId) <= 0 then
        table.insert(events, {
            eventType = "item_fail",
            sourceSide = sideIndex,
            itemName = item.name,
            message = "No " .. item.name .. " left!",
        })
        return
    end

    -- Consume item
    PlayerDataManager.removeItem(player, itemId)

    -- Handle capture orb
    if item.effect.capture then
        if not battle.isWild then
            table.insert(events, {
                eventType = "item_fail",
                sourceSide = sideIndex,
                itemName = item.name,
                message = "Can't capture a trainer's creature!",
            })
            return
        end

        local captureResult = CaptureSystem.attemptCapture(player, battle)
        table.insert(events, {
            eventType = "capture_attempt",
            sourceSide = sideIndex,
            targetSide = 2,
            targetCreatureName = getActiveCreature(battle, 2).speciesId,
            itemName = item.name,
            captureSuccess = captureResult.success,
            captureChance = captureResult.chance,
            message = captureResult.success
                and "Gotcha! " .. getActiveCreature(battle, 2).speciesId .. " was captured!"
                or "Oh no! " .. getActiveCreature(battle, 2).speciesId .. " broke free!",
        })

        if captureResult.success then
            BattleEngine._endBattle(battle, "captured")
        end
        return
    end

    -- Healing items
    if item.effect.restoreHp then
        local hpBefore = creature.currentHp
        creature.currentHp = math.min(creature.maxHp, creature.currentHp + item.effect.restoreHp)
        table.insert(events, {
            eventType = "heal",
            sourceSide = sideIndex,
            sourceCreatureName = creature.speciesId,
            itemName = item.name,
            hpBefore = hpBefore,
            hpAfter = creature.currentHp,
            message = creature.speciesId .. " recovered HP with " .. item.name .. "!",
        })
    end

    if item.effect.restoreMp then
        local mpBefore = creature.currentMp
        creature.currentMp = math.min(creature.maxMp, creature.currentMp + item.effect.restoreMp)
        table.insert(events, {
            eventType = "mp_heal",
            sourceSide = sideIndex,
            sourceCreatureName = creature.speciesId,
            itemName = item.name,
            mpBefore = mpBefore,
            mpAfter = creature.currentMp,
            message = creature.speciesId .. " recovered MP with " .. item.name .. "!",
        })
    end

    -- Stat boost items
    if item.effect.boostStat then
        local stages = getStatStages(battle, creature.uid)
        local stat = item.effect.boostStat
        local oldStage = stages[stat] or 0
        local newStage = math.clamp(oldStage + (item.effect.stages or 1),
            BattleConstants.MIN_STAT_STAGE, BattleConstants.MAX_STAT_STAGE)
        stages[stat] = newStage

        table.insert(events, {
            eventType = "stat_change",
            sourceSide = sideIndex,
            sourceCreatureName = creature.speciesId,
            itemName = item.name,
            statName = stat,
            stages = newStage - oldStage,
            message = creature.speciesId .. "'s " .. stat .. " rose using " .. item.name .. "!",
        })
    end
end

------------------------------------------------------------------------
-- FAINT CHECKING
------------------------------------------------------------------------

function BattleEngine._checkFaints(battle: any, events: { any }): string
    for sideIndex = 1, 2 do
        local active = getActiveCreature(battle, sideIndex)
        if active.currentHp <= 0 then
            local hasAlive = BattleEngine._sideHasAlive(battle, sideIndex)
            if not hasAlive then
                -- This side is fully wiped out
                local winnerSide = sideIndex == 1 and 2 or 1
                local outcome = winnerSide == 1 and "win" or "lose"
                BattleEngine._endBattle(battle, outcome)
                return "battle_over"
            end
        end
    end
    return "continue"
end

function BattleEngine._sideHasAlive(battle: any, sideIndex: number): boolean
    local side = battle.sides[sideIndex]
    for _, creature in side.creatures do
        if creature.currentHp > 0 then
            return true
        end
    end
    return false
end

function BattleEngine._getFirstAliveIndex(battle: any, sideIndex: number): number?
    local side = battle.sides[sideIndex]
    for i, creature in side.creatures do
        if creature.currentHp > 0 then
            return i
        end
    end
    return nil
end

------------------------------------------------------------------------
-- FORCED SWITCH (after faint, from client)
------------------------------------------------------------------------

function BattleEngine.handleForcedSwitch(player: Player, data: any)
    local battleId = playerBattleMap[player.UserId]
    if not battleId then
        return
    end

    local battle = activeBattles[battleId]
    if not battle then
        return
    end

    local sideIndex = 1  -- Player is always side 1
    local switchIndex = data.switchIndex

    -- Validate
    local side = battle.sides[sideIndex]
    if switchIndex < 1 or switchIndex > #side.creatures then
        return
    end
    if side.creatures[switchIndex].currentHp <= 0 then
        return
    end

    -- Clear old creature's stages
    local oldCreature = getActiveCreature(battle, sideIndex)
    battle.statStages[oldCreature.uid] = nil

    side.activeIndex = switchIndex
    local newCreature = getActiveCreature(battle, sideIndex)

    -- Notify client of the switch
    Remotes.BattleTurnResult:FireClient(player, {
        turnNumber = battle.turnNumber,
        events = {
            {
                eventType = "switch",
                sourceSide = sideIndex,
                sourceCreatureName = oldCreature.speciesId,
                switchedTo = newCreature.speciesId,
                message = "Go, " .. newCreature.speciesId .. "!",
            },
        },
        sides = {
            [1] = {
                activeIndex = battle.sides[1].activeIndex,
                currentHp = getActiveCreature(battle, 1).currentHp,
                maxHp = getActiveCreature(battle, 1).maxHp,
                currentMp = getActiveCreature(battle, 1).currentMp,
                maxMp = getActiveCreature(battle, 1).maxMp,
            },
            [2] = {
                activeIndex = battle.sides[2].activeIndex,
                currentHp = getActiveCreature(battle, 2).currentHp,
                maxHp = getActiveCreature(battle, 2).maxHp,
                currentMp = getActiveCreature(battle, 2).currentMp,
                maxMp = getActiveCreature(battle, 2).maxMp,
            },
        },
    })

    -- Also check if AI side needs to switch
    local aiActive = getActiveCreature(battle, 2)
    if aiActive.currentHp <= 0 then
        local aiAlive = BattleEngine._getFirstAliveIndex(battle, 2)
        if aiAlive then
            battle.sides[2].activeIndex = aiAlive
        end
    end

    -- Continue to next turn
    task.wait(0.5)
    BattleEngine._requestActions(battleId)
end

------------------------------------------------------------------------
-- END BATTLE
------------------------------------------------------------------------

function BattleEngine._endBattle(battle: any, outcome: string)
    if battle.status == "finished" then
        return
    end
    battle.status = "finished"

    local player = battle.sides[1].owner
    if not player then
        BattleEngine._cleanup(battle)
        return
    end

    local endResult: any = {
        outcome = outcome,
        xpGained = 0,
        levelsGained = 0,
        newMoves = {},
        capturedCreature = nil,
    }

    -- Handle win rewards
    if outcome == "win" then
        -- Award XP to the active creature
        local activeCreature = getActiveCreature(battle, 1)
        local defeatedCreature = getActiveCreature(battle, 2)

        if activeCreature.currentHp > 0 then
            local levelResult = LevelingSystem.awardXP(activeCreature, defeatedCreature.level)
            endResult.xpGained = levelResult.xpGained
            endResult.levelsGained = levelResult.levelsGained
            endResult.newMoves = levelResult.newMoves or {}

            -- Sync creature back to player data
            PlayerDataManager.updateCreature(player, activeCreature)

            if levelResult.levelsGained > 0 then
                Remotes.CreatureLevelUp:FireClient(player, {
                    creatureUid = activeCreature.uid,
                    newLevel = activeCreature.level,
                    stats = activeCreature.stats,
                    newMoves = levelResult.newMoves,
                })
            end
        end
    elseif outcome == "lose" then
        -- Mercy rule: set all fainted creatures to 1 HP
        PlayerDataManager.applyMercyRule(player)
    elseif outcome == "captured" then
        -- Creature already added to party by CaptureSystem
        local capturedCreature = getActiveCreature(battle, 2)
        endResult.capturedCreature = creatureSnapshot(capturedCreature)
    end

    -- Update all player creatures from battle back to player data
    for _, creature in battle.sides[1].creatures do
        PlayerDataManager.updateCreature(player, creature)
    end

    -- Fire end event
    Remotes.BattleEnd:FireClient(player, endResult)

    -- Cleanup
    BattleEngine._cleanup(battle)

    print("[BattleEngine] Battle ended: " .. battle.id .. " → " .. outcome)
end

------------------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------------------

function BattleEngine._cleanup(battle: any)
    local player = battle.sides[1].owner
    if player then
        playerBattleMap[player.UserId] = nil
    end
    activeBattles[battle.id] = nil
end

------------------------------------------------------------------------
-- QUERIES
------------------------------------------------------------------------

--- Get the active battle ID for a player (nil if not in battle).
function BattleEngine.getActiveBattleId(player: Player): string?
    return playerBattleMap[player.UserId]
end

--- Check if a player is currently in a battle.
function BattleEngine.isInBattle(player: Player): boolean
    return playerBattleMap[player.UserId] ~= nil
end

------------------------------------------------------------------------
-- INITIALIZATION (wire remotes)
------------------------------------------------------------------------

function BattleEngine.init()
    ensureDependencies()

    -- Player submits an action
    Remotes.BattleSubmitAction.OnServerEvent:Connect(function(player: Player, data: any)
        BattleEngine.submitAction(player, data)
    end)

    -- Player picks a replacement after faint
    Remotes.BattleSwitchCreature.OnServerEvent:Connect(function(player: Player, data: any)
        BattleEngine.handleForcedSwitch(player, data)
    end)

    print("[BattleEngine] Initialized")
end

return BattleEngine
