--[[
    BattleUI.luau
    Master battle screen ScreenGui.
    Creates and positions all battle UI panels:
        - Enemy creature info plate (top-left)
        - Player creature info plate (bottom-right)
        - Battle log (middle-bottom)
        - Action menu with sub-menus (bottom)
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UIConstants = require(script.Parent:WaitForChild("UIConstants"))
local BattleHUD = require(script.Parent:WaitForChild("BattleHUD"))
local ActionMenu = require(script.Parent:WaitForChild("ActionMenu"))
local MoveSelectUI = require(script.Parent:WaitForChild("MoveSelectUI"))
local ItemSelectUI = require(script.Parent:WaitForChild("ItemSelectUI"))
local SwitchUI = require(script.Parent:WaitForChild("SwitchUI"))
local BattleLog = require(script.Parent:WaitForChild("BattleLog"))

local BattleUI = {}
BattleUI.__index = BattleUI

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function BattleUI.new(): any
    local self = setmetatable({}, BattleUI)

    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BattleScreen"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.IgnoreGuiInset = true
    screenGui.Enabled = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Full-screen darkened background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = UIConstants.Colors.BattleBg
    background.BackgroundTransparency = 0.15
    background.BorderSizePixel = 0
    background.Parent = screenGui

    -- Battle arena area (top ~60% of screen — creature display zone)
    local arenaFrame = Instance.new("Frame")
    arenaFrame.Name = "ArenaFrame"
    arenaFrame.Size = UDim2.new(1, 0, 0.55, 0)
    arenaFrame.Position = UDim2.new(0, 0, 0, 0)
    arenaFrame.BackgroundTransparency = 1
    arenaFrame.Parent = background

    -- Bottom panel area (bottom ~45% — log + menus)
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0.45, 0)
    bottomFrame.Position = UDim2.new(0, 0, 0.55, 0)
    bottomFrame.BackgroundTransparency = 1
    bottomFrame.Parent = background

    -- Create components
    local enemyHUD = BattleHUD.new(arenaFrame, true)
    local playerHUD = BattleHUD.new(arenaFrame, false)
    local battleLog = BattleLog.new(bottomFrame)
    local actionMenu = ActionMenu.new(bottomFrame)
    local moveSelectUI = MoveSelectUI.new(bottomFrame)
    local itemSelectUI = ItemSelectUI.new(bottomFrame)
    local switchUI = SwitchUI.new(bottomFrame)

    -- VS indicator in center
    local vsLabel = Instance.new("TextLabel")
    vsLabel.Name = "VSLabel"
    vsLabel.Size = UDim2.new(0, 80, 0, 40)
    vsLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    vsLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    vsLabel.BackgroundTransparency = 1
    vsLabel.Text = "⚔ VS"
    vsLabel.TextColor3 = UIConstants.Colors.TextSecondary
    vsLabel.Font = UIConstants.Font.Header
    vsLabel.TextSize = 20
    vsLabel.Parent = arenaFrame

    self.screenGui = screenGui
    self.background = background
    self.arenaFrame = arenaFrame
    self.bottomFrame = bottomFrame
    self.enemyHUD = enemyHUD
    self.playerHUD = playerHUD
    self.battleLog = battleLog
    self.actionMenu = actionMenu
    self.moveSelectUI = moveSelectUI
    self.itemSelectUI = itemSelectUI
    self.switchUI = switchUI

    return self
end

------------------------------------------------------------------------
-- Access components
------------------------------------------------------------------------

function BattleUI:getEnemyHUD() return self.enemyHUD end
function BattleUI:getPlayerHUD() return self.playerHUD end
function BattleUI:getBattleLog() return self.battleLog end
function BattleUI:getActionMenu() return self.actionMenu end
function BattleUI:getMoveSelectUI() return self.moveSelectUI end
function BattleUI:getItemSelectUI() return self.itemSelectUI end
function BattleUI:getSwitchUI() return self.switchUI end

------------------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------------------

function BattleUI:show()
    self.screenGui.Enabled = true
    self.actionMenu:show()
    self.moveSelectUI:hide()
    self.itemSelectUI:hide()
    self.switchUI:hide()
    self.battleLog:clear()
end

function BattleUI:hide()
    self.screenGui.Enabled = false
end

------------------------------------------------------------------------
-- Show only the action menu (hide sub-menus)
------------------------------------------------------------------------

function BattleUI:showActionMenu()
    self.actionMenu:show()
    self.actionMenu:setEnabled(true)
    self.moveSelectUI:hide()
    self.itemSelectUI:hide()
    self.switchUI:hide()
end

------------------------------------------------------------------------
-- Disable all input (during turn resolution)
------------------------------------------------------------------------

function BattleUI:disableInput()
    self.actionMenu:setEnabled(false)
    self.moveSelectUI:hide()
    self.itemSelectUI:hide()
    self.switchUI:hide()
end

------------------------------------------------------------------------
-- Show forced switch (after faint — no back button)
------------------------------------------------------------------------

function BattleUI:showForcedSwitch(party: { any }, activeIndex: number)
    self.actionMenu:hide()
    self.moveSelectUI:hide()
    self.itemSelectUI:hide()
    self.switchUI:showParty(party, activeIndex, true)
end

------------------------------------------------------------------------
-- Destroy
------------------------------------------------------------------------

function BattleUI:destroy()
    self.screenGui:Destroy()
end

return BattleUI
