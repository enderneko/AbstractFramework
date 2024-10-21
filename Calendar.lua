---@class AbstractWidgets
local AW = _G.AbstractWidgets

-- NOTE: override these before create calendar
AW.FIRST_WEEKDAY = 1
AW.WEEKDAY_NAMES = {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
if GetCVar("portal") == "US" then
    AW.RAID_LOCKOUT_RESET_DAY = 2
elseif GetCVar("portal") == "EU" then
    AW.RAID_LOCKOUT_RESET_DAY = 3
else
    AW.RAID_LOCKOUT_RESET_DAY = 4
end

---------------------------------------------------------------------
-- utils
---------------------------------------------------------------------
local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

local function IsLeapYear(year)
    return year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)
end

local function GetMonthInfo(year, month)
    local numDays, firstWeekday
    if month == 2 and IsLeapYear(year) then
        numDays = 29
    else
        numDays = days_in_month[month]
    end
    firstWeekday = tonumber(date("%u", time{["day"]=1, ["month"]=month, ["year"]=year}))
    return numDays, firstWeekday
end

---------------------------------------------------------------------
-- calendar
---------------------------------------------------------------------
local MIN_YEAR, MAX_YEAR = 2020, 2040
local calendar

local function FillDays(year, month)
    local numDays, firstWeekday = GetMonthInfo(year, month)
    local start = (firstWeekday >= AW.FIRST_WEEKDAY) and (firstWeekday - AW.FIRST_WEEKDAY + 1) or (7 - AW.FIRST_WEEKDAY + 1 + firstWeekday)

    local day = 1
    for i, b in ipairs(calendar.days) do
        if i >= start and i < start + numDays then
            b.id = day --! for button group
            b:SetEnabled(true)
            b:SetText(day)

            -- date highlights
            local str = string.format("%04d%02d%02d", calendar.date.year, calendar.date.month, day)
            if calendar.info[str] then
                b.tooltips = calendar.info[str].tooltips
                b.mark:SetColor(calendar.info[str].color)
                b.mark:Show()
            else
                b.mark:Hide()
            end

            day = day + 1
        else
            b.id = -1 --! for button group
            b.tooltips = nil
            b.mark:Hide()
            b:SetEnabled(false)
            b:SetText("")
        end
    end

    -- show "today" mark
    local today = date("*t")
    if month == today.month and year == today.year then
        calendar.todayMark:SetParent(calendar.days[start+today.day-1])
        AW.ClearPoints(calendar.todayMark)
        AW.SetPoint(calendar.todayMark, "BOTTOM", 0, 3)
        calendar.todayMark:Show()
    else
        calendar.todayMark:Hide()
    end

    -- highlight selected day
    local selected = date("*t", calendar.date.timestamp)
    if year == selected.year and month == selected.month then
        calendar.highlight(selected.day)
    else
        calendar.highlight()
    end

    -- update previous/next
    calendar.previous:SetEnabled(not (year == MIN_YEAR and month == 1))
    calendar.next:SetEnabled(not (year == MAX_YEAR and month == 12))
end

local function CreateCalendar()
    calendar = AW.CreateBorderedFrame(AW.UIParent, nil, 185, 167, nil, "accent")
    calendar:SetClampedToScreen(true)
    calendar:EnableMouse(true)

    -- year dropdown
    local year = AW.CreateDropdown(calendar, 65, 7, nil, true)
    calendar.year = year
    local items = {}
    for i = MIN_YEAR, MAX_YEAR do
        tinsert(items, {
            ["text"] = i,
            ["onClick"] = function()
                calendar.date.year = i
                FillDays(calendar.date.year, calendar.date.month)
            end,
        })
    end
    year:SetItems(items)

    -- month dropdown
    local month = AW.CreateDropdown(calendar, 51, 7, nil, true)
    calendar.month = month
    items = {}
    for i = 1, 12 do
        -- local name = CALENDAR_FULLDATE_MONTH_NAMES[i] -- needs utf8sub
        tinsert(items, {
            ["text"] = i,
            ["onClick"] = function()
                calendar.date.month = i
                FillDays(calendar.date.year, calendar.date.month)
            end,
        })
    end
    month:SetItems(items)

    -- previous month
    local previous = AW.CreateButton(calendar, nil, "accent_hover", 35, 20)
    calendar.previous = previous
    previous:SetTexture(AW.GetIcon("ArrowLeft"), {16, 16}, {"CENTER", 0, 0})
    previous:SetScript("OnClick", function()
        calendar.date.month = calendar.date.month - 1
        if calendar.date.month == 0 then
            calendar.date.month = 12
            calendar.date.year = calendar.date.year - 1
            year:SetSelectedValue(calendar.date.year)
        end
        FillDays(calendar.date.year, calendar.date.month)
        month:SetSelectedValue(calendar.date.month)
    end)
    AW.RegisterForCloseDropdown(previous)

    -- next month
    local next = AW.CreateButton(calendar, nil, "accent_hover", 35, 20)
    calendar.next = next
    next:SetTexture(AW.GetIcon("ArrowRight"), {16, 16}, {"CENTER", 0, 0})
    next:SetScript("OnClick", function()
        calendar.date.month = calendar.date.month + 1
        if calendar.date.month == 13 then
            calendar.date.month = 1
            calendar.date.year = calendar.date.year + 1
            year:SetSelectedValue(calendar.date.year)
        end
        FillDays(calendar.date.year, calendar.date.month)
        month:SetSelectedValue(calendar.date.month)
    end)
    AW.RegisterForCloseDropdown(next)

    AW.SetPoint(previous, "TOPLEFT", 1, -1)
    AW.SetPoint(next, "TOPRIGHT", -1, -1)
    AW.SetPoint(year, "TOPLEFT", previous, "TOPRIGHT", -1, 0)
    AW.SetPoint(month, "TOPLEFT", year, "TOPRIGHT", -1, 0)
    AW.SetPoint(month, "TOPRIGHT", next, "TOPLEFT", 1, 0)

    -- headers
    local headers = {}
    calendar.headers = headers
    for i = 1, 7 do
        headers[i] = AW.CreateBorderedFrame(calendar, nil, 27, 20, "widget", "black")

        local weekday
        if AW.FIRST_WEEKDAY+(i-1)>7 then
            weekday = AW.FIRST_WEEKDAY+(i-1)-7
        else
            weekday = AW.FIRST_WEEKDAY+(i-1)
        end
        headers[i].weekday = weekday

        local name = AW.L[AW.WEEKDAY_NAMES[weekday]]
        headers[i].text = AW.CreateFontString(headers[i], name)
        AW.SetPoint(headers[i].text, "CENTER")

        -- highlight raid lockout reset day
        if weekday == AW.RAID_LOCKOUT_RESET_DAY then
            headers[i].text:SetColor("accent")
        end

        if i == 1 then
            AW.SetPoint(headers[i], "TOPLEFT", 1, -26)
        else
            AW.SetPoint(headers[i], "TOPLEFT", headers[i-1], "TOPRIGHT", -1, 0)
        end
    end

    -- days
    local days = {}
    calendar.days = days
    for i = 1, 42 do
        days[i] = AW.CreateButton(calendar, "", "accent_hover", 27, 20)

        -- mark
        days[i].mark = AW.CreateTexture(days[i], AW.GetIcon("Mark"))
        AW.SetSize(days[i].mark, 8, 8)
        AW.SetPoint(days[i].mark, "TOPRIGHT", -1, -1)
        days[i].mark:Hide()

        if i == 1 then
            AW.SetPoint(days[i], "TOPLEFT", 1, -51)
        elseif i % 7 == 1 then
            AW.SetPoint(days[i], "TOPLEFT", days[i-7], "BOTTOMLEFT", 0, 1)
        else
            AW.SetPoint(days[i], "TOPLEFT", days[i-1], "TOPRIGHT", -1, 0)
        end
    end

    calendar.highlight = AW.CreateButtonGroup(days, function(d)
        calendar.date.day = d
        calendar.parent:SetDate(calendar.date)
        calendar.date.timestamp = calendar.parent.date.timestamp
        if calendar.onDateChanged then
            calendar.onDateChanged(calendar.date)
        end
        calendar:Hide()
    end, nil, nil, function(self)
        AW.ShowTooltips(self, "TOPLEFT", 0, 2, self.tooltips)
    end, AW.HideTooltips)

    -- "today" mark
    local todayMark = AW.CreateTexture(calendar, nil, "gray")
    calendar.todayMark = todayMark
    AW.SetSize(todayMark, 17, 1)

    -- scripts
    calendar:SetScript("OnMouseWheel", function() end)
    calendar:SetScript("OnHide", function()
        calendar:Hide()
    end)

    -- override UpdatePixels
    -- update size, make it pixel perfect
    function calendar:UpdatePixels()
        AW.RePoint(calendar)
        AW.ReBorder(calendar)

        -- height
        local height1 = AW.ConvertPixelsForRegion(51, calendar) + AW.ConvertPixelsForRegion(1, calendar)
        local height2 = AW.ConvertPixelsForRegion(20, calendar) * 6
        local height3 = AW.ConvertPixelsForRegion(1, calendar) * 5
        calendar:SetHeight(height1 + height2 - height3)

        -- width
        local width1 = AW.ConvertPixelsForRegion(1, calendar) * 2
        local width2 = AW.ConvertPixelsForRegion(27, calendar) * 7
        local width3 = AW.ConvertPixelsForRegion(1, calendar) * 6
        calendar:SetWidth(width1 + width2 - width3)
    end

    -- set date
    calendar.date = {}
    function calendar:SetDate(date)
        calendar.date.year = date.year
        calendar.date.month = date.month
        calendar.date.day = date.day
        calendar.date.timestamp = date.timestamp
        calendar.year:SetSelectedValue(date.year)
        calendar.month:SetSelectedValue(date.month)
        FillDays(date.year, date.month, date.day)
    end
end

local function ShowCalendar(parent, date, info, position, onDateChanged)
    if not calendar then CreateCalendar() end
    if calendar:IsShown() and calendar:GetParent() == parent then
        calendar:Hide()
        return
    end

    calendar.parent = parent
    calendar.onDateChanged = onDateChanged
    calendar.info = info

    calendar:SetDate(date)
    calendar:SetParent(parent)
    AW.SetFrameLevel(calendar, 20)
    calendar:Show()

    AW.ClearPoints(calendar)
    if position == "BOTTOMLEFT" then
        AW.SetPoint(calendar, "TOPLEFT", parent, "BOTTOMLEFT", 0, -5)
    elseif position == "BOTTOMRIGHT" then
        AW.SetPoint(calendar, "TOPRIGHT", parent, "BOTTOMRIGHT", 0, -5)
    elseif position == "TOPLEFT" then
        AW.SetPoint(calendar, "BOTTOMLEFT", parent, "TOPLEFT", 0, 5)
    else -- TOPRIGHT
        AW.SetPoint(calendar, "BOTTOMRIGHT", parent, "TOPRIGHT", 0, 5)
    end
end

---------------------------------------------------------------------
-- date widget
---------------------------------------------------------------------
-- https://strftime.net/
-- %a  abbreviated weekday name (e.g., Wed)
-- %A  full weekday name (e.g., Wednesday)
-- %b  abbreviated month name (e.g., Sep)
-- %B  full month name (e.g., September)
-- %c  date and time (e.g., 09/16/98 23:48:10)
-- %d  day of the month (16) [01-31]
-- %H  hour, using a 24-hour clock (23) [00-23]
-- %I  hour, using a 12-hour clock (11) [01-12]
-- %M  minute (48) [00-59]
-- %m  month (09) [01-12]
-- %p  either "am" or "pm" (pm)
-- %S  second (10) [00-61]
-- %w  weekday (3) [0-6 = Sunday-Saturday]
-- %x  date (e.g., 09/16/98)
-- %X  time (e.g., 23:48:10)
-- %Y  full year (1998)
-- %y  two-digit year (98) [00-99]

--- @param date string|number|table "YYYYMMDD", a epoch unix timestamp in seconds, or a "*t" table
function AW.CreateDateWidget(parent, date, width, calendarPosition)
    local w = AW.CreateButton(parent, "", "accent", width or 110, 20)
    w:SetTexture(AW.GetIcon("Calendar"), {16, 16},  {"LEFT", 2, 0})

    w.date = {} -- save show date info
    w.info = { -- store dates with extra info
        -- ["20240214"] = {
        --     ["tooltips"] = {strings},
        --     ["color"] = (string), -- in Color.lua
        -- },
    }

    function w:SetDate(d)
        local t
        if type(d) == "string" then
            local _y, _m, _d = d:match("(%d%d%d%d)(%d%d)(%d%d)")
            w.date.year = tonumber(_y)
            w.date.month = tonumber(_m)
            w.date.day = tonumber(_d)
            w.date.timestamp = time{year=_y, month=_m, day=_d}
        elseif type(d) == "number" then
            local dt = _G.date("*t", d)
            w.date.year = dt.year
            w.date.month = dt.month
            w.date.day = dt.day
            w.date.timestamp = time(w.date)
        elseif type(d) == "table" then
            w.date.year = d.year
            w.date.month = d.month
            w.date.day = d.day
            w.date.timestamp = time(w.date)
        end
        w:SetText(w.date.year.."/"..w.date.month.."/"..w.date.day)
    end
    w:SetDate(date or time())

    function w:SetMarksForDays(info)
        w.info = info
    end

    function w:SetOnDateChanged(onDateChanged)
        w.onDateChanged = onDateChanged
    end

    w:SetScript("OnClick", function()
        ShowCalendar(w, w.date, w.info, calendarPosition, w.onDateChanged)
    end)

    AW.RegisterForCloseDropdown(w)

    return w
end