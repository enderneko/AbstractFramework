---@class AbstractFramework
local AF = _G.AbstractFramework

-- NOTE: use addon built-in CallbackHandler
-- local callbacks = {
--     -- invoke priority
--     {}, -- 1
--     {}, -- 2
--     {}, -- 3
-- }

-- function AF.RegisterCallback(eventName, onEventFuncName, onEventFunc, priority)
--     local t = priority and callbacks[priority] or callbacks[2]
--     if not t[eventName] then t[eventName] = {} end
--     t[eventName][onEventFuncName] = onEventFunc
-- end

-- function AF.UnregisterCallback(eventName, onEventFuncName)
--     for _, t in pairs(callbacks) do
--         if t[eventName] then
--             t[eventName][onEventFuncName] = nil
--         end
--     end
-- end

-- function AF.UnregisterAllCallbacks(eventName)
--     for _, t in pairs(callbacks) do
--         t[eventName] = nil
--     end
-- end

-- function AF.Fire(eventName, ...)
--     for _, t in pairs(callbacks) do
--         if t[eventName] then
--             for _, fn in pairs(t[eventName]) do
--                 fn(...)
--             end
--         end
--     end
-- end

---------------------------------------------------------------------
-- addon loaded
---------------------------------------------------------------------
local addonCallbacks = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addonCallbacks[addon] then
        for _, fn in pairs(addonCallbacks[addon]) do
            fn(addon)
        end
    end
end)

function AF.RegisterCallbackForAddon(addon, func)
    if not addonCallbacks[addon] then addonCallbacks[addon] = {} end
    tinsert(addonCallbacks[addon], func)
end