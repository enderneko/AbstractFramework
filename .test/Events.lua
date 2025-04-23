---@class AbstractFramework
local AF = _G.AbstractFramework

AF.AddEventHandler(AF)

---------------------------------------------------------------------
-- instance
---------------------------------------------------------------------
local IsInInstance = IsInInstance
local isInInstance = false

AF:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    local isIn, iType = IsInInstance()
    if isIn then
        isInInstance = true
        AF.Fire("AF_INSTANCE_ENTER", iType)
    elseif isInInstance then
        isInInstance = false
        AF.Fire("AF_INSTANCE_LEAVE", iType)
    end
end)

---------------------------------------------------------------------
-- combat
---------------------------------------------------------------------
AF:RegisterEvent("PLAYER_REGEN_DISABLED", AF.GetFireFunc("AF_COMBAT_ENTER"))
AF:RegisterEvent("PLAYER_REGEN_ENABLED", AF.GetFireFunc("AF_COMBAT_LEAVE"))