--[[
    ItemSelectUI.luau
    Scrollable item selection sub-menu for battles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ItemDatabase = require(Shared:WaitForChild("ItemDatabase"))
local UIConstants = require(script.Parent:WaitForChild("UIConstants"))

local ItemSelectUI = {}
ItemSelectUI.__index = ItemSelectUI

------------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------------

function ItemSelectUI.new(parent: GuiObject): any
    local self = setmetatable({}, ItemSelectUI)

    local frame = Instance.new("Frame")
    frame.Name = "ItemSelectUI"
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
    title.Text = "🎒 Items"
    title.TextColor3 = UIConstants.Colors.TextSecondary
    title.Font = UIConstants.Font.Bold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

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

    -- Scrolling item list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemList"
    scrollFrame.Size = UDim2.new(0.95, 0, 0, 70)
    scrollFrame.Position = UDim2.new(0.025, 0, 0, 28)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = UIConstants.Colors.PanelBorder
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
    scrollFrame.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scrollFrame

    self.frame = frame
    self.scrollFrame = scrollFrame
    self.backBtn = backBtn
    self.onItemSelected = nil
    self.onBack = nil

    backBtn.MouseButton1Click:Connect(function()
        if self.onBack then self.onBack() end
    end)

    return self
end

------------------------------------------------------------------------
-- Show inventory
------------------------------------------------------------------------

function ItemSelectUI:showItems(inventory: { [string]: number })
    -- Clear existing
    for _, child in self.scrollFrame:GetChildren() do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local hasItems = false
    for itemId, count in inventory do
        if count <= 0 then continue end
        hasItems = true

        local item = ItemDatabase.getItem(itemId)
        if not item then continue end

        local btn = Instance.new("TextButton")
        btn.Name = "Item_" .. itemId
        btn.Size = UDim2.new(0, 150, 0, 65)
        btn.BackgroundColor3 = UIConstants.Colors.ButtonDefault
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = self.scrollFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        -- Item name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -8, 0, 18)
        nameLabel.Position = UDim2.new(0, 4, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name
        nameLabel.TextColor3 = UIConstants.Colors.ButtonText
        nameLabel.Font = UIConstants.Font.Bold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = btn

        -- Count
        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(1, -8, 0, 14)
        countLabel.Position = UDim2.new(0, 4, 0, 26)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = "×" .. tostring(count)
        countLabel.TextColor3 = UIConstants.Colors.TextSecondary
        countLabel.Font = UIConstants.Font.Default
        countLabel.TextSize = 12
        countLabel.TextXAlignment = Enum.TextXAlignment.Left
        countLabel.Parent = btn

        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -8, 0, 14)
        descLabel.Position = UDim2.new(0, 4, 0, 44)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = item.description
        descLabel.TextColor3 = UIConstants.Colors.TextSecondary
        descLabel.Font = UIConstants.Font.Default
        descLabel.TextSize = 9
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextTruncate = Enum.TextTruncate.AtEnd
        descLabel.Parent = btn

        -- Hover / Click
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = UIConstants.Colors.ButtonHover
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = UIConstants.Colors.ButtonDefault
        end)
        btn.MouseButton1Click:Connect(function()
            if self.onItemSelected then self.onItemSelected(itemId) end
        end)
    end

    -- Empty state
    if not hasItems then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyLabel"
        emptyLabel.Size = UDim2.new(0, 200, 0, 60)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "No items available"
        emptyLabel.TextColor3 = UIConstants.Colors.TextSecondary
        emptyLabel.Font = UIConstants.Font.Default
        emptyLabel.TextSize = 14
        emptyLabel.Parent = self.scrollFrame
    end

    self.frame.Visible = true
end

------------------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------------------

function ItemSelectUI:show()
    self.frame.Visible = true
end

function ItemSelectUI:hide()
    self.frame.Visible = false
end

function ItemSelectUI:destroy()
    self.frame:Destroy()
end

return ItemSelectUI
