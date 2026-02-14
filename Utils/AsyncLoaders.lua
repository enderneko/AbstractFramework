---@class AbstractFramework
local AF = select(2, ...)

local DEFAULT_TIMEOUT = 2

local Spell = Spell
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
    local called = false

    local function tryResolveOnce()
        if called then return end
        called = true
        local ok, result = pcall(resolve, mixinObj)
        callback(ok and result or nil)
    end

    if isCached then
        tryResolveOnce()
        return
    end

    local timer
    local cancel = AF.noop -- default to noop so timer callback can safely call it

    timer = NewTimer(DEFAULT_TIMEOUT, function()
        cancel()
        if not called then
            called = true
            callback(nil)
        end
    end)

    cancel = continueWithCancel(mixinObj, function()
        timer:Cancel()
        tryResolveOnce()
    end)
end

local function ContinueWithCancel_Spell(spell, onLoad)
    if spell:IsSpellEmpty() then
        -- empty spell: immediately trigger onLoad
        pcall(onLoad)
        return AF.noop
    else
        return spell:ContinueWithCancelOnSpellLoad(onLoad)
    end
end

---@param id number
---@param resolve fun(spell: SpellMixin): any
---@param callback fun(result: any)
local function HandleSpell(id, resolve, callback)
    HandleGeneric(
        Spell:CreateFromSpellID(id),
        IsSpellCached(id),
        ContinueWithCancel_Spell,
        resolve,
        callback
    )
end

local function ContinueWithCancel_Item(item, onLoad)
    if item:IsItemEmpty() then
        -- empty item: immediately trigger onLoad
        pcall(onLoad)
        return AF.noop
    else
        return item:ContinueWithCancelOnItemLoad(onLoad)
    end
end

---@param id number
---@param resolve fun(item: ItemMixin): any
---@param callback fun(result: any)
local function HandleItem(id, resolve, callback)
    HandleGeneric(
        Item:CreateFromItemID(id),
        IsItemCached(id),
        ContinueWithCancel_Item,
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