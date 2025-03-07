---@class AbstractFramework
local AF = _G.AbstractFramework

local current_root

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local menus = {}

local function CreateMenu(level)
    local menu = AF.CreateScrollList(level > 1 and AF.UIParent or menus[level - 1], "AFCascadingMenu" .. level, 10, 1, 1, 10, 18, 0, "widget", "accent")
    menu:SetClampedToScreen(true)
    menu:Hide()

    menus[level] = menu
    menu.buttons = {}
    menu.createdButtons = {}

    menu:SetScript("OnHide", function()
        menu:Hide()
        if level == 1 then
            current_root = nil
        end
    end)

    return menu
end

local function LoadItems(items, maxShownItems, level)
    local menu = menus[level] or CreateMenu(level)
    wipe(menu.buttons)

    for i, item in pairs(items) do
        local b
        if menu.createdButtons[i] then
            b = menu.createdButtons[i]
        else
            b = AF.CreateButton(menu, "AFCascadingMenu" .. level .. "Button" .. i, "accent_transparent", 18, 18, nil, true)
            menu.createdButtons[i] = b

            -- children symbol
            b.childrenSymbol = b:CreateFontString(nil, "OVERLAY", "AF_FONT_NORMAL")
            b.childrenSymbol:SetText(AF.WrapTextInColor(">", "gray"))
            b.childrenSymbol:SetPoint("RIGHT", -2, 0)
            b.childrenSymbol:Hide()

            -- sub menu
            b:HookScript("OnEnter", function()
                if b.items then
                    LoadItems(b.items, maxShownItems, level + 1)
                    AF.ClearPoints(menus[level + 1])
                    AF.SetPoint(menus[level + 1], "TOPLEFT", b, "TOPRIGHT", -2, 2)
                    menus[level + 1]:Show()
                end
            end)
        end

        b:SetText(item.text)
        b:SetEnabled(not item.disabled)

        if item.icon then
            b:SetTexture(item.icon, {16, 16}, {"LEFT", 2, 0}, nil, true, item.iconBorderColor)
        else
            b:HideTexture()
        end

        if item.onClick then
            b:SetScript("OnClick", function()
                item.onClick(item.value)
                if current_root and current_root.SetValue then
                    current_root:SetValue(item.value)
                end
                menus[1]:Hide()
            end)
        else
            b:SetScript("OnClick", nil)
        end

        if item.children then
            b.items = item.children
            b.childrenSymbol:Show()
        else
            b.items = nil
            b.childrenSymbol:Hide()
        end

        tinsert(menu.buttons, b)
        menu:SetSlotNum(maxShownItems)
        menu:SetWidgets(menu.buttons)
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
-- local items = {
--     {
--         ["text"] = (string),
--         ["value"] = (any),
--         ["icon"] = (string|number),
--         ["iconBorderColor"] = (string),
--         ["onClick"] = (function),
--         ["disabled"] = (boolean),
--         ["children"] = {...},
--     }, ...
-- }

-- when an item is clicked, will call parent:SetValue(text, value, icon, iconBorderColor), if exists
---@param parent Frame
---@param items table
---@param maxShownItems number? default is 10
---@param point string? default is "TOPLEFT"
---@param relativePoint string? default is "BOTTOMLEFT"
---@param x number? default is 0
---@param y number? default is -2
function AF.ShowCascadingMenu(parent, items, maxShownItems, point, relativePoint, x, y)
    current_root = parent
    LoadItems(items, maxShownItems, 1)
    menus[1]:SetParent(parent)
    AF.ClearPoints(menus[1])
    AF.SetPoint(menus[1], point or "TOPLEFT", parent, relativePoint or "BOTTOMLEFT", x or 0, y or -2)
    menus[1]:Show()
end

---------------------------------------------------------------------
-- cascading menu button
---------------------------------------------------------------------
---@class AF_CascadingMenu
local AF_CascadingMenuMixin = {}

function AF_CascadingMenuMixin:SetValue(text, value, icon, iconBorderColor)
    self:SetText(text)
    if icon then
        self:SetTexture(icon, {16, 16}, {"LEFT", 2, 0}, nil, nil, iconBorderColor)
    else
        self:HideTexture()
    end
end

function AF_CascadingMenuMixin:SetLabel(label, color, font)
    if not self.label then
        self.label = AF.CreateFontString(self, label, color or "white", font)
        self.label:SetJustifyH("LEFT")
        AF.SetPoint(self.label, "BOTTOMLEFT", self, "TOPLEFT", 2, 2)
    end

    self.label.color = color or "white"
    self.label:SetColor(self.enabled and self.label.color or "disabled")
    self.label:SetText(label)
end

function AF_CascadingMenuMixin:SetEnabled(enabled)
    self.enabled = enabled
    self:_SetEnabled(enabled)

    if self.label then
        self.label:SetColor(enabled and self.label.color or "disabled")
    end

    if not enabled and current_root == self then
        menus[1]:Hide()
    end
end

function AF_CascadingMenuMixin:SetItems(items, maxShownItems)
    -- validate item.value
    for _, item in ipairs(items) do
        if not item.value then item.value = item.text end
    end
    self.items = items
    self.maxShownItems = maxShownItems
end

function AF_CascadingMenuMixin:LoadItems()
    if not self.items then return end
    current_root = self
    LoadItems(self.items, self.maxShownItems, 1)
    AF.ClearPoints(menus[1])
    AF.SetPoint(menus[1], "TOPLEFT", self, "BOTTOMLEFT", 0, -2)
    AF.SetPoint(menus[1], "TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
    menus[1]:Show()
end

---@param parent Frame
---@param width number
---@param items table
---@param maxShownItems number? default is 10
---@return AF_CascadingMenu|AF_Button|Button
function AF.CreateCascadingMenu(parent, width)
    local menu = AF.CreateButton(parent, "", "accent_hover", width, 20)

    menu._SetEnabled = menu.SetEnabled
    Mixin(menu, AF_CascadingMenuMixin)

    menu:SetScript("OnClick", menu.LoadItems)

    return menu
end