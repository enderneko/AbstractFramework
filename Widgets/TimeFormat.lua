---@class AbstractFramework
local AF = select(2, ...)
local L = AF.L

local TAGS = {
    "%Y:Year:2027", -- 2027
    "%y:Year:27", -- 27
    "%m:Month:12", -- 01-12
    "%B:Month:December", -- January-December
    "%b:Month:Dec", -- Jan-Dec
    "%d:Day:07", -- 01-31
    -- "%e:Day", -- 1-31
    "%A:Weekday:Tuesday", -- Sunday-Saturday
    "%a:Weekday:Tue", -- Sun-Sat
    -- "%W:Week (Monday First)", -- 00-53
    -- "%U:Week (Sunday First)", -- 00-53
    "%p:AM/PM", -- AM/PM
    "%P:am/pm", -- am/pm
    "%H:Hour:20", -- 00-23
    "%I:Hour:08", -- 01-12
    "%M:Minute:07", -- 00-59
    "%S:Second:07", -- 00-59
    -- "%z:Timezone:+0800", -- +0800
    -- "%Z:Timezone:China Standard Time", -- China Standard Time
    -- "%F:ISO 8601", -- 2027-12-07
    -- "%D:US date", -- 12/07/27
    -- "%c:Locale date and time", -- Tue Dec 7 14:23:45 2027
    -- "%v:VMS date", -- 07-Dec-2027
}

local cached = {}
local function GetTagsText()
    local color = AF.GetAddonAccentColorName()
    if cached[color] then
        return cached[color]
    end

    cached[color] = {}
    for _, info in next, TAGS do
        local tag, name, example = strsplit(":", info)
        tinsert(cached[color],
            AF.WrapTextInColor(tag, color) .. " " .. L[name] ..
            (example and (" " .. AF.WrapTextInColor(example, "tip")) or "")
        )
    end
    cached[color] = table.concat(cached[color], "\n")
    return cached[color]
end

-- local DELIMITERS = {"/", "-", "+", ",", ".", ":", "space"}
-- local BRACKETS = {"[", "]", "<", ">", "(", ")"}

---------------------------------------------------------------------
-- Time Format Tips
---------------------------------------------------------------------
local timeFormatTips

local function CreateTimeFormatTips()
    timeFormatTips = AF.CreateBorderedFrame(AF.UIParent, nil, 200, 100, nil, "accent")
    timeFormatTips:SetClampedToScreen(true)
    timeFormatTips:Hide()

    timeFormatTips:SetOnHide(function()
        timeFormatTips:Hide()
    end)

    local text = AF.CreateFontString(timeFormatTips)
    timeFormatTips.text = text
    AF.SetPoint(text, "TOPLEFT", 7, -7)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
end

local function ShowTimeFormatTips(owner)
    if not timeFormatTips then CreateTimeFormatTips() end

    timeFormatTips.owner = owner
    timeFormatTips.callback = callback

    -- accent color system
    timeFormatTips:SetBackdropBorderColor(AF.GetColorRGB(owner.accentColor))

    AF.ClearPoints(timeFormatTips)
    if owner.tipsPosition == "BOTTOMLEFT" then
        AF.SetPoint(timeFormatTips, "TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    elseif owner.tipsPosition == "BOTTOMRIGHT" then
        AF.SetPoint(timeFormatTips, "TOPRIGHT", owner, "BOTTOMRIGHT", 0, -2)
    elseif owner.tipsPosition == "TOPRIGHT" then
        AF.SetPoint(timeFormatTips, "BOTTOMRIGHT", owner, "TOPRIGHT", 0, 2)
    else -- TOPLEFT
        AF.SetPoint(timeFormatTips, "BOTTOMLEFT", owner, "TOPLEFT", 0, 2)
    end

    timeFormatTips:SetParent(owner)
    AF.SetFrameLevel(timeFormatTips, 20)
    timeFormatTips:UpdatePixels()
    timeFormatTips:Show()
end

local function UpdateTimeFormatTips(owner)
    if timeFormatTips and timeFormatTips.owner == owner then
        local str = GetTagsText()
        local fmt = owner:GetText()
        local success
        if not AF.IsBlank(fmt) then
            success,fmt = pcall(date, fmt)
            if success then
                str = str .. "\n\n" .. AF.WrapTextInColor(fmt, "softlime")
            end
        end
        timeFormatTips.text:SetText(str)
        AF.ResizeToFitText(timeFormatTips, timeFormatTips.text, 7, 7)
    end
end

local function HideTimeFormatTips(owner)
    if timeFormatTips and timeFormatTips.owner == owner then
        timeFormatTips:Hide()
    end
end

---------------------------------------------------------------------
-- Time Format Box
---------------------------------------------------------------------
---@class AF_TimeFormatBox:AF_EditBox
local AF_TimeFormatBoxMixin = {}

--- same as SetText
function AF_TimeFormatBoxMixin:SetValue(value)
    self:SetText(value)
end

---@param onFormatChanged fun(value:string)
function AF_TimeFormatBoxMixin:SetOnFormatChanged(onFormatChanged)
    self.onFormatChanged = onFormatChanged
end

local function OnEditFocusGained(self)
    ShowTimeFormatTips(self)
    UpdateTimeFormatTips(self)
end

local function OnEditFocusLost(self)
    HideTimeFormatTips(self)
end

local function OnTextChanged(value, _, self)
    if self.onFormatChanged then
        self.onFormatChanged(value)
    end
    AF.DelayedInvoke(0.5, UpdateTimeFormatTips, self)
end

---@param parent Frame
---@param width number|nil
---@param tipsPosition "BOTTOMLEFT"|"BOTTOMRIGHT"|"TOPLEFT"|"TOPRIGHT"|nil default is "TOPLEFT"
---@return AF_TimeFormatBox pane
function AF.CreateTimeFormatBox(parent, width, tipsPosition)
    local box = AF.CreateEditBox(parent, nil, width or 150, 20)
    Mixin(box, AF_TimeFormatBoxMixin)

    box:SetOnEditFocusGained(OnEditFocusGained)
    box:SetOnEditFocusLost(OnEditFocusLost)
    box:SetOnTextChanged(OnTextChanged)

    return box
end