---@class AbstractFramework
local AF = _G.AbstractFramework

local tonumber = tonumber
local format, gsub, strlower, strupper, strsplit, strtrim = string.format, string.gsub, string.lower, string.upper, string.split, string.trim
local utf8len, len, utf8sub = string.utf8len, string.len, string.utf8sub
local strfind = string.find
local tinsert, tconcat = table.insert, table.concat

---------------------------------------------------------------------
-- string
---------------------------------------------------------------------
function AF.UpperFirst(str, lowerOthers)
    if AF.IsBlank(str) then return str end

    if lowerOthers then
        str = strlower(str)
    end
    return (str:gsub("^%l", strupper))
end

function AF.LowerFirst(str)
    if AF.IsBlank(str) then return str end
    return (str:gsub("^%u", strlower))
end

function AF.RemoveWhitespaces(str)
    if type(str) == "string" then
        return (str:gsub("%s+", ""))
    end
end

local function CapitalizeWord(space, firstChar, rest)
    return space .. strupper(firstChar) .. rest
end

function AF.UpperEachWord(str, lowerOthers)
    if AF.IsBlank(str) then return str end

    if lowerOthers then
        str = strlower(str)
    end

    -- %s matches whitespace
    -- %w matches alphanumeric chars
    -- %w* matches zero or more alphanumeric chars
    return (str:gsub("(%s?)(%w)(%w*)", CapitalizeWord))
end

function AF.SplitString(sep, str)
    if not str then return end

    local ret = {strsplit(sep, str)}
    for i, v in ipairs(ret) do
        ret[i] = tonumber(v) or ret[i] -- keep non number
    end
    return unpack(ret)
end

function AF.StringToTable(str, sep, convertToNum)
    local t = {}
    if str == "" then return t end
    assert(sep, "separator is nil")

    if convertToNum then
        for i, v in pairs({string.split(sep, str)}) do
            v = strtrim(v)
            tinsert(t, tonumber(v) or v)
        end
    else
        for i, v in pairs({string.split(sep, str)}) do
            tinsert(t, strtrim(v))
        end
    end
    return t
end

---@param t table
---@param sep string
---@param useKey boolean
---@param useValue boolean
function AF.TableToString(t, sep, useKey, useValue)
    if useKey or useValue then
        local str = ""
        for k, v in pairs(t) do
            if useKey and useValue then
                str = str .. k .. "=" .. v .. sep
            elseif useKey then
                str = str .. k .. sep
            elseif useValue then
                str = str .. v .. sep
            end
        end
        return str:sub(1, -(#sep + 1))
    else
        return tconcat(t, sep)
    end
end

function AF.IsBlank(str)
    if type(str) ~= "string" then
        return true
    end
    return str == "" or strtrim(str) == ""
end

function AF.GetNumStringLines(str)
    if str == "" then return 0 end

    local count = 0
    local i = 1
    while true do
        local start = strfind(str, "\n", i, true) -- plain search
        if not start then break end
        count = count + 1
        i = start + 1
    end
    return count + 1
end

---------------------------------------------------------------------
-- number format
---------------------------------------------------------------------
local abbr_1K, abbr_10K, abbr_100000K = "千", "万", "亿"
if LOCALE_zhTW then
    abbr_1K, abbr_10K, abbr_100000K = "千", "萬", "億"
elseif LOCALE_koKR then
    abbr_1K, abbr_10K, abbr_100000K = "천", "만", "억"
end

function AF.FormatNumber_Asian(n)
    if abs(n) >= 100000000 then
        return AF.RoundToDecimal(n / 100000000, 2) .. abbr_100000K
    elseif abs(n) >= 10000 then
        return AF.RoundToDecimal(n / 10000, 1) .. abbr_10K
    else
        return n
    end
end

function AF.FormatNumber(n)
    if abs(n) >= 1000000000 then
        return AF.RoundToDecimal(n / 1000000000, 2) .. "B"
    elseif abs(n) >= 1000000 then
        return AF.RoundToDecimal(n / 1000000, 2) .. "M"
    elseif abs(n) >= 1000 then
        return AF.RoundToDecimal(n / 1000, 1) .. "K"
    else
        return n
    end
end

---------------------------------------------------------------------
-- number format (secret)
---------------------------------------------------------------------
local AbbreviateNumbers = AbbreviateNumbers

local asianNumberAbbrevOptions = {
   breakpointData = {
      {breakpoint = 100000000, abbreviation = abbr_100000K, significandDivisor = 1000000, fractionDivisor = 100, abbreviationIsGlobal = false}, -- 1.23亿
      {breakpoint = 10000, abbreviation = abbr_10K, significandDivisor = 1000, fractionDivisor = 10, abbreviationIsGlobal = false}, -- 1.2万
   },
}

local westernNumberAbbrevOptions = {
   breakpointData = {
      {breakpoint = 1000000000, abbreviation = "B", significandDivisor = 10000000, fractionDivisor = 100, abbreviationIsGlobal = false}, -- 1.23B
      {breakpoint = 1000000, abbreviation = "M", significandDivisor = 10000, fractionDivisor = 100, abbreviationIsGlobal = false}, -- 1.23M
      {breakpoint = 1000, abbreviation = "K", significandDivisor = 100, fractionDivisor = 10, abbreviationIsGlobal = false}, -- 1.2K
   },
}

function AF.FormatSecretNumber_Asian(n)
    return AbbreviateNumbers(n, asianNumberAbbrevOptions)
end

function AF.FormatSecretNumber(n)
    return AbbreviateNumbers(n, westernNumberAbbrevOptions)
end

---------------------------------------------------------------------
-- money format
---------------------------------------------------------------------
local BreakUpLargeNumbers = BreakUpLargeNumbers
local GOLD_SYMBOL, SILVER_SYMBOL, COPPER_SYMBOL
local GOLD_ICON, SILVER_ICON, COPPER_ICON

---@param style string? "icon"|"symbol"|"nosuffix", default is "icon".
---@param goldOnly boolean?
function AF.FormatMoney(copper, style, useCommas, goldOnly)
    local gold = floor(copper / 10000)
    local silver = floor(copper / 100 - gold * 100)
    local copper = copper - gold * 10000 - silver * 100

    if useCommas then
        gold = BreakUpLargeNumbers(gold)
    end

    if style == "symbol" then
        if not GOLD_SYMBOL then
            GOLD_SYMBOL = AF.WrapTextInColor(_G.GOLD_AMOUNT_SYMBOL, "coin_gold")
            SILVER_SYMBOL = AF.WrapTextInColor(_G.SILVER_AMOUNT_SYMBOL, "coin_silver")
            COPPER_SYMBOL = AF.WrapTextInColor(_G.COPPER_AMOUNT_SYMBOL, "coin_copper")
        end

        if goldOnly then
            return format("%s%s", gold, GOLD_SYMBOL)
        else
            return format("%s%s %d%s %d%s", gold, GOLD_SYMBOL, silver, SILVER_SYMBOL, copper, COPPER_SYMBOL)
        end

    elseif style == "nosuffix" then
        if goldOnly then
            return AF.WrapTextInColor(gold, "coin_gold")
        else
            return format("%s %s %s", AF.WrapTextInColor(gold, "coin_gold"), AF.WrapTextInColor(silver, "coin_silver"), AF.WrapTextInColor(copper, "coin_copper"))
        end

    else
        if not GOLD_ICON then
            GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
            SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
            COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"
        end

        if goldOnly then
            return format("%s%s", gold, GOLD_ICON)
        else
            return format("%s%s %d%s %d%s", gold, GOLD_ICON, silver, SILVER_ICON, copper, COPPER_ICON)
        end
    end
end

---------------------------------------------------------------------
-- truncation
---------------------------------------------------------------------

---@param s string if s contains only English characters, it will be truncated by enChars, otherwise by nonEnChars.
---@param enChars number number of English characters
---@param nonEnChars number number of non-English characters
---@return string
function AF.TruncateStringByLength(s, enChars, nonEnChars)
    if AF.IsBlank(s) then return s end

    local len1 = len(s)
    local len2 = utf8len(s)
    local ret = s

    if len1 ~= len2 then
        if nonEnChars and nonEnChars > 0 and len2 > nonEnChars then
            ret = utf8sub(s, 1, nonEnChars)
        end
    else
        if enChars and enChars > 0 and len1 > enChars then
            ret =  utf8sub(s, 1, enChars)
        end
    end

    return ret
end