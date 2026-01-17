---@class AbstractFramework
local AF = _G.AbstractFramework

local DEFAULT_TIMEOUT = 2

local IsSpellCached = C_Spell.IsSpellDataCached
local IsItemCached = C_Item.IsItemDataCachedByID
local NewTimer = C_Timer.NewTimer
local pcall = pcall

---@param mixinObj SpellMixin|ItemMixin
---@param isCached boolean
---@param continueWithCancel fun(obj: SpellMixin|ItemMixin, onLoad: fun())
---@param resolve fun(obj: SpellMixin|ItemMixin): any
---@param callback fun(result: any)
local function HandleGeneric(mixinObj, isCached, continueWithCancel, resolve, callback)
    local function safeResolve()
        local ok, result = pcall(resolve, mixinObj)
        if ok then
            callback(result)
        else
            callback(nil)
        end
    end

    if isCached then
        safeResolve()
        return
    end

    local timer, cancel

    timer = NewTimer(DEFAULT_TIMEOUT, function()
        cancel()
        callback(nil)
    end)

    cancel = continueWithCancel(mixinObj, function()
        timer:Cancel()
        safeResolve()
    end)
end

---@param id number
---@param resolve fun(spell: SpellMixin): any
---@param callback fun(result: any)
local function HandleSpell(id, resolve, callback)
    HandleGeneric(
        Spell:CreateFromSpellID(id),
        IsSpellCached(id),
        function(spell, onLoad) return spell:ContinueWithCancelOnSpellLoad(onLoad) end,
        resolve,
        callback
    )
end

---@param id number
---@param resolve fun(item: ItemMixin): any
---@param callback fun(result: any)
local function HandleItem(id, resolve, callback)
    HandleGeneric(
        Item:CreateFromItemID(id),
        IsItemCached(id),
        function(item, onLoad) return item:ContinueWithCancelOnItemLoad(onLoad) end,
        resolve,
        callback
    )
end

---------------------------------------------------------------------
-- general
---------------------------------------------------------------------

---@param spellID number
---@param callback fun(spell: SpellMixin)
function AF.LoadSpellAsync(spellID, callback)
    HandleSpell(spellID, function(spell) return spell end, callback)
end

---@param itemID number
---@param callback fun(item: ItemMixin)
function AF.LoadItemAsync(itemID, callback)
    HandleItem(itemID, function(item) return item end, callback)
end

---------------------------------------------------------------------
-- name
---------------------------------------------------------------------

---@param spellID number
---@param callback fun(name: string|nil)
function AF.LoadSpellNameAsync(spellID, callback)
    HandleSpell(spellID, function(spell) return spell:GetSpellName() end, callback)
end

---@param itemID number
---@param callback fun(name: string|nil)
function AF.LoadItemNameAsync(itemID, callback)
    HandleItem(itemID, function(item) return item:GetItemName() end, callback)
end


---------------------------------------------------------------------
-- icon
---------------------------------------------------------------------

---@param spellID number
---@param callback fun(icon: number|string|nil)
function AF.LoadSpellIconAsync(spellID, callback)
    HandleSpell(spellID, function(spell) return spell:GetSpellTexture() end, callback)
end

---@param itemID number
---@param callback fun(icon: number|string|nil)
function AF.LoadItemIconAsync(itemID, callback)
    HandleItem(itemID, function(item) return item:GetItemIcon() end, callback)
end

---------------------------------------------------------------------
-- quality
---------------------------------------------------------------------

---@param itemID number
---@param callback fun(quality: number|nil)
function AF.LoadItemQualityAsync(itemID, callback)
    HandleItem(itemID, function(item) return item:GetItemQuality() end, callback)
end