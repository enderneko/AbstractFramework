---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- spells
---------------------------------------------------------------------
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellTexture = C_Spell.GetSpellTexture
function AF.GetSpellInfo(spellId)
    local info = GetSpellInfo(spellId)
    if not info then return end

    if not info.iconID then -- when?
        info.iconID = GetSpellTexture(spellId)
    end

    return info.name, info.iconID
end

---------------------------------------------------------------------
-- auras
---------------------------------------------------------------------
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
function AF.FindAuraById(unit, filter, spellId)
    local i = 1
    repeat
        local auraData = GetAuraDataByIndex(unit, i, filter)
        if auraData then
            if auraData.spellId == spellId then
                return auraData
            end
            i = i + 1
        end
    until not auraData
end