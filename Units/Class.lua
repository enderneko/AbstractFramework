---@class AbstractFramework
local AF = select(2, ...)

local classFileToLocalized
if LocalizedClassList then
    classFileToLocalized = LocalizedClassList()
else
    classFileToLocalized = {}
    FillLocalizedClassList(classFileToLocalized)
end

local classLocalizedToFile = AF.SwapKeyValue(classFileToLocalized)

local sortedClasses = {}
local classFileToID = {}
local classIDToFile = {}

do
    -- WARRIOR = 1,
    -- PALADIN = 2,
    -- HUNTER = 3,
    -- ROGUE = 4,
    -- PRIEST = 5,
    -- DEATHKNIGHT = 6,
    -- SHAMAN = 7,
    -- MAGE = 8,
    -- WARLOCK = 9,
    -- MONK = 10,
    -- DRUID = 11,
    -- DEMONHUNTER = 12,
    -- EVOKER = 13,
    --! GetNumClasses returns the highest class ID (NOT IN CLASSIC)
    local highestClassID = GetNumClasses()
    if highestClassID < 11 then highestClassID = 11 end
    for i = 1, highestClassID do
        local classFile, classID = select(2, GetClassInfo(i))
        if classFile and classID == i then
            tinsert(sortedClasses, classFile)
            classFileToID[classFile] = i
            classIDToFile[i] = classFile
        end
    end
    sort(sortedClasses)
end

local GetNumClasses = GetNumClasses

function AF.GetClassID(classFileOrLocalized)
    if classLocalizedToFile[classFileOrLocalized] then
        classFileOrLocalized = classLocalizedToFile[classFileOrLocalized]
    end
    return classFileToID[classFileOrLocalized]
end

function AF.GetClassFile(classIDOrLocalized)
    if type(classIDOrLocalized) == "string" then
        return classLocalizedToFile[classIDOrLocalized]
    elseif type(classIDOrLocalized) == "number" then
        return classIDToFile[classIDOrLocalized]
    end
end

function AF.GetLocalizedClassName(classFileOrID)
    if type(classFileOrID) == "string" then
        return classFileToLocalized[classFileOrID] or classFileOrID
    elseif type(classFileOrID) == "number" and classIDToFile[classFileOrID] then
        return classFileToLocalized[classIDToFile[classFileOrID]] or classFileOrID
    end
    return ""
end

---@return string|nil icon class icon atlas
function AF.GetClassIcon(classFileOrID)
    local class = AF.GetClassFile(classFileOrID)
    if class then
        return "classicon-" .. class:lower()
    end
end

---@return function iterator classFile, classID, index
function AF.IterateClasses()
    local i = 0
    return function()
        i = i + 1
        if i <= GetNumClasses() then
            return sortedClasses[i], classFileToID[sortedClasses[i]], i
        end
    end
end

---@return function iterator classFile, classID, index
function AF.IterateSortedClasses()
    local i = 0
    return function()
        i = i + 1
        if i <= #sortedClasses then
            return sortedClasses[i], classFileToID[sortedClasses[i]], i
        end
    end
end

function AF.GetSortedClasses()
    return AF.Copy(sortedClasses)
end

---------------------------------------------------------------------
-- spec
---------------------------------------------------------------------
local GetSpecializationInfoForSpecID = GetSpecializationInfoForSpecID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
local GetSpecializationInfoByID = GetSpecializationInfoByID

local specIDToName = {
    -- Death Knight
    [250] = "Blood",
    [251] = "Frost",
    [252] = "Unholy",
    [1455] = "Initial",

    -- Demon Hunter
    [577] = "Havoc",
    [581] = "Vengeance",
    [1480] = "Devourer",
    [1456] = "Initial",

    -- Druid
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Restoration",
    [1447] = "Initial",

    -- Evoker
    [1467] = "Devastation",
    [1468] = "Preservation",
    [1473] = "Augmentation",
    [1465] = "Initial",

    -- Hunter
    [253] = "BeastMastery",
    [254] = "Marksmanship",
    [255] = "Survival",
    [1448] = "Initial",

    -- Mage
    [62] = "Arcane",
    [63] = "Fire",
    [64] = "Frost",
    [1449] = "Initial",

    -- Monk
    [268] = "Brewmaster",
    [270] = "Mistweaver",
    [269] = "Windwalker",
    [1450] = "Initial",

    -- Paladin
    [65] = "Holy",
    [66] = "Protection",
    [70] = "Retribution",
    [1451] = "Initial",

    -- Priest
    [256] = "Discipline",
    [257] = "Holy",
    [258] = "Shadow",
    [1452] = "Initial",

    -- Rogue
    [259] = "Assassination",
    [260] = "Outlaw",
    [261] = "Subtlety",
    [1453] = "Initial",

    -- Shaman
    [262] = "Elemental",
    [263] = "Enhancement",
    [264] = "Restoration",
    [1444] = "Initial",

    -- Warlock
    [265] = "Affliction",
    [266] = "Demonology",
    [267] = "Destruction",
    [1454] = "Initial",

    -- Warrior
    [71] = "Arms",
    [72] = "Fury",
    [73] = "Protection",
    [1446] = "Initial",
}

function AF.GetSpecIcon(specID)
    if not specID then return end
    local icon = select(4, GetSpecializationInfoForSpecID(specID))
    return icon
end

function AF.GetSpecRole(specID)
    if not specID then return end
    local role = select(5, GetSpecializationInfoForSpecID(specID))
    return role
end

function AF.GetSpecName(specID)
    if not specID then return end
    return specIDToName[specID]
end

function AF.GetLocalizedSpecName(specID)
    if not specID then return end
    local name = select(2, GetSpecializationInfoForSpecID(specID))
    return name
end

function AF.GetSpecIconForClassID(classID, index)
    if not (classID and index) then return end
    local icon = select(4, GetSpecializationInfoForClassID(classID, index))
    return icon
end

function AF.GetClassFileForSpecID(specID)
    if not specID then return end
    local classFile = select(6, GetSpecializationInfoByID(specID))
    return classFile
end

function AF.GetLocalizedClassNameForSpecID(specID)
    if not specID then return end
    local name = select(7, GetSpecializationInfoByID(specID))
    return name
end

function AF.GetClassIDForSpecID(specID)
    if not specID then return end
    local classFile = AF.GetClassFileForSpecID(specID)
    return AF.GetClassID(classFile)
end