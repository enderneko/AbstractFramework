---@class AbstractFramework
local AF = select(2, ...)

local type, select = type, select
local unpack, next = unpack, next
local assert = assert
local NewTimer = C_Timer.NewTimer

---------------------------------------------------------------------
-- delayed invoke
-- not recommended for high-concurrency/high-frequency scenarios
---------------------------------------------------------------------
local delayed = {}

function AF.DelayedInvoke(delay, func, ...)
    assert(type(delay) == "number", "delay must be a number")
    assert(type(func) == "function", "func must be a function")

    -- cancel existing timer
    if delayed[func] then
        delayed[func]:Cancel()
        delayed[func] = nil
    end

    -- save arguments directly to local variables to reduce closure overhead
    local a1, a2, a3, a4, a5, a6, a7 = ...
    local numArgs = select("#", ...)
    local args
    if numArgs > 7 then
        args = {...}
    end

    delayed[func] = NewTimer(delay, function()
        delayed[func] = nil
        -- call function based on number of arguments, avoid creating temporary tables
        if numArgs == 0 then
            func()
        elseif numArgs == 1 then
            func(a1)
        elseif numArgs == 2 then
            func(a1, a2)
        elseif numArgs == 3 then
            func(a1, a2, a3)
        elseif numArgs == 4 then
            func(a1, a2, a3, a4)
        elseif numArgs == 5 then
            func(a1, a2, a3, a4, a5)
        elseif numArgs == 6 then
            func(a1, a2, a3, a4, a5, a6)
        elseif numArgs == 7 then
            func(a1, a2, a3, a4, a5, a6, a7)
        else
            func(unpack(args, 1, numArgs))
        end
    end)
end

function AF.GetDelayedInvoker(delay, func)
    assert(type(delay) == "number", "delay must be a number")
    assert(type(func) == "function", "func must be a function")

    return function(...)
        AF.DelayedInvoke(delay, func, ...)
    end
end

---------------------------------------------------------------------
-- delayed invoke for object
-- not recommended for high-concurrency/high-frequency scenarios
---------------------------------------------------------------------
local delayedForObj = setmetatable({}, { __mode = "k" })

function AF.DelayedInvokeForObj(delay, obj, func, ...)
    assert(type(delay) == "number", "delay must be a number")
    assert(obj ~= nil, "obj must not be nil")
    assert(type(func) == "function", "func must be a function")

    -- get or create per-object table
    local row = delayedForObj[obj]
    if not row then
        row = {}
        delayedForObj[obj] = row
    end

    -- cancel existing timer for this func
    if row[func] then
        row[func]:Cancel()
        row[func] = nil
    end

    -- save arguments directly to local variables to reduce closure overhead
    local a1, a2, a3, a4, a5, a6, a7 = ...
    local numArgs = select("#", ...)
    local args
    if numArgs > 7 then
        args = {...}
    end

    row[func] = NewTimer(delay, function()
        row[func] = nil
        -- clean up empty per-object table to avoid leakage
        if not next(row) then
            delayedForObj[obj] = nil
        end

        -- call function with obj as first argument
        if numArgs == 0 then
            func(obj)
        elseif numArgs == 1 then
            func(obj, a1)
        elseif numArgs == 2 then
            func(obj, a1, a2)
        elseif numArgs == 3 then
            func(obj, a1, a2, a3)
        elseif numArgs == 4 then
            func(obj, a1, a2, a3, a4)
        elseif numArgs == 5 then
            func(obj, a1, a2, a3, a4, a5)
        elseif numArgs == 6 then
            func(obj, a1, a2, a3, a4, a5, a6)
        elseif numArgs == 7 then
            func(obj, a1, a2, a3, a4, a5, a6, a7)
        else
            func(obj, unpack(args, 1, numArgs))
        end
    end)
end

function AF.GetDelayedInvokerForObj(delay, obj, func)
    assert(type(delay) == "number", "delay must be a number")
    assert(obj ~= nil, "obj must not be nil")
    assert(type(func) == "function", "func must be a function")

    return function(...)
        AF.DelayedInvokeForObj(delay, obj, func, ...)
    end
end