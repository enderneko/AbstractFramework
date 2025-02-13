---@class AbstractFramework
local AF = _G.AbstractFramework

local select, type, tonumber = select, type, tonumber
local floor, ceil, abs, max, min = math.floor, math.ceil, math.abs, math.max, math.min
local format, gsub, strlower, strupper, strsplit = string.format, string.gsub, string.lower, string.upper, string.split
local next, pairs, ipairs = next, pairs, ipairs
local tinsert, tremove, tsort, tconcat = table.insert, table.remove, table.sort, table.concat

---------------------------------------------------------------------
-- misc
---------------------------------------------------------------------
function AF.Unpack2(t)
    return t[1], t[2]
end

function AF.Unpack3(t)
    return t[1], t[2], t[3]
end

function AF.Unpack4(t)
    return t[1], t[2], t[3], t[4]
end

function AF.Unpack5(t)
    return t[1], t[2], t[3], t[4], t[5]
end

function AF.Unpack6(t)
    return t[1], t[2], t[3], t[4], t[5], t[6]
end

function AF.Unpack7(t)
    return t[1], t[2], t[3], t[4], t[5], t[6], t[7]
end

function AF.Round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces >= 0 then
        local mult = 10 ^ numDecimalPlaces
        return floor(num * mult + 0.5) / mult
    end
    return floor(num + 0.5)
end

function AF.Interpolate(start, stop, step, maxSteps)
    return start + (stop - start) * step / maxSteps
end

---------------------------------------------------------------------
-- number
---------------------------------------------------------------------
local symbol_1K, symbol_10K, symbol_1B = "", "", ""
if LOCALE_zhCN then
    symbol_1K, symbol_10K, symbol_1B = "千", "万", "亿"
elseif LOCALE_zhTW then
    symbol_1K, symbol_10K, symbol_1B = "千", "萬", "億"
elseif LOCALE_koKR then
    symbol_1K, symbol_10K, symbol_1B = "천", "만", "억"
end

function AF.FormatNumber_Asian(n)
    if abs(n) >= 100000000 then
        return tonumber(format("%.2f", n/100000000)) .. symbol_1B
    elseif abs(n) >= 10000 then
        return tonumber(format("%.2f", n/10000)) .. symbol_10K
    -- elseif abs(n) >= 1000 then
    --     return tonumber(format("%.1f", n/1000)) .. symbol_1K
    else
        return n
    end
end

function AF.FormatNumber(n)
    if abs(n) >= 1000000000 then
        return tonumber(format("%.2f", n/1000000000)) .. "B"
    elseif abs(n) >= 1000000 then
        return tonumber(format("%.2f", n/1000000)) .. "M"
    elseif abs(n) >= 1000 then
        return tonumber(format("%.1f", n/1000)) .. "K"
    else
        return n
    end
end

AF.epsilon = 0.001

function AF.ApproxEqual(a, b, epsilon)
    return abs(a - b) <= (epsilon or AF.epsilon)
end

function AF.ApproxZero(n)
    return AF.ApproxEqual(n, 0)
end

function AF.Round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces >= 0 then
        local mult = 10 ^ numDecimalPlaces
        return floor(num * mult + 0.5) / mult
    end
    return floor(num + 0.5)
end

function AF.Clamp(value, minValue, maxValue)
    maxValue = max(minValue, maxValue) -- to ensure maxValue >= minValue
    if value > maxValue then
        return maxValue
    elseif value < minValue then
        return minValue
    end
    return value
end

---------------------------------------------------------------------
-- string
---------------------------------------------------------------------
function AF.UpperFirst(str, lowerOthers)
    if lowerOthers then
        str = strlower(str)
    end
    return (str:gsub("^%l", strupper))
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
    for i, v in pairs({string.split(sep, str)}) do
        v = strtrim(v)
        if convertToNum then
            tinsert(t, tonumber(v) or v)
        else
            tinsert(t, v)
        end
    end
    return t
end

function AF.TableToString(t, sep)
    return tconcat(t, sep)
end

---------------------------------------------------------------------
-- table
---------------------------------------------------------------------

---@param t table
---@return number
function AF.Getn(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function AF.GetIndex(t, e)
    for i, v in pairs(t) do
        if e == v then
            return i
        end
    end
    return nil
end

function AF.GetKeys(t)
    local keys = {}
    for k in pairs(t) do
        tinsert(keys, k)
    end
    return keys
end

---@param ... table
---@return table newTbl
function AF.Copy(...)
    local newTbl = {}
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        for k, v in pairs(t) do
            if type(v) == "table" then
                newTbl[k] = AF.Copy(v)
            else
                newTbl[k] = v
            end
        end
    end
    return newTbl
end

function AF.Contains(t, v)
    for _, value in pairs(t) do
        if value == v then return true end
    end
    return false
end

function AF.Insert(t, v)
    local i, done = 1
    repeat
        if not t[i] then
            t[i] = v
            done = true
        end
        i = i + 1
    until done
end

function AF.Remove(t, v)
    for i = #t, 1, -1 do
        if t[i] == v then
            tremove(t, i)
        end
    end
end

-- merge into the first table
---@param t table
---@param ... table
function AF.Merge(t, ...)
    for i = 1, select("#", ...) do
        local _t = select(i, ...)
        for k, v in pairs(_t) do
            if type(v) == "table" then
                t[k] = AF.Copy(v)
            else
                t[k] = v
            end
        end
    end
end

function AF.IsEmpty(t)
    if not t or type(t) ~= "table" then
        return true
    end

    if next(t) then
        return false
    end
    return true
end

function AF.RemoveElementsExceptKeys(tbl, ...)
    local keys = {}

    for i = 1, select("#", ...) do
        local k = select(i, ...)
        keys[k] = true
    end

    for k in pairs(tbl) do
        if not keys[k] then
            tbl[k] = nil
        end
    end
end

function AF.RemoveElementsByKeys(tbl, ...)
    for i = 1, select("#", ...) do
        local k = select(i, ...)
        tbl[k] = nil
    end
end

-- transposes a table, swapping its keys and values
---@param t table the table to transpose
---@param value any the value to assign to the transposed keys
---@return table
function AF.TransposeTable(t, value)
    local temp = {}
    for k, v in ipairs(t) do
        temp[v] = value or k
    end
    return temp
end

-- transposes the given spell table.
---@param t table
---@param convertIdToName boolean?
---@return table
function AF.TransposeSpellTable(t, convertIdToName)
    if not convertIdToName then
        return AF.TransposeTable(t)
    end

    local temp = {}
    for k, v in ipairs(t) do
        local name = AF.GetSpellInfo(v)
        if name then
            temp[name] = k
        end
    end
    return temp
end

---------------------------------------------------------------------
-- table sort
---------------------------------------------------------------------
local function CompareField(a, b, key, order)
    if a[key] ~= b[key] then
        if order == "ascending" then
            return a[key] < b[key]
        else  -- "descending"
            return a[key] > b[key]
        end
    end
    return nil
end

local function SortComparator(criteria)
    return function(a, b)
        for _, criterion in ipairs(criteria) do
            local result = CompareField(a, b, criterion.key, criterion.order)
            if result ~= nil then
                return result
            end
        end
        return false
    end
end

-- order: "ascending" or "descending"
---@param t table
---@param ...: key1, order1, key2, order2, ...
function AF.Sort(t, ...)
    local criteria = {}
    for i = 1, select("#", ...), 2 do
        local key = select(i, ...)
        local order = select(i + 1, ...)
        if key and order then
            tinsert(criteria, {key = key, order = order})
        end
    end
    tsort(t, SortComparator(criteria))
end

---------------------------------------------------------------------
-- time
---------------------------------------------------------------------

function AF.FormatTime(sec)
    if sec >= 3600 then
        return "%dh", ceil(sec / 3600)
    elseif sec >= 60 then
        return "%dm", ceil(sec / 60)
    end
    return "%ds", floor(sec)
end

local SEC = gsub(_G.SPELL_DURATION_SEC, "%%%.%df", "%%s")
local MIN = gsub(_G.SPELL_DURATION_MIN, "%%%.%df", "%%s")

function AF.GetLocalizedSeconds(sec)
    if sec > 60 then
        return format(MIN, AF.Round(sec / 60, 1))
    else
        return format(SEC, AF.Round(sec, 1))
    end
end

---------------------------------------------------------------------
-- queue
---------------------------------------------------------------------
local QUEUE_THRESHOLD = 1000000

local FIFOQueue = {}
FIFOQueue.__index = FIFOQueue

function FIFOQueue:new(threshold)
    local instance = {
        first = 1,
        last = 0,
        length = 0,
        threshold = threshold or QUEUE_THRESHOLD,
        queue = {},
    }
    setmetatable(instance, FIFOQueue)
    return instance
end

function FIFOQueue:push(value)
    self.length = self.length + 1
    self.last = self.last + 1
    self.queue[self.last] = value
end

function FIFOQueue:pop()
    if self.first > self.last then return end
    local value = self.queue[self.first]
    self.queue[self.first] = nil
    self.first = self.first + 1
    self.length = self.length - 1
    return value
end

function FIFOQueue:isEmpty()
    return self.first > self.last
end

function FIFOQueue:shrink()
    local newQueue = {}
    local newFirst = 1
    for i = self.first, self.last do
        newQueue[newFirst] = self.queue[i]
        newFirst = newFirst + 1
    end
    self.queue = newQueue
    self.first = 1
    self.last = newFirst - 1
end

function FIFOQueue:checkShrink()
    if self.first > self.threshold then
        FIFOQueue:shrink()
    end
end

function AF.NewQueue(threshold)
    return FIFOQueue:new(threshold)
end