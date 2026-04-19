--[[
    SwitchUI.luau
    Party switch sub-menu. Shows all party creatures with HP bars.
    Greyed out for fainted creatures. Highlights current active.
]]

local UIConstants = require(script.Parent:WaitForChild("UIConstants"))

local SwitchUI = {}
SwitchUI.__index = SwitchUI

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function SwitchUI.new(parent: GuiObject): any
    local self = setmetatable({}, SwitchUI)

    local frame = Instance.new("Frame")
    frame.Name = "SwitchUI"
    frame.Size = UDim2.new(1, 0, 0, 110)
    frame.Position = UDim2.new(0, 0, 1, -110)
    frame.BackgroundColor3 = UIConstants.Colors.ActionPanelBg
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.5, 0, 0, 20)
    title.Position = UDim2.new(0.05, 0, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "🔄 Switch Creature"
    title.TextColor3 = UIConstants.Colors.TextSecondary
    title.Font = UIConstants.Font.Bold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    self.titleLabel = title

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
    self.backBtn = backBtn

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 6)
    backCorner.Parent = backBtn

    -- Party list
    local partyList = Instance.new("Frame")
    partyList.Name = "PartyList"
    partyList.Size = UDim2.new(0.95, 0, 0, 70)
    partyList.Position = UDim2.new(0.025, 0, 0, 28)
    partyList.BackgroundTransparency = 1
    partyList.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.Parent = partyList

    self.frame = frame
    self.partyList = partyList
    self.onCreatureSelected = nil
    self.onBack = nil

    backBtn.MouseButton1Click:Connect(function()
        if self.onBack then self.onBack() end
    end)

    return self
end

------------------------------------------------------------------------
-- Show party for selection
------------------------------------------------------------------------

function SwitchUI:showParty(party: { any }, activeIndex: number, forced: boolean?)
    -- Clear existing
    for _, child in self.partyList:GetChildren() do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- If forced (after faint), hide back button
    if forced then
        self.backBtn.Visible = false
        self.titleLabel.Text = "⚠ Choose a replacement!"
    else
        self.backBtn.Visible = true
        self.titleLabel.Text = "🔄 Switch Creature"
    end

    for i, creature in party do
        local isActive = (i == activeIndex)
        local isFainted = (creature.currentHp <= 0)
        local canSelect = not isActive and not isFainted

        local btn = Instance.new("TextButton")
        btn.Name = "Party_" .. i
        btn.Size = UDim2.new(0, 110, 0, 65)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Active = canSelect
        btn.BorderSizePixel = 0
        btn.Parent = self.partyList

        -- Color based on state
        if isActive then
            btn.BackgroundColor3 = UIConstants.Colors.ButtonHover
        elseif isFainted then
            btn.BackgroundColor3 = UIConstants.Colors.ButtonDisabled
        else
            btn.BackgroundColor3 = UIConstants.Colors.ButtonDefault
        end

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        -- Element strip
        local strip = Instance.new("Frame")
        strip.Size = UDim2.new(1, 0, 0, 3)
        strip.BackgroundColor3 = UIConstants.getElementColor(creature.element)
        strip.BorderSizePixel = 0
        strip.Parent = btn

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -6, 0, 16)
        nameLabel.Position = UDim2.new(0, 3, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = (creature.nickname or creature.speciesId) .. " Lv." .. creature.level
        nameLabel.TextColor3 = isFainted and UIConstants.Colors.ButtonTextDim or UIConstants.Colors.ButtonText
        nameLabel.Font = UIConstants.Font.Bold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = btn

        -- HP bar bg
        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0.85, 0, 0, 8)
        hpBg.Position = UDim2.new(0.075, 0, 0, 28)
        hpBg.BackgroundColor3 = UIConstants.Colors.HpBarBg
        hpBg.BorderSizePixel = 0
        hpBg.Parent = btn

        local hpBgCorner = Instance.new("UICorner")
        hpBgCorner.CornerRadius = UDim.new(0, 3)
        hpBgCorner.Parent = hpBg

        -- HP bar fill
        local ratio = math.clamp(creature.currentHp / math.max(creature.maxHp, 1), 0, 1)
        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(ratio, 0, 1, 0)
        hpFill.BackgroundColor3 = UIConstants.getHpColor(ratio)
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg

        local hpFillCorner = Instance.new("UICorner")
        hpFillCorner.CornerRadius = UDim.new(0, 3)
        hpFillCorner.Parent = hpFill

        -- HP text
        local hpText = Instance.new("TextLabel")
        hpText.Size = UDim2.new(1, -6, 0, 12)
        hpText.Position = UDim2.new(0, 3, 0, 40)
        hpText.BackgroundTransparency = 1
        hpText.Text = creature.currentHp .. "/" .. creature.maxHp
        hpText.TextColor3 = UIConstants.Colors.TextSecondary
        hpText.Font = UIConstants.Font.Mono
        hpText.TextSize = 10
        hpText.TextXAlignment = Enum.TextXAlignment.Center
        hpText.Parent = btn

        -- Status label
        if isActive then
            local statusLabel = Instance.new("TextLabel")
            statusLabel.Size = UDim2.new(1, 0, 0, 12)
            statusLabel.Position = UDim2.new(0, 0, 0, 52)
            statusLabel.BackgroundTransparency = 1
            statusLabel.Text = "Active"
            statusLabel.TextColor3 = UIConstants.Colors.TextHeal
            statusLabel.Font = UIConstants.Font.Default
            statusLabel.TextSize = 10
            statusLabel.Parent = btn
        elseif isFainted then
            local statusLabel = Instance.new("TextLabel")
            statusLabel.Size = UDim2.new(1, 0, 0, 12)
            statusLabel.Position = UDim2.new(0, 0, 0, 52)
            statusLabel.BackgroundTransparency = 1
            statusLabel.Text = "Fainted"
            statusLabel.TextColor3 = UIConstants.Colors.TextDamage
            statusLabel.Font = UIConstants.Font.Default
            statusLabel.TextSize = 10
            statusLabel.Parent = btn
        end

        -- Click handler
        if canSelect then
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = UIConstants.Colors.ButtonHover
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = UIConstants.Colors.ButtonDefault
            end)
            btn.MouseButton1Click:Connect(function()
                if self.onCreatureSelected then
                    self.onCreatureSelected(i)
                end
            end)
        end
    end

    self.frame.Visible = true
end

------------------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------------------

function SwitchUI:show()
    self.frame.Visible = true
end

function SwitchUI:hide()
    self.frame.Visible = false
end

function SwitchUI:destroy()
    self.frame:Destroy()
end

return SwitchUI
