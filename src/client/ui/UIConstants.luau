--[[
    UIConstants.luau
    Centralized color palette, font settings, sizing, and animation
    durations for all battle UI components.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ElementTypes = require(Shared:WaitForChild("ElementTypes"))

local UIConstants = {}

------------------------------------------------------------------------
-- Colors
------------------------------------------------------------------------

UIConstants.Colors = {
    -- Backgrounds
    BattleBg         = Color3.fromRGB(20, 22, 30),
    PanelBg          = Color3.fromRGB(30, 34, 45),
    PanelBorder      = Color3.fromRGB(55, 60, 80),
    ActionPanelBg    = Color3.fromRGB(25, 28, 38),

    -- HP bar
    HpFull           = Color3.fromRGB(50, 205, 80),
    HpMid            = Color3.fromRGB(230, 200, 40),
    HpLow            = Color3.fromRGB(220, 55, 55),
    HpBarBg          = Color3.fromRGB(50, 50, 60),

    -- MP bar
    MpBar            = Color3.fromRGB(70, 130, 230),
    MpBarBg          = Color3.fromRGB(40, 45, 65),

    -- XP bar
    XpBar            = Color3.fromRGB(100, 200, 255),
    XpBarBg          = Color3.fromRGB(40, 45, 65),

    -- Buttons
    ButtonDefault    = Color3.fromRGB(50, 55, 75),
    ButtonHover      = Color3.fromRGB(70, 80, 110),
    ButtonPressed    = Color3.fromRGB(40, 45, 60),
    ButtonDisabled   = Color3.fromRGB(35, 38, 48),
    ButtonText       = Color3.fromRGB(230, 235, 245),
    ButtonTextDim    = Color3.fromRGB(120, 125, 140),

    -- Battle log
    LogBg            = Color3.fromRGB(18, 20, 28),
    LogText          = Color3.fromRGB(200, 205, 220),
    LogHighlight     = Color3.fromRGB(255, 220, 100),

    -- General text
    TextPrimary      = Color3.fromRGB(240, 242, 250),
    TextSecondary    = Color3.fromRGB(160, 165, 180),
    TextDamage       = Color3.fromRGB(255, 90, 70),
    TextHeal         = Color3.fromRGB(80, 220, 120),
    TextSuperEff     = Color3.fromRGB(255, 180, 50),
    TextNotEff       = Color3.fromRGB(130, 140, 160),

    -- Transition
    TransitionBg     = Color3.fromRGB(5, 5, 10),
}

-- Element colors (re-exported for convenience)
UIConstants.ElementColors = ElementTypes.Colors

------------------------------------------------------------------------
-- Fonts
------------------------------------------------------------------------

UIConstants.Font = {
    Default   = Enum.Font.GothamMedium,
    Bold      = Enum.Font.GothamBold,
    Header    = Enum.Font.GothamBlack,
    Mono      = Enum.Font.RobotoMono,
}

------------------------------------------------------------------------
-- Sizes
------------------------------------------------------------------------

UIConstants.Size = {
    -- HP/MP bar dimensions
    BarWidth       = UDim2.new(0.85, 0, 0, 10),
    BarHeight      = 10,

    -- Creature info plate
    PlateWidth     = UDim2.new(0, 280, 0, 90),

    -- Action buttons
    ButtonSize     = UDim2.new(0, 140, 0, 45),
    ButtonCorner   = UDim.new(0, 8),

    -- Battle log
    LogHeight      = UDim2.new(0, 80),

    -- General corner rounding
    CornerRadius   = UDim.new(0, 6),
    CornerRadiusLg = UDim.new(0, 10),
}

------------------------------------------------------------------------
-- Animation durations (seconds)
------------------------------------------------------------------------

UIConstants.Anim = {
    BarDrain       = 0.5,     -- HP/MP bar tween time
    ButtonHover    = 0.15,    -- button color transition
    TransitionIn   = 0.4,     -- encounter transition fade in
    TransitionHold = 1.2,     -- how long to show "appeared" text
    TransitionOut  = 0.4,     -- fade out
    MessageDelay   = 0.6,     -- delay between battle log messages
    FaintFlash     = 0.3,     -- flash on faint
}

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

--- Get HP bar color based on HP percentage.
function UIConstants.getHpColor(ratio: number): Color3
    if ratio > 0.5 then
        return UIConstants.Colors.HpFull
    elseif ratio > 0.2 then
        return UIConstants.Colors.HpMid
    else
        return UIConstants.Colors.HpLow
    end
end

--- Get element color with fallback.
function UIConstants.getElementColor(element: string): Color3
    return ElementTypes.getColor(element)
end

return UIConstants
