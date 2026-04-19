--[[
    BattleHUD.luau
    Reusable creature info plate component showing:
        - Creature name + level
        - Element color badge
        - HP bar (green→yellow→red)
        - MP bar (blue)

    Used for both the player's and opponent's creature display.
]]

local TweenService = game:GetService("TweenService")

local UIConstants = require(script.Parent:WaitForChild("UIConstants"))

local BattleHUD = {}
BattleHUD.__index = BattleHUD

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function BattleHUD.new(parent: GuiObject, isEnemy: boolean): any
    local self = setmetatable({}, BattleHUD)

    self.isEnemy = isEnemy

    -- Main container
    local plate = Instance.new("Frame")
    plate.Name = isEnemy and "EnemyPlate" or "PlayerPlate"
    plate.Size = UDim2.new(0, 280, 0, 95)
    plate.BackgroundColor3 = UIConstants.Colors.PanelBg
    plate.BorderSizePixel = 0
    plate.Parent = parent

    if isEnemy then
        plate.AnchorPoint = Vector2.new(0, 0)
        plate.Position = UDim2.new(0.05, 0, 0.05, 0)
    else
        plate.AnchorPoint = Vector2.new(1, 1)
        plate.Position = UDim2.new(0.95, 0, 0.95, 0)
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIConstants.Size.CornerRadius
    corner.Parent = plate

    local stroke = Instance.new("UIStroke")
    stroke.Color = UIConstants.Colors.PanelBorder
    stroke.Thickness = 1.5
    stroke.Parent = plate

    -- Element badge (colored strip on left side)
    local badge = Instance.new("Frame")
    badge.Name = "ElementBadge"
    badge.Size = UDim2.new(0, 6, 1, 0)
    badge.Position = UDim2.new(0, 0, 0, 0)
    badge.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    badge.BorderSizePixel = 0
    badge.Parent = plate

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 6)
    badgeCorner.Parent = badge

    self.badge = badge

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.6, 0, 0, 22)
    nameLabel.Position = UDim2.new(0, 16, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Creature"
    nameLabel.TextColor3 = UIConstants.Colors.TextPrimary
    nameLabel.Font = UIConstants.Font.Bold
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = plate
    self.nameLabel = nameLabel

    -- Level label
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.3, 0, 0, 22)
    levelLabel.Position = UDim2.new(0.68, 0, 0, 8)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv.5"
    levelLabel.TextColor3 = UIConstants.Colors.TextSecondary
    levelLabel.Font = UIConstants.Font.Default
    levelLabel.TextSize = 14
    levelLabel.TextXAlignment = Enum.TextXAlignment.Right
    levelLabel.Parent = plate
    self.levelLabel = levelLabel

    -- HP label
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Name = "HpLabel"
    hpLabel.Size = UDim2.new(0, 40, 0, 14)
    hpLabel.Position = UDim2.new(0, 16, 0, 33)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = "HP"
    hpLabel.TextColor3 = UIConstants.Colors.TextSecondary
    hpLabel.Font = UIConstants.Font.Bold
    hpLabel.TextSize = 12
    hpLabel.TextXAlignment = Enum.TextXAlignment.Left
    hpLabel.Parent = plate

    -- HP bar background
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Name = "HpBarBg"
    hpBarBg.Size = UDim2.new(0.75, 0, 0, 12)
    hpBarBg.Position = UDim2.new(0.2, 0, 0, 34)
    hpBarBg.BackgroundColor3 = UIConstants.Colors.HpBarBg
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = plate

    local hpBarBgCorner = Instance.new("UICorner")
    hpBarBgCorner.CornerRadius = UDim.new(0, 4)
    hpBarBgCorner.Parent = hpBarBg

    -- HP bar fill
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HpFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = UIConstants.Colors.HpFull
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBarBg

    local hpFillCorner = Instance.new("UICorner")
    hpFillCorner.CornerRadius = UDim.new(0, 4)
    hpFillCorner.Parent = hpFill

    self.hpFill = hpFill

    -- HP text (numbers)
    local hpText = Instance.new("TextLabel")
    hpText.Name = "HpText"
    hpText.Size = UDim2.new(1, -8, 1, 0)
    hpText.Position = UDim2.new(0, 4, 0, 0)
    hpText.BackgroundTransparency = 1
    hpText.Text = "50/50"
    hpText.TextColor3 = UIConstants.Colors.TextPrimary
    hpText.Font = UIConstants.Font.Mono
    hpText.TextSize = 10
    hpText.TextXAlignment = Enum.TextXAlignment.Right
    hpText.Parent = hpBarBg
    self.hpText = hpText

    -- MP label
    local mpLabel = Instance.new("TextLabel")
    mpLabel.Name = "MpLabel"
    mpLabel.Size = UDim2.new(0, 40, 0, 14)
    mpLabel.Position = UDim2.new(0, 16, 0, 52)
    mpLabel.BackgroundTransparency = 1
    mpLabel.Text = "MP"
    mpLabel.TextColor3 = UIConstants.Colors.TextSecondary
    mpLabel.Font = UIConstants.Font.Bold
    mpLabel.TextSize = 12
    mpLabel.TextXAlignment = Enum.TextXAlignment.Left
    mpLabel.Parent = plate

    -- MP bar background
    local mpBarBg = Instance.new("Frame")
    mpBarBg.Name = "MpBarBg"
    mpBarBg.Size = UDim2.new(0.75, 0, 0, 10)
    mpBarBg.Position = UDim2.new(0.2, 0, 0, 54)
    mpBarBg.BackgroundColor3 = UIConstants.Colors.MpBarBg
    mpBarBg.BorderSizePixel = 0
    mpBarBg.Parent = plate

    local mpBarBgCorner = Instance.new("UICorner")
    mpBarBgCorner.CornerRadius = UDim.new(0, 4)
    mpBarBgCorner.Parent = mpBarBg

    -- MP bar fill
    local mpFill = Instance.new("Frame")
    mpFill.Name = "MpFill"
    mpFill.Size = UDim2.new(1, 0, 1, 0)
    mpFill.BackgroundColor3 = UIConstants.Colors.MpBar
    mpFill.BorderSizePixel = 0
    mpFill.Parent = mpBarBg

    local mpFillCorner = Instance.new("UICorner")
    mpFillCorner.CornerRadius = UDim.new(0, 4)
    mpFillCorner.Parent = mpFill

    self.mpFill = mpFill

    -- MP text
    local mpText = Instance.new("TextLabel")
    mpText.Name = "MpText"
    mpText.Size = UDim2.new(1, -8, 1, 0)
    mpText.Position = UDim2.new(0, 4, 0, 0)
    mpText.BackgroundTransparency = 1
    mpText.Text = "30/30"
    mpText.TextColor3 = UIConstants.Colors.TextPrimary
    mpText.Font = UIConstants.Font.Mono
    mpText.TextSize = 9
    mpText.TextXAlignment = Enum.TextXAlignment.Right
    mpText.Parent = mpBarBg
    self.mpText = mpText

    -- Element name label
    local elementLabel = Instance.new("TextLabel")
    elementLabel.Name = "ElementLabel"
    elementLabel.Size = UDim2.new(0.5, 0, 0, 14)
    elementLabel.Position = UDim2.new(0, 16, 0, 72)
    elementLabel.BackgroundTransparency = 1
    elementLabel.Text = "Ember"
    elementLabel.TextColor3 = UIConstants.Colors.TextSecondary
    elementLabel.Font = UIConstants.Font.Default
    elementLabel.TextSize = 11
    elementLabel.TextXAlignment = Enum.TextXAlignment.Left
    elementLabel.Parent = plate
    self.elementLabel = elementLabel

    self.plate = plate
    return self
end

------------------------------------------------------------------------
-- Update creature info
------------------------------------------------------------------------

function BattleHUD:setCreature(data: any)
    local name = data.nickname or data.name or data.speciesId
    self.nameLabel.Text = name
    self.levelLabel.Text = "Lv." .. tostring(data.level)

    local elementColor = UIConstants.getElementColor(data.element)
    self.badge.BackgroundColor3 = elementColor
    self.elementLabel.Text = data.element
    self.elementLabel.TextColor3 = elementColor

    self:updateHP(data.currentHp, data.maxHp, false)
    self:updateMP(data.currentMp, data.maxMp, false)
end

------------------------------------------------------------------------
-- Update HP with optional animation
------------------------------------------------------------------------

function BattleHUD:updateHP(current: number, max: number, animate: boolean?)
    local ratio = math.clamp(current / math.max(max, 1), 0, 1)
    local targetSize = UDim2.new(ratio, 0, 1, 0)
    local color = UIConstants.getHpColor(ratio)

    self.hpText.Text = tostring(current) .. "/" .. tostring(max)

    if animate then
        local tween = TweenService:Create(self.hpFill, TweenInfo.new(
            UIConstants.Anim.BarDrain,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), { Size = targetSize, BackgroundColor3 = color })
        tween:Play()
    else
        self.hpFill.Size = targetSize
        self.hpFill.BackgroundColor3 = color
    end
end

------------------------------------------------------------------------
-- Update MP with optional animation
------------------------------------------------------------------------

function BattleHUD:updateMP(current: number, max: number, animate: boolean?)
    local ratio = math.clamp(current / math.max(max, 1), 0, 1)
    local targetSize = UDim2.new(ratio, 0, 1, 0)

    self.mpText.Text = tostring(current) .. "/" .. tostring(max)

    if animate then
        local tween = TweenService:Create(self.mpFill, TweenInfo.new(
            UIConstants.Anim.BarDrain,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), { Size = targetSize })
        tween:Play()
    else
        self.mpFill.Size = targetSize
    end
end

------------------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------------------

function BattleHUD:show()
    self.plate.Visible = true
end

function BattleHUD:hide()
    self.plate.Visible = false
end

function BattleHUD:destroy()
    self.plate:Destroy()
end

return BattleHUD
