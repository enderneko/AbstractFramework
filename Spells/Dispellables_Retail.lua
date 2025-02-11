---@class AbstractFramework
local AF = _G.AbstractFramework

local dispellable = {}

function AF.CanDispel(debuffType)
    if not debuffType then return end
    return dispellable[debuffType]
end

local dispelNodeIDs = {
    -- DRUID ----------------
        -- 102 - Balance
        [102] = {["Curse"] = 82205, ["Poison"] = 82205},
        -- 103 - Feral
        [103] = {["Curse"] = 82204, ["Poison"] = 82204},
        -- 104 - Guardian
        [104] = {["Curse"] = 82215, ["Poison"] = 82215},
        -- Restoration
        [105] = {["Curse"] = 82203, ["Magic"] = true, ["Poison"] = 82203},
    -------------------------

    -- EVOKER ---------------
        -- 1467 - Devastation
        [1467] = {["Curse"] = 93294, ["Disease"] = 93294, ["Poison"] = {93306, 93294}, ["Bleed"] = 93294},
        -- 1468 - Preservation
        [1468] = {["Curse"] = 93294, ["Disease"] = 93294, ["Magic"] = true, ["Poison"] = true, ["Bleed"] = 93294},
        -- 1473 - Augmentation
        [1473] = {["Curse"] = 93294, ["Disease"] = 93294, ["Poison"] = {93306, 93294}, ["Bleed"] = 93294},
    -------------------------

    -- MAGE -----------------
        -- 62 - Arcane
        [62] = {["Curse"] = 62116},
        -- 63 - Fire
        [63] = {["Curse"] = 62116},
        -- 64 - Frost
        [64] = {["Curse"] = 62116},
    -------------------------

    -- MONK -----------------
        -- 268 - Brewmaster
        [268] = {["Disease"] = 81633, ["Poison"] = 81633},
        -- 269 - Windwalker
        [269] = {["Disease"] = 80606, ["Poison"] = 80606},
        -- 270 - Mistweaver
        [270] = {["Disease"] = 81634, ["Magic"] = true, ["Poison"] = 81634},
    -------------------------

    -- PALADIN --------------
        -- 65 - Holy
        [65] = {["Disease"] = 81508, ["Magic"] = true, ["Poison"] = 81508, ["Bleed"] = 81616},
        -- 66 - Protection
        [66] = {["Disease"] = 81507, ["Poison"] = 81507, ["Bleed"] = 81616},
        -- 70 - Retribution
        [70] = {["Disease"] = 81507, ["Poison"] = 81507, ["Bleed"] = 81616},
    -------------------------

    -- PRIEST ---------------
        -- 256 - Discipline
        [256] = {["Disease"] = 82705, ["Magic"] = true},
        -- 257 - Holy
        [257] = {["Disease"] = 82705, ["Magic"] = true},
        -- 258 - Shadow
        [258] = {["Disease"] = 82704, ["Magic"] = 82699},
    -------------------------

    -- SHAMAN ---------------
        -- 262 - Elemental
        [262] = {["Curse"] = 81075, ["Poison"] = 81093},
        -- 263 - Enhancement
        [263] = {["Curse"] = 81077, ["Poison"] = 81093},
        -- 264 - Restoration
        [264] = {["Curse"] = 81073, ["Magic"] = true, ["Poison"] = 81093},
    -------------------------

    -- WARLOCK --------------
        -- 265 - Affliction
        -- [265] = {["Magic"] = function() return IsSpellKnown(89808, true) end},
        -- 266 - Demonology
        -- [266] = {["Magic"] = function() return IsSpellKnown(89808, true) end},
        -- 267 - Destruction
        -- [267] = {["Magic"] = function() return IsSpellKnown(89808, true) end},
    -------------------------
}

local eventFrame = CreateFrame("Frame")

if UnitClassBase("player") == "WARLOCK" then
    eventFrame:RegisterEvent("UNIT_PET")

    local timer
    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if unit ~= "player" then return end

        if timer then
            timer:Cancel()
        end
        timer = C_Timer.NewTimer(1, function()
            -- update dispellable
            dispellable["Magic"] = IsSpellKnown(89808, true)
            -- texplore(dispellable)
        end)

    end)
else
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

    local function UpdateDispellable()
        -- update dispellable
        wipe(dispellable)
        local activeConfigID = C_ClassTalents.GetActiveConfigID()
        if activeConfigID and dispelNodeIDs[BFI.vars.playerSpecID] then
            for dispelType, value in pairs(dispelNodeIDs[BFI.vars.playerSpecID]) do
                if type(value) == "boolean" then
                    dispellable[dispelType] = value
                elseif type(value) == "table" then -- more than one trait
                    for _, v in pairs(value) do
                        local nodeInfo = C_Traits.GetNodeInfo(activeConfigID, v)
                        if nodeInfo and nodeInfo.ranksPurchased ~= 0 then
                            dispellable[dispelType] = true
                            break
                        end
                    end
                else -- number: check node info
                    local nodeInfo = C_Traits.GetNodeInfo(activeConfigID, value)
                    if nodeInfo and nodeInfo.ranksPurchased ~= 0 then
                        dispellable[dispelType] = true
                    end
                end
            end
        end
        -- texplore(dispellable)
    end

    local timer

    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end

        if timer then timer:Cancel() end
        timer = C_Timer.NewTimer(1, UpdateDispellable)
    end)
end