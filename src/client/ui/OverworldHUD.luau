--[[
    OverworldHUD.luau  (Client UI module)
    Always-visible overworld UI showing:
        - Mini party bar (creature icons with HP bars)
        - Zone indicator (shows when inside encounter zone)
        - Healed notification
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local uiFolder = script.Parent
local UIConstants = require(uiFolder:WaitForChild("UIConstants"))

local OverworldHUD = {}
OverworldHUD.__index = OverworldHUD

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function OverworldHUD.new(): any
    local self = setmetatable({}, OverworldHUD)

    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OverworldHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = player:WaitForChild("PlayerGui")

    --------------------------------------------------------------------------
    -- Mini party bar (top-left)
    --------------------------------------------------------------------------

    local partyFrame = Instance.new("Frame")
    partyFrame.Name = "PartyBar"
    partyFrame.Size = UDim2.new(0, 200, 0, 50)
    partyFrame.Position = UDim2.new(0, 12, 0, 12)
    partyFrame.BackgroundColor3 = UIConstants.Colors.PanelBg
    partyFrame.BackgroundTransparency = 0.3
    partyFrame.BorderSizePixel = 0
    partyFrame.Parent = screenGui

    local partyCorner = Instance.new("UICorner")
    partyCorner.CornerRadius = UIConstants.Size.CornerRadius
    partyCorner.Parent = partyFrame

    local partyStroke = Instance.new("UIStroke")
    partyStroke.Color = UIConstants.Colors.PanelBorder
    partyStroke.Thickness = 1
    partyStroke.Parent = partyFrame

    -- Party title
    local partyTitle = Instance.new("TextLabel")
    partyTitle.Name = "PartyTitle"
    partyTitle.Size = UDim2.new(1, -8, 0, 14)
    partyTitle.Position = UDim2.new(0, 4, 0, 2)
    partyTitle.BackgroundTransparency = 1
    partyTitle.Text = "🐾 Party"
    partyTitle.TextColor3 = UIConstants.Colors.TextSecondary
    partyTitle.Font = UIConstants.Font.Bold
    partyTitle.TextSize = 11
    partyTitle.TextXAlignment = Enum.TextXAlignment.Left
    partyTitle.Parent = partyFrame

    -- Party slots container
    local slotsFrame = Instance.new("Frame")
    slotsFrame.Name = "Slots"
    slotsFrame.Size = UDim2.new(1, -8, 0, 30)
    slotsFrame.Position = UDim2.new(0, 4, 0, 16)
    slotsFrame.BackgroundTransparency = 1
    slotsFrame.Parent = partyFrame

    local slotsLayout = Instance.new("UIListLayout")
    slotsLayout.FillDirection = Enum.FillDirection.Horizontal
    slotsLayout.Padding = UDim.new(0, 4)
    slotsLayout.Parent = slotsFrame

    self.partyFrame = partyFrame
    self.slotsFrame = slotsFrame

    --------------------------------------------------------------------------
    -- Zone indicator (bottom-center)
    --------------------------------------------------------------------------

    local zoneFrame = Instance.new("Frame")
    zoneFrame.Name = "ZoneIndicator"
    zoneFrame.Size = UDim2.new(0, 250, 0, 36)
    zoneFrame.Position = UDim2.new(0.5, 0, 1, -50)
    zoneFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    zoneFrame.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    zoneFrame.BackgroundTransparency = 0.25
    zoneFrame.BorderSizePixel = 0
    zoneFrame.Visible = false
    zoneFrame.Parent = screenGui

    local zoneCorner = Instance.new("UICorner")
    zoneCorner.CornerRadius = UDim.new(0, 20)
    zoneCorner.Parent = zoneFrame

    local zoneLabel = Instance.new("TextLabel")
    zoneLabel.Name = "ZoneText"
    zoneLabel.Size = UDim2.new(1, 0, 1, 0)
    zoneLabel.BackgroundTransparency = 1
    zoneLabel.Text = "⚠ Wild Area"
    zoneLabel.TextColor3 = Color3.fromRGB(255, 240, 200)
    zoneLabel.Font = UIConstants.Font.Bold
    zoneLabel.TextSize = 15
    zoneLabel.Parent = zoneFrame

    self.zoneFrame = zoneFrame
    self.zoneLabel = zoneLabel

    --------------------------------------------------------------------------
    -- Notification label (center, fades)
    --------------------------------------------------------------------------

    local notifLabel = Instance.new("TextLabel")
    notifLabel.Name = "Notification"
    notifLabel.Size = UDim2.new(0, 350, 0, 40)
    notifLabel.Position = UDim2.new(0.5, 0, 0.35, 0)
    notifLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    notifLabel.BackgroundColor3 = UIConstants.Colors.PanelBg
    notifLabel.BackgroundTransparency = 0.2
    notifLabel.BorderSizePixel = 0
    notifLabel.Text = ""
    notifLabel.TextColor3 = UIConstants.Colors.TextPrimary
    notifLabel.Font = UIConstants.Font.Bold
    notifLabel.TextSize = 18
    notifLabel.Visible = false
    notifLabel.Parent = screenGui

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notifLabel

    self.notifLabel = notifLabel
    self.screenGui = screenGui

    return self
end

------------------------------------------------------------------------
-- Update party display
------------------------------------------------------------------------

function OverworldHUD:updateParty(party: { any })
    -- Clear existing slots
    for _, child in self.slotsFrame:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Resize party bar based on count
    local slotWidth = 58
    local totalWidth = #party * slotWidth + (#party - 1) * 4 + 8
    self.partyFrame.Size = UDim2.new(0, math.max(totalWidth, 120), 0, 50)

    for i, creature in party do
        local slot = Instance.new("Frame")
        slot.Name = "Slot_" .. i
        slot.Size = UDim2.new(0, slotWidth, 0, 28)
        slot.BackgroundColor3 = UIConstants.Colors.PanelBg
        slot.BackgroundTransparency = 0.5
        slot.BorderSizePixel = 0
        slot.Parent = self.slotsFrame

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 4)
        slotCorner.Parent = slot

        -- Element strip
        local strip = Instance.new("Frame")
        strip.Size = UDim2.new(0, 3, 1, 0)
        strip.BackgroundColor3 = UIConstants.getElementColor(creature.element)
        strip.BorderSizePixel = 0
        strip.Parent = slot

        -- Name (abbreviated)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -6, 0, 12)
        nameLabel.Position = UDim2.new(0, 5, 0, 1)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = string.sub(creature.speciesId, 1, 6)
        nameLabel.TextColor3 = creature.currentHp > 0
            and UIConstants.Colors.TextPrimary
            or UIConstants.Colors.TextDamage
        nameLabel.Font = UIConstants.Font.Default
        nameLabel.TextSize = 9
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = slot

        -- Mini HP bar
        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0.85, 0, 0, 5)
        hpBg.Position = UDim2.new(0.075, 0, 0, 15)
        hpBg.BackgroundColor3 = UIConstants.Colors.HpBarBg
        hpBg.BorderSizePixel = 0
        hpBg.Parent = slot

        local hpBgCorner = Instance.new("UICorner")
        hpBgCorner.CornerRadius = UDim.new(0, 2)
        hpBgCorner.Parent = hpBg

        local ratio = math.clamp(creature.currentHp / math.max(creature.maxHp, 1), 0, 1)
        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(ratio, 0, 1, 0)
        hpFill.BackgroundColor3 = UIConstants.getHpColor(ratio)
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg

        local hpFillCorner = Instance.new("UICorner")
        hpFillCorner.CornerRadius = UDim.new(0, 2)
        hpFillCorner.Parent = hpFill

        -- Level
        local lvLabel = Instance.new("TextLabel")
        lvLabel.Size = UDim2.new(1, -6, 0, 10)
        lvLabel.Position = UDim2.new(0, 5, 0, 20)
        lvLabel.BackgroundTransparency = 1
        lvLabel.Text = "Lv" .. creature.level
        lvLabel.TextColor3 = UIConstants.Colors.TextSecondary
        lvLabel.Font = UIConstants.Font.Mono
        lvLabel.TextSize = 8
        lvLabel.TextXAlignment = Enum.TextXAlignment.Right
        lvLabel.Parent = slot
    end
end

------------------------------------------------------------------------
-- Zone indicator
------------------------------------------------------------------------

function OverworldHUD:showZoneIndicator(zoneId: string)
    self.zoneLabel.Text = "⚠ Wild Area — " .. zoneId
    self.zoneFrame.Visible = true
end

function OverworldHUD:hideZoneIndicator()
    self.zoneFrame.Visible = false
end

------------------------------------------------------------------------
-- Notification (fades after a delay)
------------------------------------------------------------------------

function OverworldHUD:showNotification(text: string, duration: number?)
    local dur = duration or 2.5

    self.notifLabel.Text = text
    self.notifLabel.TextTransparency = 0
    self.notifLabel.BackgroundTransparency = 0.2
    self.notifLabel.Visible = true

    task.delay(dur, function()
        local fadeOut = TweenService:Create(self.notifLabel, TweenInfo.new(0.5), {
            TextTransparency = 1,
            BackgroundTransparency = 1,
        })
        fadeOut:Play()
        fadeOut.Completed:Wait()
        self.notifLabel.Visible = false
    end)
end

------------------------------------------------------------------------
-- Show / Hide (for during battles)
------------------------------------------------------------------------

function OverworldHUD:show()
    self.screenGui.Enabled = true
end

function OverworldHUD:hide()
    self.screenGui.Enabled = false
end

function OverworldHUD:destroy()
    self.screenGui:Destroy()
end

return OverworldHUD
