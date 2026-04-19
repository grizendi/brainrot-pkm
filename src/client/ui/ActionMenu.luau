--[[
    ActionMenu.luau
    Main 5-button action panel for battles:
        Attack, Defend, Skills, Items, Switch

    Provides callbacks for each button press.
]]

local UIConstants = require(script.Parent:WaitForChild("UIConstants"))

local ActionMenu = {}
ActionMenu.__index = ActionMenu

------------------------------------------------------------------------
-- Internal: create a styled button
------------------------------------------------------------------------

local function createButton(parent: GuiObject, text: string, position: UDim2, id: string): TextButton
    local button = Instance.new("TextButton")
    button.Name = id .. "Button"
    button.Text = text
    button.Size = UDim2.new(0, 130, 0, 40)
    button.Position = position
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = UIConstants.Colors.ButtonDefault
    button.TextColor3 = UIConstants.Colors.ButtonText
    button.Font = UIConstants.Font.Bold
    button.TextSize = 15
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIConstants.Size.ButtonCorner
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = UIConstants.Colors.PanelBorder
    stroke.Thickness = 1
    stroke.Parent = button

    -- Hover effects
    button.MouseEnter:Connect(function()
        if button.Active then
            button.BackgroundColor3 = UIConstants.Colors.ButtonHover
        end
    end)
    button.MouseLeave:Connect(function()
        if button.Active then
            button.BackgroundColor3 = UIConstants.Colors.ButtonDefault
        end
    end)

    return button
end

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function ActionMenu.new(parent: GuiObject): any
    local self = setmetatable({}, ActionMenu)

    -- Container frame
    local frame = Instance.new("Frame")
    frame.Name = "ActionMenu"
    frame.Size = UDim2.new(1, 0, 0, 110)
    frame.Position = UDim2.new(0, 0, 1, -110)
    frame.BackgroundColor3 = UIConstants.Colors.ActionPanelBg
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- Divider line at top
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(0.9, 0, 0, 1)
    divider.Position = UDim2.new(0.05, 0, 0, 0)
    divider.BackgroundColor3 = UIConstants.Colors.PanelBorder
    divider.BorderSizePixel = 0
    divider.Parent = frame

    -- Create buttons in a 2x2 + 1 layout
    local attackBtn = createButton(frame, "⚔ ATTACK", UDim2.new(0.22, 0, 0.3, 0), "Attack")
    local defendBtn = createButton(frame, "🛡 DEFEND", UDim2.new(0.5, 0, 0.3, 0), "Defend")
    local skillsBtn = createButton(frame, "✨ SKILLS", UDim2.new(0.78, 0, 0.3, 0), "Skills")
    local itemsBtn  = createButton(frame, "🎒 ITEMS",  UDim2.new(0.33, 0, 0.73, 0), "Items")
    local switchBtn = createButton(frame, "🔄 SWITCH", UDim2.new(0.67, 0, 0.73, 0), "Switch")

    self.frame = frame
    self.buttons = {
        attack = attackBtn,
        defend = defendBtn,
        skills = skillsBtn,
        items = itemsBtn,
        switch = switchBtn,
    }
    self.callbacks = {}

    -- Wire button clicks
    attackBtn.MouseButton1Click:Connect(function()
        if self.callbacks.onAttack then self.callbacks.onAttack() end
    end)
    defendBtn.MouseButton1Click:Connect(function()
        if self.callbacks.onDefend then self.callbacks.onDefend() end
    end)
    skillsBtn.MouseButton1Click:Connect(function()
        if self.callbacks.onSkills then self.callbacks.onSkills() end
    end)
    itemsBtn.MouseButton1Click:Connect(function()
        if self.callbacks.onItems then self.callbacks.onItems() end
    end)
    switchBtn.MouseButton1Click:Connect(function()
        if self.callbacks.onSwitch then self.callbacks.onSwitch() end
    end)

    return self
end

------------------------------------------------------------------------
-- Callbacks
------------------------------------------------------------------------

function ActionMenu:setCallbacks(callbacks: any)
    self.callbacks = callbacks
end

------------------------------------------------------------------------
-- Enable / Disable
------------------------------------------------------------------------

function ActionMenu:setEnabled(enabled: boolean)
    for _, button in self.buttons do
        button.Active = enabled
        button.BackgroundColor3 = enabled and UIConstants.Colors.ButtonDefault or UIConstants.Colors.ButtonDisabled
        button.TextColor3 = enabled and UIConstants.Colors.ButtonText or UIConstants.Colors.ButtonTextDim
    end
end

function ActionMenu:show()
    self.frame.Visible = true
end

function ActionMenu:hide()
    self.frame.Visible = false
end

function ActionMenu:destroy()
    self.frame:Destroy()
end

return ActionMenu
