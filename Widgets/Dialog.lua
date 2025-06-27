---@class AbstractFramework
local AF = _G.AbstractFramework

local YES = _G.YES
local NO = _G.NO
local OKAY = _G.OKAY
local CANCEL = _G.CANCEL
local GOT_IT = _G.HELP_TIP_BUTTON_GOT_IT
local GOT_IT_COUNTDOWN = GOT_IT .. " (%d)"

---------------------------------------------------------------------
-- dialog
---------------------------------------------------------------------
local dialogPool

---@class AF_Dialog:AF_BorderedFrame
local AF_DialogMixin = {}

---@param enabled boolean
function AF_DialogMixin:EnableYes(enabled)
    self.yes:SetEnabled(enabled)
end

---@param enabled boolean
function AF_DialogMixin:EnableNo(enabled)
    self.no:SetEnabled(enabled)
end

function AF_DialogMixin:SetToYesNo()
    self.yes:SetText(YES)
    self.no:SetText(NO)
    AF.SetWidth(self.yes, 50)
    AF.SetWidth(self.no, 50)
end

function AF_DialogMixin:SetToOkayCancel()
    self.yes:SetText(OKAY)
    self.no:SetText(CANCEL)
    AF.SetWidth(self.yes, 70)
    AF.SetWidth(self.no, 70)
end

---@param yesText string
---@param noText string
---@param buttonWidth? number
function AF_DialogMixin:SetToCustom(yesText, noText, buttonWidth)
    self.yes:SetText(yesText)
    self.no:SetText(noText)
    AF.SetWidth(self.yes, buttonWidth or 50)
    AF.SetWidth(self.no, buttonWidth or 50)
end

-- content.dialog will be set to the owner dialog
---@param content Frame content must have valid height (width is relative to the dialog)
---@param height? number content height can also be set here
function AF_DialogMixin:SetContent(content, height)
    content.dialog = self
    self.content = content
    content:SetParent(self.contentHolder)
    content:SetPoint("TOPLEFT", self.contentHolder)
    content:SetPoint("TOPRIGHT", self.contentHolder)
    if height then
        content:SetHeight(height)
    end
    content:Show()
end

-- onConfirm
function AF_DialogMixin:SetOnConfirm(fn)
    self.onConfirm = fn
end

-- onCancel
function AF_DialogMixin:SetOnCancel(fn)
    self.onCancel = fn
end

-- update pixels
function AF_DialogMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)

    self:UpdateHeight()

    if self.minButtonWidth then
        AF.ResizeDialogButtonToFitText(self.minButtonWidth)
    end
end

function AF_DialogMixin:UpdateHeight()
    self:SetScript("OnUpdate", function()
        if self.text:GetText() then
            --! NOTE: text width must be set, and its x/y offset should be 0 (not sure), or WEIRD ISSUES would a appear.
            self.text:SetWidth(AF.Round(self:GetWidth() - 14))
            self.textHolder:SetHeight(AF.Round(self.text:GetStringHeight()))
        end
        if self.content then
            self.contentHolder:SetHeight(AF.Round(self.content:GetHeight()))
        end
        self:SetHeight(AF.Round(self.textHolder:GetHeight() + self.contentHolder:GetHeight()) + 40)
        self:SetScript("OnUpdate", nil)

        -- accent color system
        local r, g, b = AF.GetColorRGB(self.accentColor)
        self:SetBackdropBorderColor(r, g, b)
        self.yes:SetBackdropBorderColor(r, g, b)
        self.no:SetBackdropBorderColor(r, g, b)
    end)
end

local function Dialog_OnShow(self)
    self:UpdateHeight()
end

local function Dialog_OnHide(self)
    self:Hide()
    AF.ClearPoints(self)

    -- reset
    self.minButtonWidth = nil
    self.onConfirm = nil
    self.onCancel = nil

    -- reset text
    self.text:SetText()
    self.textHolder:SetHeight(0)

    -- reset content
    if self.content then
        self.content:ClearAllPoints()
        self.content:Hide()
        self.content = nil
    end
    self.contentHolder:SetHeight(0)

    -- reset button
    self.yes:SetEnabled(true)
    self:SetToYesNo()

    -- hide mask
    if self.shownMask then
        self.shownMask:Hide()
        self.shownMask = nil
    end

    -- reset shadow
    AF.ShowNormalGlow(self, "shadow", 2)

    -- release
    dialogPool:Release(self)
end

dialogPool = AF.CreateObjectPool(function()
    local dialog = AF.CreateBorderedFrame(AF.UIParent, nil, 200, 100)
    dialog:Hide() -- for first OnShow

    AF.ShowNormalGlow(dialog, "shadow", 2)
    dialog:EnableMouse(true)

    -- text holder
    local textHolder = AF.CreateFrame(dialog)
    dialog.textHolder = textHolder
    AF.SetPoint(textHolder, "TOPLEFT", 7, -7)
    AF.SetPoint(textHolder, "TOPRIGHT", -7, -7)

    local text = AF.CreateFontString(textHolder)
    dialog.text = text
    AF.SetPoint(text, "TOPLEFT")
    AF.SetPoint(text, "TOPRIGHT")
    text:SetWordWrap(true)
    text:SetSpacing(3)

    -- frame holder
    local contentHolder = AF.CreateFrame(dialog)
    dialog.contentHolder = contentHolder
    AF.SetPoint(contentHolder, "TOPLEFT", textHolder, "BOTTOMLEFT", 7, -7)
    AF.SetPoint(contentHolder, "TOPRIGHT", textHolder, "BOTTOMRIGHT", -7, -7)

    -- no
    local no = AF.CreateButton(dialog, NO, "red", 50, 17)
    dialog.no = no
    AF.SetPoint(no, "BOTTOMRIGHT")
    no:SetBackdropBorderColor(AF.GetColorRGB("accent"))
    AF.ClearPoints(no.text)
    AF.SetPoint(no.text, "CENTER")
    no:SetScript("OnClick", function()
        if dialog.onCancel then dialog.onCancel() end
        dialog:Hide()
    end)

    -- yes
    local yes = AF.CreateButton(dialog, YES, "green", 50, 17)
    dialog.yes = yes
    AF.SetPoint(yes, "BOTTOMRIGHT", no, "BOTTOMLEFT", 1, 0)
    yes:SetBackdropBorderColor(AF.GetColorRGB("accent"))
    AF.ClearPoints(yes.text)
    AF.SetPoint(yes.text, "CENTER")
    yes:SetScript("OnClick", function()
        if dialog.onConfirm then dialog.onConfirm() end
        dialog:Hide()
    end)

    -- script
    dialog:SetScript("OnShow", Dialog_OnShow)
    dialog:SetScript("OnHide", Dialog_OnHide)

    -- mixin
    Mixin(dialog, AF_DialogMixin)

    return dialog
end)

---@param parent Frame
---@param text string
---@param width? number default 200
---@param noMask? boolean
---@return AF_Dialog dialog
function AF.GetDialog(parent, text, width, noMask)
    local dialog = dialogPool:Acquire()

    dialog.accentColor = AF.GetAddonAccentColorName()

    dialog:SetParent(parent)
    AF.SetFrameLevel(dialog, 50, parent)
    AF.SetWidth(dialog, width or 200)

    dialog.text:SetText(text)

    if yesText then dialog.yes:SetText(yesText) end
    if noText then dialog.no:SetText(noText) end

    if not noMask then
        dialog.shownMask = AF.ShowMask(parent)
    end

    dialog:Show()

    return dialog
end

---------------------------------------------------------------------
-- message dialog
---------------------------------------------------------------------
local messageDialogPool

---@class AF_MessageDialog:AF_BorderedFrame
local AF_MessageDialogMixin = {}

function AF_MessageDialogMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)

    self:UpdateHeight()
end

function AF_MessageDialogMixin:UpdateHeight()
    self:SetScript("OnUpdate", function()
        if self.text:GetText() then
            --! NOTE: text width must be set, and its x/y offset should be 0 (not sure), or WEIRD ISSUES would a appear.
            self.text:SetWidth(AF.Round(self:GetWidth() - 14))
            self.textHolder:SetHeight(AF.Round(self.text:GetStringHeight()))
        end
        self:SetHeight(AF.Round(self.textHolder:GetHeight()) + 40)
        self:SetScript("OnUpdate", nil)

        -- accent color system
        self:SetBackdropBorderColor(AF.GetColorRGB(self.accentColor, 1))
        self.close:SetColor(self.accentColor)
    end)
end

local function MessageDialog_OnShow(self)
    self:UpdateHeight()
end

local function MessageDialog_OnHide(self)
    self:Hide()
    AF.ClearPoints(self)

    -- reset text
    self.text:SetText()
    self.textHolder:SetHeight(0)

    -- reset timer
    if self.timer then
        self.timer:Cancel()
        self.timer = nil
    end

    -- hide mask
    if self.shownMask then
        self.shownMask:Hide()
        self.shownMask = nil
    end

    -- reset shadow
    AF.ShowNormalGlow(self, "shadow", 2)

    -- release
    messageDialogPool:Release(self)
end

messageDialogPool = AF.CreateObjectPool(function()
    local messageDialog = AF.CreateBorderedFrame(AF.UIParent, nil, 200, 100)
    messageDialog:Hide() -- for first OnShow

    AF.ShowNormalGlow(messageDialog, "shadow", 2)
    messageDialog:EnableMouse(true)

    -- text holder
    local textHolder = AF.CreateFrame(messageDialog)
    messageDialog.textHolder = textHolder
    AF.SetPoint(textHolder, "TOPLEFT", 7, -7)
    AF.SetPoint(textHolder, "TOPRIGHT", -7, -7)

    local text = AF.CreateFontString(textHolder)
    messageDialog.text = text
    AF.SetPoint(text, "TOPLEFT")
    AF.SetPoint(text, "TOPRIGHT")
    text:SetWordWrap(true)
    text:SetSpacing(3)

    -- close
    local close = AF.CreateButton(messageDialog, GOT_IT, "accent", 17, 17)
    messageDialog.close = close
    AF.SetPoint(close, "BOTTOMLEFT", 5, 5)
    AF.SetPoint(close, "BOTTOMRIGHT", -5, 5)
    close:SetScript("OnClick", function()
        messageDialog:Hide()
    end)

    -- script
    messageDialog:SetScript("OnShow", MessageDialog_OnShow)
    messageDialog:SetScript("OnHide", MessageDialog_OnHide)

    -- mixin
    Mixin(messageDialog, AF_MessageDialogMixin)

    return messageDialog
end)

---@param parent Frame
---@param text string
---@param width? number default 200
---@param noMask? boolean
---@param countdown? number
---@return AF_MessageDialog
function AF.GetMessageDialog(parent, text, width, noMask, countdown)
    local messageDialog = messageDialogPool:Acquire()

    messageDialog.accentColor = AF.GetAddonAccentColorName()

    messageDialog:SetParent(parent)
    AF.SetFrameLevel(messageDialog, 50, parent)
    AF.SetWidth(messageDialog, width or 200)

    messageDialog.text:SetText(text)

    if not noMask then
        messageDialog.shownMask = AF.ShowMask(parent)
    end

    if countdown then
        messageDialog.close:SetEnabled(false)
        messageDialog.close:SetFormattedText(GOT_IT_COUNTDOWN, countdown)
        messageDialog.timer = C_Timer.NewTicker(1, function()
            messageDialog.timer = nil
            countdown = countdown - 1
            if countdown == 0 then
                messageDialog.close:SetText(GOT_IT)
                messageDialog.close:SetEnabled(true)
            else
                messageDialog.close:SetFormattedText(GOT_IT_COUNTDOWN, countdown)
            end
        end, countdown)
    else
        messageDialog.close:SetEnabled(true)
    end

    messageDialog:Show()

    return messageDialog
end