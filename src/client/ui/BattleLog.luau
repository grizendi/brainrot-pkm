--[[
    BattleLog.luau
    Scrolling text feed at the bottom of the battle screen.
    Displays damage messages, effectiveness, status changes, etc.
]]

local UIConstants = require(script.Parent:WaitForChild("UIConstants"))

local BattleLog = {}
BattleLog.__index = BattleLog

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function BattleLog.new(parent: GuiObject): any
    local self = setmetatable({}, BattleLog)

    local frame = Instance.new("Frame")
    frame.Name = "BattleLog"
    frame.Size = UDim2.new(1, 0, 0, 70)
    frame.Position = UDim2.new(0, 0, 1, -180)  -- above action menu
    frame.BackgroundColor3 = UIConstants.Colors.LogBg
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Scrolling frame for messages
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "MessageScroll"
    scroll.Size = UDim2.new(1, -16, 1, -8)
    scroll.Position = UDim2.new(0, 8, 0, 4)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = UIConstants.Colors.PanelBorder
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    self.frame = frame
    self.scroll = scroll
    self.messageCount = 0

    return self
end

------------------------------------------------------------------------
-- Add a message
------------------------------------------------------------------------

function BattleLog:addMessage(text: string, color: Color3?)
    self.messageCount = self.messageCount + 1

    local label = Instance.new("TextLabel")
    label.Name = "Msg_" .. self.messageCount
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or UIConstants.Colors.LogText
    label.Font = UIConstants.Font.Default
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.LayoutOrder = self.messageCount
    label.Parent = self.scroll

    -- Auto-scroll to bottom
    task.defer(function()
        self.scroll.CanvasPosition = Vector2.new(0, self.scroll.AbsoluteCanvasSize.Y)
    end)
end

--- Add a message with a type-based color
function BattleLog:addTypedMessage(text: string, messageType: string?)
    local color = UIConstants.Colors.LogText

    if messageType == "damage" then
        color = UIConstants.Colors.TextDamage
    elseif messageType == "heal" then
        color = UIConstants.Colors.TextHeal
    elseif messageType == "super_effective" then
        color = UIConstants.Colors.TextSuperEff
    elseif messageType == "not_effective" then
        color = UIConstants.Colors.TextNotEff
    elseif messageType == "highlight" then
        color = UIConstants.Colors.LogHighlight
    end

    self:addMessage(text, color)
end

------------------------------------------------------------------------
-- Clear all messages
------------------------------------------------------------------------

function BattleLog:clear()
    for _, child in self.scroll:GetChildren() do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    self.messageCount = 0
end

------------------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------------------

function BattleLog:show()
    self.frame.Visible = true
end

function BattleLog:hide()
    self.frame.Visible = false
end

function BattleLog:destroy()
    self.frame:Destroy()
end

return BattleLog
