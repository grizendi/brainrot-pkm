--[[
    BattleAI.luau  (Server module)
    Simple AI for wild creature decision-making.

    Behavior:
        1. Gather all affordable moves (MP check)
        2. If any move is super-effective vs opponent, 60% chance to pick it
        3. Otherwise pick a random affordable damaging move
        4. If no moves are affordable, use Tackle (free)
        5. Wild creatures never use items, never switch
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local MoveDatabase = require(Shared:WaitForChild("MoveDatabase"))
local ElementTypes = require(Shared:WaitForChild("ElementTypes"))

local BattleAI = {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

-- Chance to pick a super-effective move when one is available
local SUPER_EFFECTIVE_BIAS = 0.60

------------------------------------------------------------------------
-- Core: choose an action for the AI side
------------------------------------------------------------------------

--[[
    Choose a battle action for the AI-controlled side.

    @param battle BattleState — current battle state
    @param sideIndex number — which side the AI controls (typically 2)
    @return BattleAction table
]]
function BattleAI.chooseAction(battle: any, sideIndex: number): any
    local side = battle.sides[sideIndex]
    local creature = side.creatures[side.activeIndex]
    local opponentSideIndex = sideIndex == 1 and 2 or 1
    local opponent = battle.sides[opponentSideIndex].creatures[battle.sides[opponentSideIndex].activeIndex]

    -- Gather affordable moves
    local affordableMoves = {}
    local superEffectiveMoves = {}

    for _, moveId in creature.moves do
        local move = MoveDatabase.getMove(moveId)
        if move then
            -- Check if creature can afford the MP cost
            if move.mpCost <= creature.currentMp then
                table.insert(affordableMoves, moveId)

                -- Check if it's super effective against the opponent
                if move.power > 0 then
                    local effectiveness = ElementTypes.getEffectiveness(move.element, opponent.element)
                    if effectiveness >= 2.0 then
                        table.insert(superEffectiveMoves, moveId)
                    end
                end
            end
        end
    end

    -- Decision logic
    local chosenMoveId: string

    if #superEffectiveMoves > 0 and math.random() < SUPER_EFFECTIVE_BIAS then
        -- Bias toward super-effective moves
        chosenMoveId = superEffectiveMoves[math.random(1, #superEffectiveMoves)]
    elseif #affordableMoves > 0 then
        -- Pick a random affordable move, biased toward damaging moves
        local damagingMoves = {}
        for _, moveId in affordableMoves do
            local move = MoveDatabase.getMove(moveId)
            if move and move.power > 0 then
                table.insert(damagingMoves, moveId)
            end
        end

        if #damagingMoves > 0 then
            -- 80% chance to use a damaging move, 20% chance for any move (including status)
            if math.random() < 0.80 or #affordableMoves == #damagingMoves then
                chosenMoveId = damagingMoves[math.random(1, #damagingMoves)]
            else
                chosenMoveId = affordableMoves[math.random(1, #affordableMoves)]
            end
        else
            -- Only status moves available — pick one or fallback to tackle
            chosenMoveId = affordableMoves[math.random(1, #affordableMoves)]
        end
    else
        -- No affordable moves at all — use Tackle (free)
        chosenMoveId = "tackle"
    end

    -- Determine action type based on move category
    local move = MoveDatabase.getMove(chosenMoveId)
    local actionType = "attack"
    if move and (move.category == "Special" or move.category == "Status") then
        actionType = "skill"
    end

    return {
        actionType = actionType,
        moveId = chosenMoveId,
        itemId = nil,
        targetIndex = 1,
        switchIndex = nil,
    }
end

return BattleAI
