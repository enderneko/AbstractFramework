---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- spells
---------------------------------------------------------------------
if AF.isWrath then
    function AF.GetSpellInfo(spellId)
        if not spellId then return end
        local name, _, icon = GetSpellInfo(spellId)
        return name, icon
    end
else
    local GetSpellInfo = C_Spell.GetSpellInfo
    local GetSpellName = C_Spell.GetSpellName
    local GetSpellTexture = C_Spell.GetSpellTexture

    function AF.GetSpellInfo(spellId)
        local info = GetSpellInfo(spellId)
        if not info then return end

        if not info.iconID then -- when?
            info.iconID = GetSpellTexture(spellId)
        end

        return info.name, info.iconID
    end
end

if C_Spell.DoesSpellExist then
    AF.SpellExists = C_Spell.DoesSpellExist
else
    AF.SpellExists = function(spellId)
        return GetSpellInfo(spellId) ~= nil
    end
end

function AF.RemoveInvalidSpells(t)
    if not t then return end
    for i = #t, 1, -1 do
        local spellId
        if type(t[i]) == "number" then
            spellId = t[i]
        else -- table
            spellId = t[i]["spellID"] or t[i][1]
        end
        if not AF.SpellExists(spellId) then
            tremove(t, i)
        end
    end
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