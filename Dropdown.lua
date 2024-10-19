---@class AbstractWidgets
local AW = _G.AbstractWidgets

local list, horizontalList

---------------------------------------------------------------------
-- list
---------------------------------------------------------------------
local function CreateListFrame()
    list = AW.CreateScrollList(AW.UIParent, 10, 1, 1, 10, 18, 0, "widget")
    list:SetClampedToScreen(true)
    list:Hide()

    -- adjust scrollBar points
    AW.SetPoint(list.scrollBar, "TOPRIGHT")
    AW.SetPoint(list.scrollBar, "BOTTOMRIGHT")

    -- make list closable by pressing ESC
    _G["AWDropdownList"] = list
    tinsert(UISpecialFrames, "AWDropdownList")

    -- store created buttons
    list.buttons = {}

    -- highlight
    local highlight = AW.CreateBorderedFrame(list, 100, 100, "none", "accent")
    highlight:Hide()

    function list:SetHighlightItem(i)
        if not i then
            highlight:ClearAllPoints()
            highlight:Hide()
        else
            highlight:SetParent(list.buttons[i]) -- NOTE: buttons show/hide automatically when scroll
            highlight:ClearAllPoints()
            highlight:SetAllPoints(list.buttons[i])
            highlight:Show()
        end
    end

    list:SetScript("OnHide", function() list:Hide() end)

    -- do not use OnShow, since it only triggers when hide -> show
    hooksecurefunc(list, "Show", function()
        horizontalList:Hide()
        list:UpdatePixels()
        if list.menu.selected then
            list:SetScroll(list.menu.selected)
        end
    end)
end

---------------------------------------------------------------------
-- horizontalList
---------------------------------------------------------------------
local function CreateHorizontalList()
    horizontalList = AW.CreateBorderedFrame(UIParent, 10, 20, "widget")
    horizontalList:SetClampedToScreen(true)
    horizontalList:Hide()

    -- make list closable by pressing ESC
    _G["AWMiniDropdownList"] = horizontalList
    tinsert(UISpecialFrames, "AWMiniDropdownList")

    -- store created buttons
    horizontalList.buttons = {}

    function horizontalList:Reset()
        for _, b in pairs(horizontalList.buttons) do
            b:Hide()
        end
    end

    -- highlight
    local highlight = AW.CreateBorderedFrame(horizontalList, 100, 100, "none", "accent")
    highlight:Hide()

    function horizontalList:SetHighlightItem(i)
        if not i then
            highlight:ClearAllPoints()
            highlight:Hide()
        else
            highlight:SetParent(horizontalList.buttons[i]) -- NOTE: buttons show/hide automatically when scroll
            highlight:ClearAllPoints()
            highlight:SetAllPoints(horizontalList.buttons[i])
            highlight:Show()
        end
    end

    horizontalList:SetScript("OnHide", function() horizontalList:Hide() end)

    -- do not use OnShow, since it only triggers when hide -> show
    hooksecurefunc(horizontalList, "Show", function()
        list:Hide()
        horizontalList:UpdatePixels()
        for _, b in pairs(horizontalList.buttons) do
            b:UpdatePixels()
        end
    end)
end

---------------------------------------------------------------------
-- close dropdown
---------------------------------------------------------------------
function AW.CloseDropdown()
    list:Hide()
    horizontalList:Hide()
    if list.menu and not list.menu.isMini then
        list.menu.button:SetTexture(AW.GetIcon("ArrowDown"))
    end
end

function AW.RegisterForCloseDropdown(f)
    assert(f and f.HasScript and f:HasScript("OnMouseDown"), "no OnMouseDown for this region!")
    f:HookScript("OnMouseDown", AW.CloseDropdown)
end

---------------------------------------------------------------------
-- dropdown menu
---------------------------------------------------------------------
--- @param maxSlots number max items per "page"
function AW.CreateDropdown(parent, width, maxSlots, dropdownType, isMini, isHorizontal, justify, textureAlpha)
    if not list then CreateListFrame() end
    if not horizontalList then CreateHorizontalList() end

    maxSlots = maxSlots or 10
    textureAlpha = textureAlpha or 0.75

    local menu = AW.CreateBorderedFrame(parent, width, 20, "widget")
    menu:EnableMouse(true)

    local currentList = (isMini and isHorizontal) and horizontalList or list
    menu.isMini = isMini

    -- label
    function menu:SetLabel(label, color, font)
        menu.label = AW.CreateFontString(menu, label, color, font)
        AW.SetPoint(menu.label, "BOTTOMLEFT", menu, "TOPLEFT", 2, 2)
        menu.label:SetText(label)

        hooksecurefunc(menu, "SetEnabled", function(self, enabled)
            if enabled then
                menu.label:SetColor(color)
            else
                menu.label:SetColor("disabled")
            end
        end)
    end

    -- button: open/close menu list
    if isMini then
        menu.button = AW.CreateButton(menu, nil, "accent_transparent", 20, 20)
        menu.button:SetAllPoints(menu)
        -- selected item
        menu.text = AW.CreateFontString(menu.button)
        AW.SetPoint(menu.text, "LEFT", 1, 0)
        AW.SetPoint(menu.text, "RIGHT", -1, 0)
        menu.text:SetJustifyH("CENTER")
    else
        menu.button = AW.CreateButton(menu, nil, "accent_hover", 18, 20)
        menu.button:SetPoint("TOPRIGHT")
        menu.button:SetPoint("BOTTOMRIGHT")
        menu.button:SetTexture(AW.GetIcon("ArrowDown"), {16, 16}, {"CENTER", 0, 0})
        -- menu.button:SetBackdropColor(AW.GetColorRGB("none"))
        -- menu.button._color = AW.GetColorTable("none")
        -- selected item
        menu.text = AW.CreateFontString(menu)
        AW.SetPoint(menu.text, "LEFT", 5, 0)
        AW.SetPoint(menu.text, "RIGHT", menu.button, "LEFT", -5, 0)
        menu.text:SetJustifyH("LEFT")
    end

    AW.AddToFontSizeUpdater(menu.text)

    -- highlight
    -- menu.highlight = AW.CreateTexture(menu, nil, AW.GetColorTable("accent", 0.07))
    -- AW.SetPoint(menu.highlight, "TOPLEFT", 1, -1)
    -- AW.SetPoint(menu.highlight, "BOTTOMRIGHT", -1, 1)
    -- menu.highlight:Hide()

    -- hook for tooltips
    menu.button:HookScript("OnEnter", function()
        if menu._tooltips then
            menu:GetScript("OnEnter")()
        end
    end)
    menu.button:HookScript("OnLeave", function()
        if menu._tooltips then
            menu:GetScript("OnLeave")()
        end
    end)

    -- selected item
    menu.text:SetWordWrap(false)

    if dropdownType == "texture" then
        menu.texture = AW.CreateTexture(isMini and menu.button or menu)
        AW.SetPoint(menu.texture, "TOPLEFT", 1, -1)
        if isMini then
            AW.SetPoint(menu.texture, "BOTTOMRIGHT", -1, 1)
        else
            AW.SetPoint(menu.texture, "BOTTOMRIGHT", menu.button, "BOTTOMLEFT", -1, 1)
        end
        menu.texture:SetVertexColor(AW.GetColorRGB("white", textureAlpha))
        menu.texture:Hide()
    end

    -- keep all menu item definitions
    menu.items = {
        -- {
        --     ["text"] = (string),
        --     ["value"] = (obj),
        --     ["texture"] = (string),
        --     ["font"] = (string),
        --     ["disabled"] = (boolean),
        --     ["onClick"] = (function)
        -- },
    }

    -- index in items
    -- menu.selected

    -- selection ----------------------------------------------------
    local function SetSelected(type, v)
        local valid
        for i, item in pairs(menu.items) do
            if item[type] == v then
                valid = true
                menu.selected = i
                menu.text:SetText(item.text)
                if dropdownType == "texture" then
                    menu.texture:SetTexture(item.texture)
                    menu.texture:Show()
                elseif dropdownType == "font" then
                    menu.text:SetFont(AW.GetFontProps(item.font))
                end
                break
            end
        end
        if not valid then
            menu:ClearSelected()
        end
    end

    --- @deprecated
    function menu:SetSelected(text)
        SetSelected("text", text)
    end

    function menu:SetSelectedValue(value)
        SetSelected("value", value)
    end

    function menu:ClearSelected()
        menu.selected = nil
        menu.text:SetText()
        if dropdownType == "texture" then menu.texture:Hide() end
        currentList:SetHighlightItem()
    end

    -- return value first, then text
    function menu:GetSelected()
        if menu.selected then
            return menu.items[menu.selected].value or menu.items[menu.selected].text
        end
        return nil
    end
    -----------------------------------------------------------------

    -- update items -------------------------------------------------
    function menu:SetItems(items)
        -- validate item.value
        for _, item in ipairs(items) do
            if not item.value then item.value = item.text end
        end
        menu.items = items
        menu.reloadRequired = true
    end

    function menu:AddItem(item)
        -- validate item.value
        if not item.value then item.value = item.text end
        tinsert(menu.items, item)
        menu.reloadRequired = true
    end

    function menu:RemoveCurrentItem()
        tremove(menu.items, menu.selected)
        menu.reloadRequired = true
    end

    function menu:ClearItems()
        wipe(menu.items)
        menu.selected = nil
        menu.text:SetText("")
        currentList:SetHighlightItem()
    end

    function menu:SetCurrentItem(item)
        menu.items[menu.selected] = item
        -- usually, update current item means to change its name (text) and func
        menu.text:SetText(item["text"])
        menu.reloadRequired = true
    end
    -----------------------------------------------------------------

    -- generic onClick ----------------------------------------------
    function menu:SetOnClick(fn)
        menu.onClick = fn
    end
    -----------------------------------------------------------------

    local buttons = {} -- current shown buttons

    local function LoadItems()
        wipe(buttons)
        menu.reloadRequired = nil
        -- hide highlight
        currentList:SetHighlightItem()
        -- hide all buttons
        currentList:Reset()

        -- load current dropdown
        for i, item in pairs(menu.items) do
            local b
            if not currentList.buttons[i] then
                -- create new button
                b = AW.CreateButton(isHorizontal and currentList or currentList.slotFrame, item.text, "accent_transparent", 18 ,18, nil, true) --! width is not important
                table.insert(currentList.buttons, b)

                b.bgTexture = AW.CreateTexture(b)
                AW.SetPoint(b.bgTexture, "TOPLEFT", 1, -1)
                AW.SetPoint(b.bgTexture, "BOTTOMRIGHT", -1, 1)
                b.bgTexture:SetVertexColor(AW.GetColorRGB("white", textureAlpha))
                b.bgTexture:Hide()

                AW.AddToFontSizeUpdater(b.text)
            else
                -- re-use button
                b = currentList.buttons[i]
                b:SetText(item.text)
            end

            tinsert(buttons, b)
            b:SetEnabled(not item.disabled)
            -- b:Show() NOTE: show/hide is done in SetScroll

            local fs = b.text
            if isMini then
                fs:SetJustifyH(justify or "CENTER")
                AW.ClearPoints(fs)
                AW.SetPoint(fs, "LEFT", 1, 0)
                AW.SetPoint(fs, "RIGHT", -1, 0)
            else
                fs:SetJustifyH(justify or "LEFT")
                AW.ClearPoints(fs)
                AW.SetPoint(fs, "LEFT", 5, 0)
                AW.SetPoint(fs, "RIGHT", -5, 0)
            end

            -- texture
            if dropdownType == "texture" and item.texture then
                b.bgTexture:SetTexture(item.texture)
                b.bgTexture:Show()
            else
                b.bgTexture:Hide()
            end

            -- font
            if item.font then
                -- set
                b:SetFont(AW.GetFontProps(item.font))
            else
                -- restore
                b:SetFont(AW.GetFontProps("normal"))
                b.Update = nil
            end

            function b:Update()
                --! invoked in SetScroll, or text may not "visible"
                b.text:Hide()
                b.text:Show()
            end

            -- highlight
            if menu.selected == i then
                currentList:SetHighlightItem(i)
            end

            b:SetScript("OnClick", function()
                menu:SetSelectedValue(item.value)
                currentList:Hide()
                if item.onClick then
                    -- NOTE: item.onClick has higher priority
                    item.onClick(item.value, menu)
                elseif menu.onClick then
                    menu.onClick(item.value)
                end
                if not isMini then menu.button:SetTexture(AW.GetIcon("ArrowDown")) end
            end)

            -- update point
            if isMini and isHorizontal then
                AW.SetWidth(b, width)
                if i == 1 then
                    AW.SetPoint(b, "TOPLEFT", 1, -1)
                else
                    AW.SetPoint(b, "TOPLEFT", currentList.buttons[i-1], "TOPRIGHT")
                end
            end
        end

        -- update list size / point
        currentList.menu = menu -- check for menu's OnHide -> list:Hide
        currentList:SetParent(menu)
        AW.SetFrameLevel(currentList, 10, menu)
        AW.ClearPoints(currentList)

        if isMini and isHorizontal then
            AW.SetPoint(currentList, "TOPLEFT", menu, "TOPRIGHT", 2, 0)
            AW.SetHeight(currentList, 20)

            if #menu.items == 0 then
                AW.SetWidth(currentList, 5)
            else
                AW.SetListWidth(currentList, #menu.items, width, 0, 2)
            end

        else -- using scroll list
            AW.SetPoint(currentList, "TOPLEFT", menu, "BOTTOMLEFT", 0, -2)
            AW.SetPoint(currentList, "TOPRIGHT", menu, "BOTTOMRIGHT", 0, -2)
            -- AW.SetWidth(currentList, width)

            currentList:SetSlotNum(min(#buttons, maxSlots))
            currentList:SetWidgets(buttons)
        end
    end

    function menu:SetEnabled(f)
        menu.button:SetEnabled(f)
        if f then
            menu.text:SetColor("white")
        else
            menu.text:SetColor("disabled")
            if currentList.menu == menu then
                currentList:Hide()
            end
        end
    end

    menu:SetScript("OnHide", function()
        if currentList.menu == menu then
            currentList:Hide()
            if not isMini then menu.button:SetTexture(AW.GetIcon("ArrowDown")) end
        end
    end)

    -- scripts
    menu.button:HookScript("OnClick", function(self, button)
        if button ~= "LeftButton" then
            currentList:Hide()
            return
        end

        if currentList.menu ~= menu then -- list shown by other dropdown
            if currentList.menu and not currentList.menu.isMini then
                -- restore previous menu's button texture
                currentList.menu.button:SetTexture(AW.GetIcon("ArrowDown"))
            end
            LoadItems()
            currentList:Show()
            if not isMini then menu.button:SetTexture(AW.GetIcon("ArrowUp")) end

        elseif currentList:IsShown() then -- list showing by this, hide it
            currentList:Hide()
            if not isMini then menu.button:SetTexture(AW.GetIcon("ArrowDown")) end

        else
            if menu.reloadRequired then
                LoadItems()
            else
                -- update highlight
                if menu.selected then
                    currentList:SetHighlightItem(menu.selected)
                end
            end
            currentList:Show()
            if not isMini then menu.button:SetTexture(AW.GetIcon("ArrowUp")) end
        end
    end)

    return menu
end