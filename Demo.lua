---@class AbstractWidgets
local AW = _G.AbstractWidgets

function AW.ShowDemo()
    if _G.AW_DEMO then
        _G.AW_DEMO:Show()
        return
    end

    -- ----------------------------------------------------------------------- --
    --                              headered frame                             --
    -- ----------------------------------------------------------------------- --
    local demo = AW.CreateHeaderedFrame(AW.UIParent, "AW_DEMO", "Abstract Widgets Demo", 710, 500)
    AW.SetPoint(demo, "BOTTOMLEFT", 500, 270)
    demo:SetFrameLevel(100)
    demo:SetTitleJustify("LEFT")

    local moverTestFrames = {}

    -- background
    demo:SetScript("OnShow", function()
        if not THE_BACKGROUND then
            THE_BACKGROUND = CreateFrame("Frame", "THE_BACKGROUND", nil, "BackdropTemplate")
            AW.SetDefaultBackdrop_NoBorder(THE_BACKGROUND)
            THE_BACKGROUND:SetBackdropColor(0.3, 0.3, 0.3, 1)
            THE_BACKGROUND:SetAllPoints(UIParent)
            THE_BACKGROUND:SetFrameStrata("BACKGROUND")
            THE_BACKGROUND:SetFrameLevel(0)
            THE_BACKGROUND:Hide()
        end
        THE_BACKGROUND:Show()

        for _, f in pairs(moverTestFrames) do
            f:Show()
        end
    end)

    demo:SetScript("OnHide", function()
        THE_BACKGROUND:Hide()
        for _, f in pairs(moverTestFrames) do
            f:Hide()
        end
    end)

    demo:Show()

    -- netstats
    local ns = AW.CreateNetStatsPane(demo.header, "RIGHT", true, true)
    AW.SetPoint(ns, "RIGHT", demo.header.closeBtn, "LEFT", -5, 0)

    -- fps
    local fps = AW.CreateFPSPane(demo.header, "RIGHT")
    AW.SetPoint(fps, "RIGHT", ns, "LEFT", -230, 0)


    -- ----------------------------------------------------------------------- --
    --                         apply combat protection                         --
    -- ----------------------------------------------------------------------- --
    AW.ApplyCombatProtectionToFrame(demo)


    -- ----------------------------------------------------------------------- --
    --                                  button                                 --
    -- ----------------------------------------------------------------------- --
    local b1 = AW.CreateButton(demo, "Button A", "accent", 100, 20)
    AW.SetPoint(b1, "TOPLEFT", 10, -10)
    AW.SetTooltips(b1, "ANCHOR_TOPLEFT", 0, 2, "Tooltip Title", "This is a tooltip")

    local b2 = AW.CreateButton(demo, "Button B", "green", 100, 20)
    AW.SetPoint(b2, "TOPLEFT", b1, "TOPRIGHT", 10, 0)
    b2:SetEnabled(false)

    local b3 = AW.CreateButton(demo, "Button C", "border_only", 100, 20)
    AW.SetPoint(b3, "TOPLEFT", b2, "TOPRIGHT", 10, 0)
    AW.SetTooltips(b3, "ANCHOR_TOPLEFT", 0, 2, "Another Style", "SetTextHighlightColor", "SetBorderHighlightColor")
    b3:SetTextHighlightColor("accent")
    b3:SetBorderHighlightColor("accent")

    local b4 = AW.CreateButton(demo, "Button D", "red", 100, 20)
    b4:SetTexture("classicon-"..strlower(PlayerUtil.GetClassFile()), {16, 16}, {"LEFT", 2, 0}, true)
    AW.SetPoint(b4, "TOPLEFT", b3, "TOPRIGHT", 10, 0)

    local b5 = AW.CreateButton(demo, nil, "accent", 20, 20)
    b5:SetTexture("classicon-"..strlower(PlayerUtil.GetClassFile()), {16, 16}, {"CENTER", 0, 0}, true, true)
    AW.SetPoint(b5, "TOPLEFT", b4, "TOPRIGHT", 10, 0)

    local b6 = AW.CreateButton(demo, nil, "accent", 20, 20)
    b6:SetTexture("classicon-"..strlower(PlayerUtil.GetClassFile()), {16, 16}, {"CENTER", 0, 0}, true, true)
    AW.SetPoint(b6, "TOPLEFT", b5, "TOPRIGHT", 10, 0)
    b6:SetEnabled(false)


    -- ----------------------------------------------------------------------- --
    --                               check button                              --
    -- ----------------------------------------------------------------------- --
    local cb1 = AW.CreateCheckButton(demo, "Check boxes")
    AW.SetPoint(cb1, "TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    AW.SetTooltips(cb1, "ANCHOR_TOPLEFT", 0, 3, "Check Button", "The hit rectangle of these check buttons are different")

    local cb2 = AW.CreateCheckButton(demo, "With")
    AW.SetPoint(cb2, "TOPLEFT", cb1, "BOTTOMLEFT", 0, -7)
    cb2:SetEnabled(false)

    local cb3 = AW.CreateCheckButton(demo, "Different label lengths", function(checked)
        cb2:SetChecked(checked)
    end)
    AW.SetPoint(cb3, "TOPLEFT", cb2, "BOTTOMLEFT", 0, -7)


    -- ----------------------------------------------------------------------- --
    --                                 edit box                                --
    -- ----------------------------------------------------------------------- --
    local eb1 = AW.CreateEditBox(demo, "Edit Box", 200, 20)
    AW.SetPoint(eb1, "TOPLEFT", cb3, "BOTTOMLEFT", 0, -10)
    eb1:SetOnTextChanged(function(text)
        print("TextChanged:", text)
    end)
    eb1:SetText("Hello!")

    local eb2 = AW.CreateEditBox(demo, "Number Only", 200, 20, false, true)
    AW.SetPoint(eb2, "TOPLEFT", eb1, "BOTTOMLEFT", 0, -10)
    eb2:SetConfirmButton(function(text)
        print("ConfirmButtonClicked:", text)
    end)

    local eb3 = AW.CreateEditBox(demo, "Edit Box", 200, 20)
    AW.SetPoint(eb3, "TOPLEFT", eb2, "BOTTOMLEFT", 0, -10)
    eb3:SetText("Disabled Edit Box")
    eb3:SetEnabled(false)

    local eb4 = AW.CreateScrollEditBox(demo, nil, "Scroll Edit Box", 100, 110)
    AW.SetPoint(eb4, "TOPLEFT", eb3, "BOTTOMLEFT", 0, -10)
    eb4:SetText("1 First\n2 Second\n3 Third\n4 Fourth\n5 Fifth\n6 Sixth\n7 Seventh\n8 Eighth\n9 Ninth\n10 Tenth")

    local cb4 = AW.CreateCheckButton(demo, nil, function(checked, self)
        eb4:SetEnabled(checked)
    end)
    AW.SetPoint(cb4, "BOTTOMLEFT", eb4, "BOTTOMRIGHT", 2, 0)
    cb4:SetChecked(true)


    -- ----------------------------------------------------------------------- --
    --                              bordered frame                             --
    -- ----------------------------------------------------------------------- --
    local bf1 = AW.CreateBorderedFrame(demo, nil, 150, 150, nil, "accent")
    AW.SetPoint(bf1, "TOPLEFT", b3, "BOTTOMLEFT", 0, -10)


    -- ----------------------------------------------------------------------- --
    --                               font string                               --
    -- ----------------------------------------------------------------------- --
    local fs1 = AW.CreateFontString(bf1, "Bordered Frame", "gray")
    AW.SetPoint(fs1, "TOPLEFT", 5, -5)


    -- ----------------------------------------------------------------------- --
    --                               titled pane                               --
    -- ----------------------------------------------------------------------- --
    local tp1 = AW.CreateTitledPane(demo, "Titled Pane", 140, 100)
    AW.SetPoint(tp1, "TOPLEFT", bf1, 5, -30)


    -- ----------------------------------------------------------------------- --
    --                               button group                              --
    -- ----------------------------------------------------------------------- --
    local bf2 = AW.CreateBorderedFrame(demo, nil, 100)
    bf2:SetTitle("Button Group")
    AW.SetPoint(bf2, "TOPLEFT", eb4, "BOTTOMLEFT", 0, -27)
    AW.SetListHeight(bf2, 3, 20, -1)

    local b6 = AW.CreateButton(bf2, "Item A", "accent_transparent", 100, 20)
    b6.id = "b6"
    AW.SetPoint(b6, "TOPLEFT")
    AW.SetPoint(b6, "RIGHT")
    AW.SetTooltips(b6, "LEFT", -2, 0, "Item A")

    local b7 = AW.CreateButton(bf2, "Item B", "accent_transparent", 100, 20)
    b7.id = "b7"
    AW.SetPoint(b7, "TOPLEFT", b6, "BOTTOMLEFT", 0, 1)
    AW.SetPoint(b7, "RIGHT")
    AW.SetTooltips(b7, "LEFT", -2, 0, "Item B")

    local b8 = AW.CreateButton(bf2, "Item C", "accent_transparent", 100, 20)
    b8.id = "b8"
    AW.SetPoint(b8, "TOPLEFT", b7, "BOTTOMLEFT", 0, 1)
    AW.SetPoint(b8, "RIGHT")
    AW.SetTooltips(b8, "LEFT", -2, 0, "Item C")

    AW.CreateButtonGroup({b6, b7, b8}, function(id)
        print("selected", id)
    end)


    -- ----------------------------------------------------------------------- --
    --                               scroll frame                              --
    -- ----------------------------------------------------------------------- --
    local sf1 = AW.CreateScrollFrame(demo, nil, 150, 150)
    AW.SetPoint(sf1, "TOPLEFT", bf1, "BOTTOMLEFT", 0, -10)
    -- AW.SetPoint(sf1, "TOPRIGHT", bf1, "BOTTOMRIGHT", 0, -10)

    sf1.tex = AW.CreateGradientTexture(sf1.scrollContent, "VERTICAL", {0.96, 0.26, 0.41, 1}, {0.24, 0.23, 0.57, 1})
    AW.SetPoint(sf1.tex, "TOPLEFT", sf1.scrollContent, 1, -1)
    AW.SetPoint(sf1.tex, "BOTTOMRIGHT", sf1.scrollContent, -1, 1)

    sf1.b1 = AW.CreateButton(sf1.scrollContent, "Entry", "blue", 20, 20)
    AW.SetPoint(sf1.b1, "TOPLEFT")
    AW.SetPoint(sf1.b1, "RIGHT")

    sf1:SetContentHeight(20)


    -- ----------------------------------------------------------------------- --
    --                                  switch                                 --
    -- ----------------------------------------------------------------------- --
    local sw1 = AW.CreateSwitch(demo, 150, 20, {
        {
            ["text"] = "20",
            ["value"] = 20,
            ["onClick"] = function()
                sf1:SetContentHeight(20)
            end,
        },
        {
            ["text"] = "100",
            ["value"] = 100,
            ["onClick"] = function()
                sf1:SetContentHeight(100)
            end,
        },
        {
            ["text"] = "200",
            ["value"] = 200,
            ["onClick"] = function()
                sf1:SetContentHeight(200)
            end,
        },
        {
            ["text"] = "400",
            ["value"] = 400,
            ["onClick"] = function()
                sf1:SetContentHeight(400)
            end,
        }
    })
    AW.SetPoint(sw1, "TOPLEFT", sf1, "BOTTOMLEFT", 0, -10)
    sw1:SetSelectedValue(20)


    -- ----------------------------------------------------------------------- --
    --                                  slider                                 --
    -- ----------------------------------------------------------------------- --
    local sl1 = AW.CreateSlider(tp1, "Scale", 130, 0.5, 2, 0.1)
    AW.SetPoint(sl1, "TOPLEFT", 5, -40)
    AW.SetTooltips(sl1, "TOPLEFT", 0, 20, "Set scale of AW.UIParent", "If AW.UIParent:GetEffectiveScale() < 0.43, there can be errors")
    sl1:SetValue(AW.GetScale())
    sl1:SetAfterValueChanged(function(value)
        AW.SetScale(value)
    end)

    local sl2 = AW.CreateSlider(demo, "Enabled", 100, 50, 500, 10, true, true)
    AW.SetPoint(sl2, "TOPLEFT", eb4, "TOPRIGHT", 10, -25)
    sl2:SetValue(1 * 100) -- for percentage, set value * 100
    sl2:SetOnValueChanged(function(value)
        print("OnSliderValueChanged:", value / 100) -- for percentage, get value / 100
    end)
    sl2:SetAfterValueChanged(function(value)
        print("AfterSliderValueChanged:", value / 100) -- for percentage, get value / 100
    end)

    local cb5 = AW.CreateCheckButton(demo, nil, function(checked, self)
        sl2:SetEnabled(checked)
        sl2:SetLabel(checked and "Enabled" or "Disabled")
        AW.ShowNotificationText(checked and "Enabled" or "Disabled", "red", nil, nil, "BOTTOMLEFT", self, "TOPLEFT", 0, 3)
    end)
    AW.SetPoint(cb5, "BOTTOMLEFT", sl2, "TOPLEFT", 0, 1)
    cb5:SetChecked(true)

    local sl3 = AW.CreateVerticalSlider(demo, "Vertical Slider", 100, 0, 100, 1, true)
    AW.SetPoint(sl3, "TOPLEFT", sl2, "BOTTOMLEFT", 45, -30)
    sl3:UpdateWordWrap()
    sl3:SetValue(0 * 100) -- for percentage, set value * 100
    sl3:SetOnValueChanged(function(value)
        print("VERTICAL_OnSliderValueChanged:", value / 100) -- for percentage, get value / 100
    end)
    sl3:SetAfterValueChanged(function(value)
        print("VERTICAL_AfterSliderValueChanged:", value / 100) -- for percentage, get value / 100
    end)

    local sl4 = AW.CreateSlider(tp1, "Font Size", 130, -5, 5, 1)
    AW.SetPoint(sl4, "TOPLEFT", sl1, 0, -50)
    sl4:SetValue(0)
    sl4:SetAfterValueChanged(function(value)
        AW.UpdateFontSize(value)
    end)


    -- ----------------------------------------------------------------------- --
    --                               scroll list                               --
    -- ----------------------------------------------------------------------- --
    local slist1 = AW.CreateScrollList(demo, nil, 150, 5, 5, 7, 20, 5)
    AW.SetPoint(slist1, "TOPLEFT", bf1, "TOPRIGHT", 10, 0)
    local widgets = {}
    for i = 1, 20 do
        tinsert(widgets, AW.CreateButton(slist1.slotFrame, "Item "..i, "accent_hover", 20, 20))
    end
    slist1:SetWidgets(widgets)


    -- ----------------------------------------------------------------------- --
    --                                 dropdown                                --
    -- ----------------------------------------------------------------------- --
    -- normal dropdown (items <= 10)
    local dd1 = AW.CreateDropdown(demo, 150)
    AW.SetPoint(dd1, "TOPLEFT", slist1, "TOPRIGHT", 10, 0)
    AW.SetTooltips(dd1, "TOPLEFT", 0, 2, "Normal Dropdown 1")
    dd1:SetLabel("Normal Dropdown 1")
    dd1:SetOnClick(function(value)
        print("NormalDropdown1 Selected:", value)
    end)
    local items = {}
    for i = 1, 7 do
        tinsert(items, {["text"] = "Item "..i})
    end
    dd1:SetItems(items)

    -- normal dropdown (items > 10)
    local dd2 = AW.CreateDropdown(demo, 150)
    AW.SetPoint(dd2, "TOPLEFT", dd1, "BOTTOMLEFT", 0, -30)
    AW.SetTooltips(dd2, "TOPLEFT", 0, 2, "Normal Dropdown 2")
    dd2:SetLabel("Normal Dropdown 2")
    dd2:SetOnClick(function(value)
        print("NormalDropdown2 Selected:", value)
    end)
    local items = {}
    for i = 1, 20 do
        tinsert(items, {["text"] = "Item "..i})
    end
    dd2:SetItems(items)

    -- empty dropdown
    local dd3 = AW.CreateDropdown(demo, 150)
    AW.SetPoint(dd3, "TOPLEFT", dd2, "BOTTOMLEFT", 0, -30)
    dd3:SetLabel("Empty Dropdown")

    -- disabled dropdown
    local dd4 = AW.CreateDropdown(demo, 150)
    AW.SetPoint(dd4, "TOPLEFT", dd3, "BOTTOMLEFT", 0, -30)
    dd4:SetLabel("Disabled Dropdown")
    dd4:SetEnabled(false)
    dd4:SetItems({
        {
            ["text"] = "Item 0",
            -- ["value"] = "item0" -- if value not set, value = text
        }
    })
    dd4:SetSelectedValue("Item 0")
    -- dd4:SetSelectedValue("item0")

    -- font dropdown
    local dd5 = AW.CreateDropdown(demo, 150, 10, "font")
    AW.SetPoint(dd5, "TOPLEFT", dd4, "BOTTOMLEFT", 0, -30)
    dd5:SetLabel("Font Dropdown")
    AW.SetTooltips(dd5, "TOPLEFT", 0, 2, "Font Dropdown", "LibSharedMedia is required")

    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local items = {}
        local fonts, fontNames = LSM:HashTable("font"), LSM:List("font")
        for _, name in ipairs(fontNames) do
            tinsert(items, {
                ["text"] = name,
                ["font"] = fonts[name],
            })
        end
        dd5:SetItems(items)
    end

    -- texture dropdown
    local dd6 = AW.CreateDropdown(demo, 150, 10, "texture")
    AW.SetPoint(dd6, "TOPLEFT", dd5, "BOTTOMLEFT", 0, -30)
    dd6:SetLabel("Texture Dropdown")
    AW.SetTooltips(dd6, "TOPLEFT", 0, 2, "Texture Dropdown", "LibSharedMedia is required")

    if LSM then
        local items = {}
        local textures, textureNames = LSM:HashTable("statusbar"), LSM:List("statusbar")
        for _, name in ipairs(textureNames) do
            tinsert(items, {
                ["text"] = name,
                ["texture"] = textures[name],
            })
        end
        dd6:SetItems(items)
    end

    -- vertical mini dropdown
    local dd7 = AW.CreateDropdown(demo, 100, 10, nil, true)
    AW.SetPoint(dd7, "TOPLEFT", dd6, "BOTTOMLEFT", 0, -30)
    dd7:SetLabel("Mini Dropdown (V)")
    local items = {}
    for i = 1, 5 do
        tinsert(items, {
            ["text"] = "VMini "..i
        })
    end
    dd7:SetItems(items)

    -- horizontal mini dropdown
    local dd8 = AW.CreateDropdown(demo, 100, 10, nil, true, true)
    AW.SetPoint(dd8, "TOPLEFT", dd7, "BOTTOMLEFT", 0, -30)
    dd8:SetLabel("Mini Dropdown (H)")
    local items = {}
    for i = 1, 3 do
        tinsert(items, {
            ["text"] = "HMini "..i
        })
    end
    dd8:SetItems(items)


    -- ----------------------------------------------------------------------- --
    --                               color picker                              --
    -- ----------------------------------------------------------------------- --
    local cp1 = AW.CreateColorPicker(demo, "Color Picker", true, function(r, g, b, a)
        print("ColorPicker1_OnChange:", r, g, b, a)
    end, function(r, g, b, a)
        print("ColorPicker1_OnConfirm:", r, g, b, a)
    end)
    AW.SetPoint(cp1, "TOPLEFT", slist1, "BOTTOMLEFT", 0, -10)
    cp1:SetColor(AW.GetColorRGB("pink", 0.7))

    local cp2 = AW.CreateColorPicker(demo, "CP No Alpha")
    AW.SetPoint(cp2, "TOPLEFT", cp1, "BOTTOMLEFT", 0, -7)
    cp2:SetColor(AW.GetColorRGB("skyblue"))

    local cp3 = AW.CreateColorPicker(demo, "CP Disabled")
    AW.SetPoint(cp3, "TOPLEFT", cp2, "BOTTOMLEFT", 0, -7)
    cp3:SetColor(AW.GetColorTable("purple"))
    cp3:SetEnabled(false)


    -- ----------------------------------------------------------------------- --
    --                                 dialog1                                 --
    -- ----------------------------------------------------------------------- --
    local b7 = AW.CreateButton(demo, "Dialog1", "accent_hover", 150, 20)
    AW.SetPoint(b7, "TOPLEFT", cp3, "BOTTOMLEFT", 0, -10)
    b7:SetScript("OnClick", function()
        local text = AW.WrapTextInColor("Test Message", "firebrick").."\nReload UI now?\n"..AW.WrapTextInColor("The quick brown fox jumps over the lazy dog", "gray")
        AW.ShowDialog(demo, text, 200, nil, nil, true)
        AW.SetDialogPoint("TOPLEFT", 255, -170)
        AW.SetDialogOnConfirm(function()
            C_UI.Reload()
        end)
    end)


    -- ----------------------------------------------------------------------- --
    --                                 dialog2                                 --
    -- ----------------------------------------------------------------------- --
    local b8 = AW.CreateButton(demo, "Dialog2", "accent_hover", 150, 20)
    AW.SetPoint(b8, "TOPLEFT", b7, "BOTTOMLEFT", 0, -7)

    -- content
    local form = AW.CreateDialogContent(50)

    -- NOTE: use WIDTH for pixel perfect

    local eb5 = AW.CreateEditBox(form, "type somthing", 172, 20)
    AW.SetPoint(eb5, "TOPLEFT")
    -- AW.SetPoint(eb5, "TOPRIGHT")

    local dd9 = AW.CreateDropdown(form, 172)
    AW.SetPoint(dd9, "TOPLEFT", eb5, "BOTTOMLEFT", 0, -7)
    -- AW.SetPoint(dd9, "TOPRIGHT", eb5, "BOTTOMRIGHT", 0, -7)
    local items = {}
    for i = 1, 7 do
        tinsert(items, {["text"] = "Item "..i})
    end
    dd9:SetItems(items)

    eb5:SetOnTextChanged(function(text)
        form.dialog.yes:SetEnabled(text ~= "" and dd9:GetSelected())
        form.value1 = text
    end)

    dd9:SetOnClick(function(value)
        form.dialog.yes:SetEnabled(strtrim(eb5:GetText()) ~= "" and dd9:GetSelected())
        form.value2 = value
    end)

    form:SetScript("OnShow", function()
        eb5:Clear()
        dd9:ClearSelected()
    end)

    b8:SetScript("OnClick", function()
        AW.ShowDialog(demo, AW.WrapTextInColor("Test Form", "yellow"), 200, _G.OKAY, _G.CANCEL, true, form, true)
        AW.SetDialogPoint("TOPLEFT", 255, -170)
        AW.ResizeDialogButtonToFitText(70)
        AW.SetDialogOnConfirm(function()
            print("Dialog Confirmed:", form.value1, form.value2)
        end)
    end)


    -- ----------------------------------------------------------------------- --
    --                            notificator dialog                           --
    -- ----------------------------------------------------------------------- --
    local b9 = AW.CreateButton(demo, "NotificationDialog", "accent_hover", 150, 20)
    AW.SetPoint(b9, "TOPLEFT", b8, "BOTTOMLEFT", 0, -7)
    b9:SetScript("OnClick", function()
        local text = AW.WrapTextInColor("NOTICE", "orange").."\n".."One day, when what has happened behind the scene could be told, developers and gamers will have a whole new level understanding of how much damage a jerk can make."
        local dialog = AW.ShowNotificationDialog(demo, text, 200, true, 3)
        AW.SetFrameStaticGlow(dialog)
        AW.SetNotificationDialogPoint("TOPLEFT", 255, -120)
    end)


    -- ----------------------------------------------------------------------- --
    --                               scroll text                               --
    -- ----------------------------------------------------------------------- --
    local bf3 = AW.CreateBorderedFrame(demo, nil, 530, 20)
    AW.SetPoint(bf3, "TOPLEFT", bf2, "BOTTOMLEFT", 0, -10)

    local st = AW.CreateScrollText(bf3, 0.01)
    AW.SetPoint(st, "TOPLEFT", 4, 0)
    AW.SetPoint(st, "TOPRIGHT", -4, 0)
    st:SetText("World of Warcraft, often abbreviated as WoW, is a massively multiplayer online roleplaying game (MMORPG) developed by Blizzard Entertainment and released on November 23, 2004, on the 10th anniversary of the Warcraft franchise, three years after its announcement on September 2, 2001. It is the fourth released game set in the Warcraft universe, and takes place four years after the events of Warcraft III: The Frozen Throne.", "gold")


    -- ----------------------------------------------------------------------- --
    --                             animated resize                             --
    -- ----------------------------------------------------------------------- --
    local b10 = AW.CreateButton(demo, "Animated Resize", "accent_hover", 150, 20)
    AW.SetPoint(b10, "TOPLEFT", bf3, "BOTTOMLEFT", 0, -10)

    local bf4 = AW.CreateBorderedFrame(demo, nil, 120, 78, nil, "hotpink")
    AW.SetFrameLevel(bf4, 50)
    bf4:Hide()
    AW.SetPoint(bf4, "BOTTOMLEFT", b10, "TOPLEFT", 0, 10)

    bf4.widthText = AW.CreateFontString(bf4, "120", "hotpink")
    AW.SetPoint(bf4.widthText, "BOTTOMLEFT", bf4, "TOPLEFT", 0, 2)

    bf4.heightText = AW.CreateFontString(bf4, "78", "hotpink")
    AW.SetPoint(bf4.heightText, "BOTTOMLEFT", bf4, "BOTTOMRIGHT", 2, 0)

    local function UpdateSizeText(width, height)
        bf4.widthText:SetText(Round(width))
        bf4.heightText:SetText(Round(height))
    end

    b10:SetScript("OnClick", function()
        if bf4:IsShown() then
            AW.HideMask(demo)
            AW.SetFrameLevel(b10, 1)
            bf4:Hide()
        else
            AW.ShowMask(demo)
            AW.SetFrameLevel(b10, 50)
            bf4:Show()
        end
    end)

    -- both
    local b11 = AW.CreateButton(bf4, "Both+", "hotpink", 100, 20)
    AW.SetPoint(b11, "BOTTOMLEFT", 10, 10)

    -- height
    local b12 = AW.CreateButton(bf4, "Height+", "hotpink", 100, 20)
    AW.SetPoint(b12, "BOTTOMLEFT", b11, "TOPLEFT", 0, -1)

    -- width
    local b13 = AW.CreateButton(bf4, "Width+", "hotpink", 100, 20)
    AW.SetPoint(b13, "BOTTOMLEFT", b12, "TOPLEFT", 0, -1)

    local maxWidth, maxHeight

    b11:SetScript("OnClick", function()
        if not maxWidth or not maxHeight then
            AW.AnimatedResize(bf4, 300, 200, nil, nil, function()
                AW.Disable(b11, b12, b13)
            end, function()
                maxWidth, maxHeight = true, true
                AW.Enable(b11, b12, b13)
                b11:SetText("Both-")
                b12:SetText("Height-")
                b13:SetText("Width-")
            end, UpdateSizeText)
        else
            AW.AnimatedResize(bf4, 120, 78, nil, nil, function()
                AW.Disable(b11, b12, b13)
            end, function()
                maxWidth, maxHeight = false, false
                AW.Enable(b11, b12, b13)
                b11:SetText("Both+")
                b12:SetText("Height+")
                b13:SetText("Width+")
            end, UpdateSizeText)
        end
    end)

    b12:SetScript("OnClick", function()
        if not maxHeight then
            AW.AnimatedResize(bf4, nil, 200, nil, nil, function()
                AW.Disable(b11, b12, b13)
            end, function()
                maxHeight = true
                AW.Enable(b11, b12, b13)
                b12:SetText("Height-")
                if maxWidth then b11:SetText("Both-") end
            end, UpdateSizeText)
        else
            AW.AnimatedResize(bf4, nil, 78, nil, nil, function()
                AW.Disable(b11, b12, b13)
            end, function()
                maxHeight = false
                AW.Enable(b11, b12, b13)
                b12:SetText("Height+")
                b11:SetText("Both+")
            end, UpdateSizeText)
        end
    end)

    b13:SetScript("OnClick", function()
        if not maxWidth then
            AW.AnimatedResize(bf4, 300, nil, nil, nil, function()
                AW.Disable(b11, b12, b13)
            end, function()
                maxWidth = true
                AW.Enable(b11, b12, b13)
                b13:SetText("Width-")
                if maxHeight then b11:SetText("Both-") end
            end, UpdateSizeText)
        else
            AW.AnimatedResize(bf4, 120, nil, nil, nil, function()
                AW.Disable(b11, b12, b13)
            end, function()
                maxWidth = false
                AW.Enable(b11, b12, b13)
                b13:SetText("Width+")
                b11:SetText("Both+")
            end, UpdateSizeText)
        end
    end)


    -- ----------------------------------------------------------------------- --
    --                                status bar                               --
    -- ----------------------------------------------------------------------- --
    local function OnUpdate(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 0.02 then
            self.elapsed = 0
            if self.isReverse then
                self.value = (self.value or 0) - 1
            else
                self.value = (self.value or 0) + 1
            end
            if self.value == 100 then
                self.isReverse = true
                self.elapsed = -1
            elseif self.value == 0 then
                self.isReverse = false
                self.elapsed = -1
            end
            self:SetBarValue(self.value)
        end
    end

    local bar1 = AW.CreateStatusBar(demo, 0, 100, 100, 20, "skyblue", nil, "percentage")
    AW.SetPoint(bar1, "TOPLEFT", b10, "BOTTOMLEFT", 0, -10)

    local bar2 = AW.CreateStatusBar(demo, 0, 100, 100, 20, "hotpink", nil, "value")
    AW.SetPoint(bar2, "TOPLEFT", bar1, "TOPRIGHT", 10, 0)
    bar2:SetScript("OnUpdate", OnUpdate)

    local bar3 = AW.CreateStatusBar(demo, 0, 100, 100, 20, "lime", nil, "value-max")
    AW.SetPoint(bar3, "TOPLEFT", bar2, "TOPRIGHT", 10, 0)
    bar3:SetScript("OnUpdate", OnUpdate)

    local bar4 = AW.CreateStatusBar(demo, 0, 100, 320, 7, "accent")
    AW.SetPoint(bar4, "TOPLEFT", bar1, "BOTTOMLEFT", 0, -5)

    bar1:SetScript("OnUpdate", function(self, elapsed)
        OnUpdate(self, elapsed)
        if self.value == 100 then
            bar4:SetSmoothedValue(100)
        elseif self.value == 50 then
            bar4:SetSmoothedValue(50)
        elseif self.value == 0 then
            bar4:SetSmoothedValue(0)
        end
    end)


    -- ----------------------------------------------------------------------- --
    --                                  popups                                 --
    -- ----------------------------------------------------------------------- --
    AW.CreatePopupMover("general", "Popups")

    local bf5 = AW.CreateBorderedFrame(demo, nil, 370, 20)
    AW.SetPoint(bf5, "BOTTOMLEFT", b10, "BOTTOMRIGHT", 10, 0)

    local fs2 = AW.CreateFontString(bf5, "Popups", "accent")
    AW.SetPoint(fs2, "LEFT", bf5, 10, 0)

    local b14 = AW.CreateButton(bf5, "PPopup+", "accent", 95, 20)
    AW.SetPoint(b14, "BOTTOMRIGHT")
    AW.SetTooltips(b14, "ANCHOR_TOPLEFT", 0, 2, "Progress Popup", "With progress bar", "Hide in 5 sec after completion")
    b14:SetScript("OnClick", function()
        local callback = AW.ShowProgressPopup("In Progress...", 100, true)
        local v = 0
        C_Timer.NewTicker(2, function()
            v = v + 25
            callback(v)
        end, 4)
    end)

    local b15 = AW.CreateButton(bf5, "CPopup+", "accent", 95, 20)
    AW.SetPoint(b15, "BOTTOMRIGHT", b14, "BOTTOMLEFT", 1, 0)
    AW.SetTooltips(b15, "ANCHOR_TOPLEFT", 0, 2, "Confirm Popup", "With \"Yes\" & \"No\" buttons", "Won't hide automatically")
    b15:SetScript("OnClick", function()
        for i = 1, 3 do
            AW.ShowConfirmPopup("Confirm "..i, function()
                print("Confirm "..i, "yes")
            end, function()
                print("Confirm "..i, "no")
            end)
        end
    end)

    local b16 = AW.CreateButton(bf5, "NPopup+", "accent", 95, 20)
    AW.SetPoint(b16, "BOTTOMRIGHT", b15, "BOTTOMLEFT", 1, 0)
    AW.SetTooltips(b16, "ANCHOR_TOPLEFT", 0, 2, "Notification Popup", "With timeout", "Right-Click to hide")
    b16:SetScript("OnClick", function()
        for i = 1, 3 do
            local timeout = random(2, 7)
            AW.ShowNotificationPopup("Notification "..AW.WrapTextInColor(timeout.."sec", "gray"), timeout)
        end
    end)

    -- ----------------------------------------------------------------------- --
    --                                 calendar                                --
    -- ----------------------------------------------------------------------- --
    local dw = AW.CreateDateWidget(demo, time())
    AW.SetPoint(dw, "TOPLEFT", bf5, "TOPRIGHT", 10, 0)
    local niceDays = {}
    local colors = {"firebrick", "hotpink", "chartreuse", "vividblue"}
    local today = date("*t")
    for i = 1, 7 do
        local str = string.format("%04d%02d%02d", today.year, today.month, random(1, 27))
        if not niceDays[str] then
            niceDays[str] = {color=colors[random(1,4)], tooltips={"Nice Day", str}}
        end
    end
    dw:SetMarksForDays(niceDays)
    dw:SetOnDateChanged(function(dt)
        print(dt.year, dt.month, dt.day, dt.timestamp)
    end)

    -- ----------------------------------------------------------------------- --
    --                                  mover                                  --
    -- ----------------------------------------------------------------------- --
    local mbf = AW.CreateBorderedFrame(demo, nil, 290, 20)
    AW.SetPoint(mbf, "TOPLEFT", bar3, "TOPRIGHT", 10, 0)

    local fs3 = AW.CreateFontString(mbf, "Movers", "accent")
    AW.SetPoint(fs3, "LEFT", mbf, 10, 0)

    local mDropdown

    local undoBtn = AW.CreateButton(mbf, "Undo", "accent", 60, 20)
    AW.SetPoint(undoBtn, "TOPRIGHT")
    undoBtn:SetScript("OnClick", function()
        AW.UndoMovers()
    end)

    local hmBtn = AW.CreateButton(mbf, "Hide", "accent", 60, 20)
    AW.SetPoint(hmBtn, "TOPRIGHT", undoBtn, "TOPLEFT", 1, 0)
    hmBtn:SetScript("OnClick", function()
        AW.HideMovers()
        mDropdown:ClearSelected()
    end)

    mDropdown = AW.CreateDropdown(mbf, 85, 10, nil, true)
    AW.SetPoint(mDropdown, "TOPRIGHT", hmBtn, "TOPLEFT", 1, 0)
    AW.SetTooltips(mDropdown, "TOPLEFT", 0, 2, "Mover Tips", "- Drag to move", "- Use (shift) mouse wheel to move frame by 1 pixel", "- Right-Click to open fine-tuning frame", "- Shift+Right-Click to hide a mover")
    mDropdown:SetItems({
        {
            ["text"] = "All",
            ["onClick"] = function()
                AW.ShowMovers()
            end,
        },
        {
            ["text"] = "General",
            ["onClick"] = function()
                AW.ShowMovers("general")
            end,
        },
        {
            ["text"] = "Group 1",
            ["onClick"] = function()
                AW.ShowMovers("group1")
            end,
        },
        {
            ["text"] = "Group 2",
            ["onClick"] = function()
                AW.ShowMovers("group2")
            end,
        },
    })

    local function CreateMoverTestFrame(id, group, point)
        local f = AW.CreateBorderedFrame(AW.UIParent, nil, 170, 120)
        tinsert(moverTestFrames, f)
        AW.SetPoint(f, point)
        f:SetTitle("Mover Test Frame "..id.."\n"..point, "hotpink", nil, true)
        AW.CreateMover(f, group, "Test Mover "..id, function(p,x,y) print("MTF"..id..":", p, x, y) end)
    end

    -- group1
    CreateMoverTestFrame(1, "group1", "TOPLEFT")
    CreateMoverTestFrame(2, "group1", "LEFT")
    CreateMoverTestFrame(3, "group1", "BOTTOMLEFT")
    CreateMoverTestFrame(4, "group1", "TOP")
    CreateMoverTestFrame(5, "group1", "CENTER")

    -- group2
    CreateMoverTestFrame(6, "group2", "TOPRIGHT")
    CreateMoverTestFrame(7, "group2", "RIGHT")
    CreateMoverTestFrame(8, "group2", "BOTTOM")
    CreateMoverTestFrame(9, "group2", "BOTTOMRIGHT")
end