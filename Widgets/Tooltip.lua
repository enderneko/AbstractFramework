---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- show / hide
---------------------------------------------------------------------
local anchorOverride = {
    ["LEFT"] = "RIGHT",
    ["RIGHT"] = "LEFT",
    ["BOTTOMLEFT"] = "TOPLEFT",
    ["BOTTOMRIGHT"] = "TOPRIGHT",
}

---@param widget Frame
---@param anchor string
---@param x number
---@param y number
---@param lines string[]
function AF.ShowTooltips(widget, anchor, x, y, lines)
    local tooltip = _G["AFTooltip"]

    if type(lines) ~= "table" or #lines == 0 then
        tooltip:Hide()
        return
    end

    tooltip:SetParent(widget)
    AF.ReBorder(tooltip)

    x = AF.ConvertPixelsForRegion(x, tooltip)
    y = AF.ConvertPixelsForRegion(y, tooltip)

    tooltip:ClearLines()

    if anchorOverride[anchor] then
        tooltip:SetOwner(widget, "ANCHOR_NONE")
        tooltip:SetPoint(anchorOverride[anchor], widget, anchor, x, y)
    else
        if anchor and not strfind(anchor, "^ANCHOR_") then anchor = "ANCHOR_" .. anchor end
        tooltip:SetOwner(widget, anchor or "ANCHOR_TOP", x or 0, y or 0)
    end

    local r, g, b = AF.GetColorRGB("accent")
    tooltip:AddLine(lines[1], r, g, b)
    for i = 2, #lines do
        if type(lines[i]) == "string" then
            tooltip:AddLine(lines[i], 1, 1, 1, true)
        elseif type(lines[i]) == "table" then
            tooltip:AddDoubleLine(lines[i][1], lines[i][2], 1, 0.82, 0, 1, 1, 1)
        end
    end

    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetToplevel(true)
    -- tooltip:SetCustomLineSpacing(5)
    tooltip:SetCustomWordWrapMinWidth(300)
    tooltip:Show()
end

---@param widget Frame
---@param anchor string
---@param x number
---@param y number
---@param ... string
function AF.SetTooltips(widget, anchor, x, y, ...)
    if type(select(1, ...)) == "table" then
        widget._tooltips = ...
    else
        widget._tooltips = {...}
    end
    widget._tooltipsAnchor = anchor
    widget._tooltipsX = x
    widget._tooltipsY = y

    if not widget._tooltipsInited then
        widget._tooltipsInited = true

        widget:HookScript("OnEnter", function()
            AF.ShowTooltips(widget, anchor, x, y, widget._tooltips)
        end)
        widget:HookScript("OnLeave", function()
            _G["AFTooltip"]:Hide()
        end)
    end
end

function AF.ClearTooltips(widget)
    widget._tooltips = nil
end

function AF.HideTooltips()
    _G["AFTooltip"]:Hide()
end

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local GetItemIconByID = C_Item.GetItemIconByID
local GetSpellTexture = C_Spell.GetSpellTexture
local GetItemQualityByID = C_Item.GetItemQualityByID

local function GameTooltip_OnHide(self)
    self.waitingForData = false
    GameTooltip_ClearMoney(self)
    GameTooltip_ClearStatusBars(self)
    GameTooltip_ClearProgressBars(self)
    GameTooltip_ClearWidgetSet(self)
    TooltipComparisonManager:Clear(self)

    GameTooltip_HideBattlePetTooltip()

    if self.ItemTooltip then
        EmbeddedItemTooltip_Hide(self.ItemTooltip)
    end
    self:SetPadding(0, 0, 0, 0)

    self:ClearHandlerInfo()

    GameTooltip_ClearStatusBars(self)
    GameTooltip_ClearStatusBarWatch(self)
end

---@class AF_Tooltip:GameTooltip
local AF_TooltipMixin = {}

function AF_TooltipMixin:UpdatePixels()
    AF.ReBorder(self)
    if self.icon then
        AF.RePoint(self.iconBG)
        AF.RePoint(self.icon)
    end
end

function AF_TooltipMixin:OnHide()
    AF.ClearPoints(self)
    GameTooltip_OnHide(self)

    -- reset border color
    self:SetBackdropBorderColor(AF.GetColorRGB("accent"))

    -- SetX with invalid data may or may not clear the tooltip's contents.
    self:ClearLines()

    if self.icon then
        self.iconBG:Hide()
        self.icon:Hide()
    end
end

function AF_TooltipMixin:OnShow()
    self:UpdatePixels()
end

function AF_TooltipMixin:SetItem(itemID, icon)
    self:SetItemByID(itemID)

    local quality = GetItemQualityByID(itemID)
    if quality then
        self:SetBackdropBorderColor(AF.GetItemQualityColor(quality))
    end

    if icon == true then
        icon = GetItemIconByID(itemID)
    end

    if icon then
        if not self.icon then
            self:SetupIcon("TOPRIGHT", "TOPLEFT", -1, 0)
        end
        self.iconBG:Show()
        self.icon:SetTexture(icon)
        self.icon:Show()
    else
        self.iconBG:Hide()
        self.icon:Hide()
    end

    self:Show()
end

function AF_TooltipMixin:SetSpell(spellID, icon)
    self:SetSpellByID(spellID)

    if icon == true then
        icon = GetSpellTexture(spellID)
    end

    if icon then
        if not self.icon then
            self:SetupIcon("TOPRIGHT", "TOPLEFT", -1, 0)
        end
        self.iconBG:Show()
        self.icon:SetTexture(icon)
        self.icon:Show()
    else
        self.iconBG:Hide()
        self.icon:Hide()
    end

    self:Show()
end

function AF_TooltipMixin:SetupIcon(point, relativePoint, x, y)
    if not self.icon then
        local iconBG = self:CreateTexture(nil, "BORDER")
        self.iconBG = iconBG
        iconBG:SetColorTexture(AF.GetColorRGB("accent"))
        AF.SetSize(iconBG, 35, 35)
        iconBG:Hide()

        local icon = self:CreateTexture(nil, "ARTWORK")
        self.icon = icon
        AF.SetOnePixelInside(icon, iconBG)
        AF.ApplyDefaultTexCoord(icon)
        icon:Hide()

        hooksecurefunc(self, "SetBackdropBorderColor", function(self, r, g, b)
            self.iconBG:SetColorTexture(r, g, b)
        end)
    end

    AF.ClearPoints(self.iconBG)
    AF.SetPoint(self.iconBG, point, self, relativePoint, x, y)
end

---@return AF_Tooltip
local function CreateTooltip(name)
    ---@type AF_Tooltip
    local tooltip = CreateFrame("GameTooltip", name, AF.UIParent, "AFTooltipTemplate,BackdropTemplate")
    -- local tooltip = CreateFrame("GameTooltip", name, AF.UIParent, "SharedTooltipTemplate,BackdropTemplate")
    AF.ApplyDefaultBackdrop(tooltip)
    tooltip:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    tooltip:SetBackdropBorderColor(AF.GetColorRGB("accent"))
    tooltip:SetOwner(AF.UIParent, "ANCHOR_NONE")

    Mixin(tooltip, AF_BaseWidgetMixin)
    Mixin(tooltip, AF_TooltipMixin)

    if AF.isRetail then
        tooltip:RegisterEvent("TOOLTIP_DATA_UPDATE")
        tooltip:SetScript("OnEvent", function()
            if tooltip:IsVisible() then
                -- Interface\FrameXML\GameTooltip.lua GameTooltipDataMixin:RefreshData()
                tooltip:RefreshData()
            end
        end)
    end

    -- tooltip:SetScript("OnTooltipSetItem", function()
    --     -- color border with item quality color
    --     tooltip:SetBackdropBorderColor(_G[name.."TextLeft1"]:GetTextColor())
    -- end)

    tooltip:SetOnHide(tooltip.OnHide)
    tooltip:SetOnShow(tooltip.OnShow)

    AF.AddToPixelUpdater(tooltip)

    return tooltip
end

AF.Tooltip = CreateTooltip("AFTooltip")
AF.IconTooltip = CreateTooltip("AFIconTooltip")
AF.IconTooltip:SetupIcon("TOPRIGHT", "TOPLEFT", -1, 0)