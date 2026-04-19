--[[
    MoveSelectUI.luau
    Sub-menu for selecting moves during battle.
    Supports two modes:
        "Attack" → shows Physical moves + free Tackle
        "Skills" → shows Special + Status moves
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local MoveDatabase = require(Shared:WaitForChild("MoveDatabase"))
local UIConstants = require(script.Parent:WaitForChild("UIConstants"))

local MoveSelectUI = {}
MoveSelectUI.__index = MoveSelectUI

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function MoveSelectUI.new(parent: GuiObject): any
    local self = setmetatable({}, MoveSelectUI)

    -- Container (overlays action menu area)
    local frame = Instance.new("Frame")
    frame.Name = "MoveSelectUI"
    frame.Size = UDim2.new(1, 0, 0, 110)
    frame.Position = UDim2.new(0, 0, 1, -110)
    frame.BackgroundColor3 = UIConstants.Colors.ActionPanelBg
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- Title label
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.5, 0, 0, 20)
    title.Position = UDim2.new(0.05, 0, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "Select Move"
    title.TextColor3 = UIConstants.Colors.TextSecondary
    title.Font = UIConstants.Font.Bold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    self.title = title

    -- Back button
    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackButton"
    backBtn.Text = "← Back"
    backBtn.Size = UDim2.new(0, 70, 0, 24)
    backBtn.Position = UDim2.new(0.88, 0, 0, 4)
    backBtn.AnchorPoint = Vector2.new(0.5, 0)
    backBtn.BackgroundColor3 = UIConstants.Colors.ButtonDefault
    backBtn.TextColor3 = UIConstants.Colors.ButtonText
    backBtn.Font = UIConstants.Font.Default
    backBtn.TextSize = 12
    backBtn.BorderSizePixel = 0
    backBtn.Parent = frame

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 6)
    backCorner.Parent = backBtn

    -- Move buttons container
    local moveList = Instance.new("Frame")
    moveList.Name = "MoveList"
    moveList.Size = UDim2.new(0.95, 0, 0, 70)
    moveList.Position = UDim2.new(0.025, 0, 0, 28)
    moveList.BackgroundTransparency = 1
    moveList.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Padding = UDim.new(0, 6)
    layout.Parent = moveList

    self.frame = frame
    self.moveList = moveList
    self.backBtn = backBtn
    self.onMoveSelected = nil
    self.onBack = nil

    backBtn.MouseButton1Click:Connect(function()
        if self.onBack then self.onBack() end
    end)

    return self
end

------------------------------------------------------------------------
-- Show moves for a given mode
------------------------------------------------------------------------

function MoveSelectUI:showMoves(creatureMoves: { string }, currentMp: number, mode: string)
    -- Clear existing buttons
    for _, child in self.moveList:GetChildren() do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Filter moves based on mode
    local moveIds: { string }
    if mode == "Attack" then
        self.title.Text = "⚔ Physical Attacks"
        moveIds = MoveDatabase.getPhysicalMoves(creatureMoves)
    else
        self.title.Text = "✨ Special / Status Skills"
        moveIds = MoveDatabase.getSkillMoves(creatureMoves)
    end

    -- Create a button for each move
    for _, moveId in moveIds do
        local move = MoveDatabase.getMove(moveId)
        if not move then continue end

        local canAfford = currentMp >= move.mpCost

        local btn = Instance.new("TextButton")
        btn.Name = "Move_" .. moveId
        btn.Size = UDim2.new(0, 150, 0, 65)
        btn.BackgroundColor3 = canAfford and UIConstants.Colors.ButtonDefault or UIConstants.Colors.ButtonDisabled
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Active = canAfford
        btn.Parent = self.moveList

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        -- Element color strip at top
        local elementStrip = Instance.new("Frame")
        elementStrip.Name = "ElementStrip"
        elementStrip.Size = UDim2.new(1, 0, 0, 3)
        elementStrip.Position = UDim2.new(0, 0, 0, 0)
        elementStrip.BackgroundColor3 = UIConstants.getElementColor(move.element)
        elementStrip.BorderSizePixel = 0
        elementStrip.Parent = btn

        -- Move name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -8, 0, 18)
        nameLabel.Position = UDim2.new(0, 4, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = move.name
        nameLabel.TextColor3 = canAfford and UIConstants.Colors.ButtonText or UIConstants.Colors.ButtonTextDim
        nameLabel.Font = UIConstants.Font.Bold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = btn

        -- Power / Category label
        local infoText = move.category == "Status" and "Status" or ("Pow: " .. move.power)
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(0.5, -4, 0, 14)
        infoLabel.Position = UDim2.new(0, 4, 0, 26)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = infoText
        infoLabel.TextColor3 = UIConstants.Colors.TextSecondary
        infoLabel.Font = UIConstants.Font.Default
        infoLabel.TextSize = 11
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = btn

        -- MP cost label
        local mpLabel = Instance.new("TextLabel")
        mpLabel.Size = UDim2.new(0.5, -4, 0, 14)
        mpLabel.Position = UDim2.new(0.5, 0, 0, 26)
        mpLabel.BackgroundTransparency = 1
        mpLabel.Text = move.mpCost > 0 and ("MP: " .. move.mpCost) or "FREE"
        mpLabel.TextColor3 = move.mpCost == 0 and UIConstants.Colors.TextHeal or UIConstants.Colors.TextSecondary
        mpLabel.Font = UIConstants.Font.Default
        mpLabel.TextSize = 11
        mpLabel.TextXAlignment = Enum.TextXAlignment.Right
        mpLabel.Parent = btn

        -- Accuracy label
        local accLabel = Instance.new("TextLabel")
        accLabel.Size = UDim2.new(1, -8, 0, 12)
        accLabel.Position = UDim2.new(0, 4, 0, 44)
        accLabel.BackgroundTransparency = 1
        accLabel.Text = "Acc: " .. move.accuracy .. "%"
        accLabel.TextColor3 = UIConstants.Colors.TextSecondary
        accLabel.Font = UIConstants.Font.Default
        accLabel.TextSize = 10
        accLabel.TextXAlignment = Enum.TextXAlignment.Left
        accLabel.Parent = btn

        -- Click handler
        if canAfford then
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = UIConstants.Colors.ButtonHover
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = UIConstants.Colors.ButtonDefault
            end)
            btn.MouseButton1Click:Connect(function()
                if self.onMoveSelected then
                    self.onMoveSelected(moveId, move.category)
                end
            end)
        end
    end

    self.frame.Visible = true
end

------------------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------------------

function MoveSelectUI:show()
    self.frame.Visible = true
end

function MoveSelectUI:hide()
    self.frame.Visible = false
end

function MoveSelectUI:destroy()
    self.frame:Destroy()
end

return MoveSelectUI
