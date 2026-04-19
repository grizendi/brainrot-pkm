--[[
    BattleController.luau  (Client module)
    Wires the BattleUI components to server RemoteEvents.

    Handles:
        - Receiving BattleStart and setting up the UI
        - Wiring action menu callbacks to BattleSubmitAction
        - Receiving BattleTurnResult and animating the log + HP/MP bars
        - Receiving BattleCreatureFainted and showing forced switch
        - Receiving BattleEnd and tearing down UI
        - Encounter transition overlay
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for server to create remotes folder
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not RemotesFolder then
    warn("[BattleController] Remotes folder not found!")
    return
end

-- Get remotes
local BattleStart = RemotesFolder:WaitForChild("BattleStart")
local BattleRequestAction = RemotesFolder:WaitForChild("BattleRequestAction")
local BattleSubmitAction = RemotesFolder:WaitForChild("BattleSubmitAction")
local BattleTurnResult = RemotesFolder:WaitForChild("BattleTurnResult")
local BattleCreatureFainted = RemotesFolder:WaitForChild("BattleCreatureFainted")
local BattleSwitchCreature = RemotesFolder:WaitForChild("BattleSwitchCreature")
local BattleEnd = RemotesFolder:WaitForChild("BattleEnd")
local EncounterTriggered = RemotesFolder:WaitForChild("EncounterTriggered")
local GetPlayerData = RemotesFolder:WaitForChild("GetPlayerData")

-- UI modules
local uiFolder = script.Parent:WaitForChild("ui")
local BattleUI = require(uiFolder:WaitForChild("BattleUI"))
local UIConstants = require(uiFolder:WaitForChild("UIConstants"))

local BattleController = {}

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

local battleUI = nil         -- BattleUI instance
local currentBattleId = nil
local playerData = nil       -- cached from server
local playerSide = nil       -- creature data for our side
local opponentSide = nil     -- creature data for opponent side
local inBattle = false

------------------------------------------------------------------------
-- Encounter transition overlay
------------------------------------------------------------------------

local function showEncounterTransition(encounterData: any, callback: () -> ())
    local transitionGui = Instance.new("ScreenGui")
    transitionGui.Name = "EncounterTransition"
    transitionGui.ResetOnSpawn = false
    transitionGui.DisplayOrder = 200
    transitionGui.IgnoreGuiInset = true
    transitionGui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Name = "TransitionBg"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = UIConstants.Colors.TransitionBg
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Parent = transitionGui

    -- Text
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 50)
    label.Position = UDim2.new(0.5, 0, 0.5, 0)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.BackgroundTransparency = 1
    label.Text = "A wild " .. encounterData.speciesId .. " (Lv." .. encounterData.level .. ") appeared!"
    label.TextColor3 = UIConstants.Colors.TextPrimary
    label.Font = UIConstants.Font.Header
    label.TextSize = 28
    label.TextTransparency = 1
    label.Parent = bg

    -- Fade in
    local fadeIn = TweenService:Create(bg, TweenInfo.new(UIConstants.Anim.TransitionIn), {
        BackgroundTransparency = 0,
    })
    local textFadeIn = TweenService:Create(label, TweenInfo.new(UIConstants.Anim.TransitionIn), {
        TextTransparency = 0,
    })

    fadeIn:Play()
    textFadeIn:Play()

    task.wait(UIConstants.Anim.TransitionIn + UIConstants.Anim.TransitionHold)

    -- Fade out
    local fadeOut = TweenService:Create(bg, TweenInfo.new(UIConstants.Anim.TransitionOut), {
        BackgroundTransparency = 1,
    })
    local textFadeOut = TweenService:Create(label, TweenInfo.new(UIConstants.Anim.TransitionOut), {
        TextTransparency = 1,
    })

    fadeOut:Play()
    textFadeOut:Play()
    fadeOut.Completed:Wait()

    transitionGui:Destroy()

    if callback then
        callback()
    end
end

------------------------------------------------------------------------
-- Wire action menu callbacks
------------------------------------------------------------------------

local function wireActionCallbacks()
    if not battleUI then return end

    local actionMenu = battleUI:getActionMenu()
    local moveSelectUI = battleUI:getMoveSelectUI()
    local itemSelectUI = battleUI:getItemSelectUI()
    local switchUI = battleUI:getSwitchUI()
    local activeCreature = playerSide.creatures[playerSide.activeIndex]

    -- Main action menu buttons
    actionMenu:setCallbacks({
        onAttack = function()
            -- Show physical moves
            actionMenu:hide()
            moveSelectUI:showMoves(activeCreature.moves, activeCreature.currentMp, "Attack")
        end,

        onDefend = function()
            -- Defend immediately
            battleUI:disableInput()
            BattleSubmitAction:FireServer({
                actionType = "defend",
            })
        end,

        onSkills = function()
            -- Show special/status moves
            actionMenu:hide()
            moveSelectUI:showMoves(activeCreature.moves, activeCreature.currentMp, "Skills")
        end,

        onItems = function()
            -- Fetch latest inventory from server
            local data = GetPlayerData:InvokeServer()
            if data and data.inventory then
                actionMenu:hide()
                itemSelectUI:showItems(data.inventory)
            end
        end,

        onSwitch = function()
            -- Show party
            actionMenu:hide()
            switchUI:showParty(playerSide.creatures, playerSide.activeIndex, false)
        end,
    })

    -- Move selection callbacks
    moveSelectUI.onMoveSelected = function(moveId: string, category: string)
        battleUI:disableInput()
        local actionType = category == "Physical" and "attack" or "skill"
        BattleSubmitAction:FireServer({
            actionType = actionType,
            moveId = moveId,
        })
    end

    moveSelectUI.onBack = function()
        moveSelectUI:hide()
        battleUI:showActionMenu()
    end

    -- Item selection callbacks
    itemSelectUI.onItemSelected = function(itemId: string)
        battleUI:disableInput()
        BattleSubmitAction:FireServer({
            actionType = "item",
            itemId = itemId,
        })
    end

    itemSelectUI.onBack = function()
        itemSelectUI:hide()
        battleUI:showActionMenu()
    end

    -- Switch callbacks
    switchUI.onCreatureSelected = function(index: number)
        battleUI:disableInput()
        BattleSubmitAction:FireServer({
            actionType = "switch",
            switchIndex = index,
        })
    end

    switchUI.onBack = function()
        switchUI:hide()
        battleUI:showActionMenu()
    end
end

------------------------------------------------------------------------
-- Process turn result events
------------------------------------------------------------------------

local function processTurnEvents(turnResult: any)
    if not battleUI then return end

    local log = battleUI:getBattleLog()
    local enemyHUD = battleUI:getEnemyHUD()
    local playerHUD = battleUI:getPlayerHUD()

    for _, event in turnResult.events do
        local msg = event.message or ""

        if event.eventType == "damage" then
            log:addTypedMessage(msg, "damage")
            task.wait(UIConstants.Anim.MessageDelay)

        elseif event.eventType == "effectiveness" then
            local effType = nil
            if string.find(msg, "super effective") then
                effType = "super_effective"
            elseif string.find(msg, "not very") then
                effType = "not_effective"
            end
            log:addTypedMessage(msg, effType)
            task.wait(UIConstants.Anim.MessageDelay * 0.5)

        elseif event.eventType == "faint" then
            log:addTypedMessage(msg, "damage")
            task.wait(UIConstants.Anim.MessageDelay)

        elseif event.eventType == "miss" then
            log:addMessage(msg)
            task.wait(UIConstants.Anim.MessageDelay)

        elseif event.eventType == "no_mp" then
            log:addTypedMessage(msg, "not_effective")
            task.wait(UIConstants.Anim.MessageDelay * 0.5)

        elseif event.eventType == "defend" then
            log:addMessage(msg)
            task.wait(UIConstants.Anim.MessageDelay * 0.5)

        elseif event.eventType == "switch" then
            log:addTypedMessage(msg, "highlight")
            task.wait(UIConstants.Anim.MessageDelay)

        elseif event.eventType == "heal" or event.eventType == "mp_heal" then
            log:addTypedMessage(msg, "heal")
            task.wait(UIConstants.Anim.MessageDelay)

        elseif event.eventType == "stat_change" then
            local changeType = (event.stages and event.stages > 0) and "heal" or "damage"
            log:addTypedMessage(msg, changeType)
            task.wait(UIConstants.Anim.MessageDelay * 0.5)

        elseif event.eventType == "status_move" then
            log:addMessage(msg)
            task.wait(UIConstants.Anim.MessageDelay * 0.5)

        elseif event.eventType == "capture_attempt" then
            log:addTypedMessage(msg, event.captureSuccess and "highlight" or "damage")
            task.wait(UIConstants.Anim.MessageDelay)

        elseif event.eventType == "mp_used" then
            -- Silent — just update bar
        elseif event.eventType == "item_fail" then
            log:addTypedMessage(msg, "not_effective")
            task.wait(UIConstants.Anim.MessageDelay)
        else
            if msg ~= "" then
                log:addMessage(msg)
                task.wait(UIConstants.Anim.MessageDelay * 0.5)
            end
        end
    end

    -- Update HP/MP bars from turn result
    if turnResult.sides then
        local pSide = turnResult.sides[1]
        local eSide = turnResult.sides[2]

        if pSide then
            playerSide.activeIndex = pSide.activeIndex
            local pc = playerSide.creatures[pSide.activeIndex]
            if pc then
                pc.currentHp = pSide.currentHp
                pc.maxHp = pSide.maxHp
                pc.currentMp = pSide.currentMp
                pc.maxMp = pSide.maxMp
                playerHUD:updateHP(pSide.currentHp, pSide.maxHp, true)
                playerHUD:updateMP(pSide.currentMp, pSide.maxMp, true)
            end
        end

        if eSide then
            opponentSide.activeIndex = eSide.activeIndex
            local ec = opponentSide.creatures[eSide.activeIndex]
            if ec then
                ec.currentHp = eSide.currentHp
                ec.maxHp = eSide.maxHp
                ec.currentMp = eSide.currentMp
                ec.maxMp = eSide.maxMp
                enemyHUD:updateHP(eSide.currentHp, eSide.maxHp, true)
                enemyHUD:updateMP(eSide.currentMp, eSide.maxMp, true)
            end
        end
    end
end

------------------------------------------------------------------------
-- Remote event handlers
------------------------------------------------------------------------

-- Encounter triggered: show transition overlay
EncounterTriggered.OnClientEvent:Connect(function(data)
    showEncounterTransition(data, function() end)
end)

-- Battle starts
BattleStart.OnClientEvent:Connect(function(data)
    currentBattleId = data.battleId
    playerSide = data.playerSide
    opponentSide = data.opponentSide
    inBattle = true

    -- Create the battle UI
    if battleUI then
        battleUI:destroy()
    end
    battleUI = BattleUI.new()

    -- Set creature info on HUDs
    local playerCreature = playerSide.creatures[playerSide.activeIndex]
    local enemyCreature = opponentSide.creatures[opponentSide.activeIndex]

    battleUI:getPlayerHUD():setCreature(playerCreature)
    battleUI:getEnemyHUD():setCreature(enemyCreature)

    -- Show the battle UI
    battleUI:show()
    battleUI:disableInput() -- wait for action request

    local log = battleUI:getBattleLog()
    log:addTypedMessage("Battle started!", "highlight")
    log:addMessage("Wild " .. enemyCreature.speciesId .. " Lv." .. enemyCreature.level .. " appeared!")
end)

-- Server requests an action from us
BattleRequestAction.OnClientEvent:Connect(function(data)
    if not battleUI or not inBattle then return end

    -- Update active creature data
    if data.activeCreature then
        local idx = playerSide.activeIndex
        playerSide.creatures[idx] = data.activeCreature
    end

    -- Refresh player HUD
    local activeCreature = playerSide.creatures[playerSide.activeIndex]
    battleUI:getPlayerHUD():setCreature(activeCreature)

    -- Also update enemy HUD after any switches
    local enemyCreature = opponentSide.creatures[opponentSide.activeIndex]
    battleUI:getEnemyHUD():setCreature(enemyCreature)

    -- Show action menu and wire callbacks
    wireActionCallbacks()
    battleUI:showActionMenu()
end)

-- Turn result received
BattleTurnResult.OnClientEvent:Connect(function(turnResult)
    if not battleUI or not inBattle then return end

    battleUI:disableInput()

    -- Process events in a coroutine so we can use task.wait
    task.spawn(function()
        processTurnEvents(turnResult)

        -- After processing, update HUDs with latest data
        local playerCreature = playerSide.creatures[playerSide.activeIndex]
        local enemyCreature = opponentSide.creatures[opponentSide.activeIndex]

        if playerCreature then
            battleUI:getPlayerHUD():setCreature(playerCreature)
        end
        if enemyCreature then
            battleUI:getEnemyHUD():setCreature(enemyCreature)
        end
    end)
end)

-- Creature fainted — forced switch
BattleCreatureFainted.OnClientEvent:Connect(function(data)
    if not battleUI or not inBattle then return end

    -- Update party data
    if data.party then
        playerSide = data.party
    end

    -- Show forced switch UI
    local switchUI = battleUI:getSwitchUI()
    switchUI.onCreatureSelected = function(index: number)
        battleUI:disableInput()
        BattleSwitchCreature:FireServer({
            switchIndex = index,
        })
    end

    battleUI:showForcedSwitch(playerSide.creatures, playerSide.activeIndex)
end)

-- Battle ended
BattleEnd.OnClientEvent:Connect(function(result)
    if not battleUI then return end

    local log = battleUI:getBattleLog()
    battleUI:disableInput()

    if result.outcome == "win" then
        log:addTypedMessage("You won the battle!", "highlight")

        if result.xpGained > 0 then
            log:addTypedMessage("Gained " .. result.xpGained .. " XP!", "heal")
        end
        if result.levelsGained > 0 then
            log:addTypedMessage("Level up! +" .. result.levelsGained .. " levels!", "highlight")
        end
        if result.newMoves and #result.newMoves > 0 then
            for _, moveId in result.newMoves do
                log:addTypedMessage("Learned " .. moveId .. "!", "highlight")
            end
        end

    elseif result.outcome == "lose" then
        log:addTypedMessage("You lost the battle...", "damage")
        log:addMessage("Your creatures have been restored to 1 HP.")

    elseif result.outcome == "captured" then
        log:addTypedMessage("Capture successful!", "highlight")
        if result.capturedCreature then
            log:addTypedMessage(
                result.capturedCreature.speciesId .. " was added to your team!",
                "heal"
            )
        end
    end

    -- Wait a moment then clean up
    task.delay(3.0, function()
        inBattle = false
        currentBattleId = nil
        playerSide = nil
        opponentSide = nil

        if battleUI then
            battleUI:destroy()
            battleUI = nil
        end
    end)
end)

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

function BattleController.isInBattle(): boolean
    return inBattle
end

return BattleController
