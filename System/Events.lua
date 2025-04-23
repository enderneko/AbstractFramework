---@class AbstractFramework
local AF = _G.AbstractFramework

AF.AddEventHandler(AF)

---------------------------------------------------------------------
-- instance
---------------------------------------------------------------------
local IsInInstance = IsInInstance
local wasInInstance = nil

--* AF_INSTANCE_ENTER / AF_INSTANCE_LEAVE
-- payload: instanceType, wasInInstance
-- wasInInstance:
--     nil if first time after login
--     true if the player was in an instance before
--     false if not

AF:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    local isIn, iType = IsInInstance()
    if isIn then
        AF.Fire("AF_INSTANCE_ENTER", iType, wasInInstance)
        wasInInstance = true
    else
        AF.Fire("AF_INSTANCE_LEAVE", iType, wasInInstance)
        wasInInstance = false
    end
end)

---------------------------------------------------------------------
-- combat
--------------------------------------------------------------------
--* AF_COMBAT_ENTER / AF_COMBAT_LEAVE
AF:RegisterEvent("PLAYER_REGEN_DISABLED", AF.GetFireFunc("AF_COMBAT_ENTER"))
AF:RegisterEvent("PLAYER_REGEN_ENABLED", AF.GetFireFunc("AF_COMBAT_LEAVE"))