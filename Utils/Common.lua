---@class AbstractFramework
local AF = _G.AbstractFramework

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

-- function AF.Copy(...)
--     local newTbl = {}
--     for i = 1, select("#", ...) do
--         local t = select(i, ...)
--         for k, v in pairs(t) do
--             if type(v) == "table" then
--                 newTbl[k] = AF.Copy(v)
--             else
--                 newTbl[k] = v
--             end
--         end
--     end
--     return newTbl
-- end

-- function AF.Merge(t, ...)
--     for i = 1, select("#", ...) do
--         local _t = select(i, ...)
--         for k, v in pairs(_t) do
--             if type(v) == "table" then
--                 t[k] = AF.Copy(v)
--             else
--                 t[k] = v
--             end
--         end
--     end
-- end