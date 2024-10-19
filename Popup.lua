---@class AbstractWidgets
local AW = _G.AbstractWidgets

local parent, mover
local popups = {}

local MAX_POPUPS = 5
local DEFAULT_WIDTH = 220
local DEFAULT_OFFSET = 10
local DEFAULT_NOTIFICATION_TIMEOUT = 10
local DEFAULT_PROGRESS_TIMEOUT = 5

local settings = {
    ["position"] = "BOTTOMLEFT,0,420",
    ["orientation"] = "bottom_to_top"
}

local notificationPool, confirmPool, progressPool

---------------------------------------------------------------------
-- creation
---------------------------------------------------------------------
local function CreateParent()
    -- parent
    parent = CreateFrame("Frame", "AWPopupParent", AW.UIParent)
    -- parent:SetBackdrop({edgeFile=AW.GetPlainTexture(), edgeSize=AW.GetOnePixelForRegion(parent)})
    -- parent:SetBackdropBorderColor(AW.GetColorRGB("black"))
    AW.SetSize(parent, DEFAULT_WIDTH, 60)
    AW.SetPoint(parent, "BOTTOMLEFT", 0, 420)
    parent:SetFrameStrata("DIALOG")
    parent:SetFrameLevel(666)
    parent:SetClampedToScreen(true)

    function parent:UpdatePixels()
        AW.ReSize(parent)
    end

    AW.AddToPixelUpdater(parent)
end

---------------------------------------------------------------------
-- mover
---------------------------------------------------------------------
function AW.CreatePopupMover(group, text)
    if not parent then CreateParent() end
    AW.CreateMover(parent, group, text, function(p, x, y)
        settings["position"] = p..","..x..","..y
    end)
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
local function ShowPopups(stopMoving)
    for i, p in ipairs(popups) do
        if stopMoving then
            p:StopMoving()
        end

        -- show
        if i <= MAX_POPUPS and not popups[i]:IsShown() then
            popups[i]:FadeIn()
        end

        -- set point
        local point, relativePoint, offset
        if settings["orientation"] == "bottom_to_top" then
            point, relativePoint = "BOTTOMLEFT", "TOPLEFT"
            offset = DEFAULT_OFFSET
        else
            point, relativePoint = "TOPLEFT", "BOTTOMLEFT"
            offset = -DEFAULT_OFFSET
        end

        AW.ClearPoints(popups[i])
        if i == 1 then
            AW.SetPoint(popups[i], point)
        else
            AW.SetPoint(popups[i], point, popups[i-1], relativePoint, 0, offset)
        end
    end
end

---------------------------------------------------------------------
-- orientation
---------------------------------------------------------------------
function AW.SetPopupOrientation(orientation)
    settings["orientation"] = strlower(orientation)
    ShowPopups()
end

---------------------------------------------------------------------
-- position
---------------------------------------------------------------------
function AW.SetPopupSettingsTable(t)
    assert(type(t)=="table")

    -- validate
    if not t["position"] then t["position"] = settings["position"] end
    if not t["orientation"] then t["orientation"] = settings["orientation"] end

    settings = t -- save reference

    -- load position
    AW.LoadPosition(parent, t["position"])
end

---------------------------------------------------------------------
-- hiding handler
---------------------------------------------------------------------
local hidingQueue = {}

local hidingHandler = CreateFrame("Frame")
hidingHandler:Hide()
hidingHandler:SetScript("OnUpdate", function()
    if hidingQueue[1] then
        if not hidingHandler.isProcessing then
            hidingHandler.isProcessing = true
            hidingQueue[1]:FadeOut()
        end
    else
        hidingHandler:Hide()
        hidingHandler.isProcessing = nil
    end
end)

local function HandleNext()
    ShowPopups()
    hidingQueue[1].isInQueue = nil
    tremove(hidingQueue, 1)
    hidingHandler.isProcessing = nil
end

local function AddToHidingQueue(p)
    if p.isInQueue then return end --! prevent Click and Timeout at the same time
    p.isInQueue = true
    tinsert(hidingQueue, p)
    hidingHandler:Show()
end

local function WipeHidingQueue()
    for _, p in ipairs(hidingQueue) do
        p.isInQueue = nil
    end
    wipe(hidingQueue)
end

local function OnPopupHide(p)
    -- update index
    for i = p.index+1, #popups do
        popups[i].index = popups[i].index - 1
    end
    tremove(popups, p.index)

    if #popups == 0 then
        --! all popups hide
        -- the last popup won't move
        WipeHidingQueue()
    else
        -- play move animation
        local hooked
        for i = p.index, MAX_POPUPS do
            if not popups[i] then break end

            -- only hook ONE popup
            if not hooked then
                -- refresh
                hooked = true
                popups[i]:SetOnMoveFinished(HandleNext)
            else
                popups[i]:SetOnMoveFinished()
            end
            popups[i]:Move(Round(p:GetHeight())+DEFAULT_OFFSET)
        end

        if not hooked then
            HandleNext()
        end
    end

    p.index = nil
end

---------------------------------------------------------------------
-- animation
---------------------------------------------------------------------
local function CreateAnimation(p)
    AW.CreateFadeInOutAnimation(p)

    local move_ag = p:CreateAnimationGroup()
    local move_a = move_ag:CreateAnimation("Translation")
    move_a:SetDuration(0.25)

    function p:Move(offset)
        if not p:IsShown() then p:FadeIn() end
        if not move_ag:IsPlaying() then
            if settings["orientation"] == "bottom_to_top" then
                move_a:SetOffset(0, -offset)
            else
                move_a:SetOffset(0, offset)
            end
            move_ag:Play()
        end
    end

    function p:SetOnMoveFinished(script)
        move_ag:SetScript("OnFinished", script)
    end

    function p:StopMoving()
        if move_ag:IsPlaying() then
            move_ag:Finish()
        end
    end
end

---------------------------------------------------------------------
-- notificationPool
---------------------------------------------------------------------
local npCreationFn = function()
    local p = AW.CreateBorderedFrame(parent)
    p:Hide()

    CreateAnimation(p)
    p:EnableMouse(true)

    -- text ------------------------------------------------------------------ --
    local text = AW.CreateFontString(p)
    p.text = text
    AW.SetPoint(p.text, "LEFT", 7, 0)
    AW.SetPoint(p.text, "RIGHT", -7, 0)

    -- timerBar -------------------------------------------------------------- --
    local timerBar = CreateFrame("StatusBar", nil, p)
    p.timerBar = timerBar
    timerBar:SetStatusBarTexture(AW.GetPlainTexture())
    timerBar:SetStatusBarColor(AW.GetColorRGB("accent"))
    AW.SetPoint(timerBar, "BOTTOMLEFT", 1, 1)
    AW.SetPoint(timerBar, "BOTTOMRIGHT", -1, 1)
    AW.SetHeight(timerBar, 1)

    -- OnMouseUp ------------------------------------------------------------- --
    p:SetScript("OnMouseUp", function(self, button)
        if button ~= "RightButton" then return end
        if p.timer then
            p.timer:Cancel()
            p.timer = nil
        end
        AddToHidingQueue(p)
    end)

    -- OnHide --------------------------------------------------------------- --
    p:SetScript("OnHide", function()
        OnPopupHide(p)
        -- release
        notificationPool:Release(p)
    end)

    -- SetTimeout ------------------------------------------------------------ --
    function p:SetTimeout(timeout)
        p:SetScript("OnShow", function()
            -- update height
            p:SetScript("OnUpdate", function()
                p.text:SetWidth(Round(p:GetWidth()-14))
                p:SetHeight(Round(p.text:GetHeight())+40)
                p:SetScript("OnUpdate", nil)
            end)
            -- play sound
            PlaySoundFile(AW.GetSound("pop"))
            -- timer bar
            p.timer = C_Timer.NewTimer(timeout, function()
                p.timer = nil
                AddToHidingQueue(p)
            end)
            -- timerBar:SetReverseFill(settings["alignment"]=="RIGHT")
            timerBar:SetMinMaxValues(0, timeout)
            timerBar:SetValue(timeout)
            timerBar:SetScript("OnUpdate", function(self, elapsed)
                timeout = max(0, timeout - elapsed)
                timerBar:SetValue(timeout)
            end)
        end)
    end

    function p:UpdatePixels()
        AW.ReSize(p)
        AW.RePoint(p)
        AW.ReBorder(p)
        AW.ReSize(timerBar)
        AW.RePoint(timerBar)
    end

    return p
end
notificationPool = CreateObjectPool(npCreationFn)

---------------------------------------------------------------------
-- confirmPool
---------------------------------------------------------------------
local cpCreationFn = function()
    local p = AW.CreateBorderedFrame(parent)
    p:Hide()

    CreateAnimation(p)
    p:EnableMouse(true)

    -- text ------------------------------------------------------------------ --
    local text = AW.CreateFontString(p)
    p.text = text
    AW.SetPoint(p.text, "LEFT", 7, 5)
    AW.SetPoint(p.text, "RIGHT", -7, 5)

    -- button ---------------------------------------------------------------- --
    local no = AW.CreateButton(p, _G.NO, "red", 40, 15, nil, nil, nil, "AW_FONT_SMALL")
    p.no = no
    AW.SetPoint(no, "BOTTOMRIGHT")
    no:SetScript("OnClick", function()
        if p.onCancel then p.onCancel() end
        AW.Disable(p.yes, p.no)
        AddToHidingQueue(p)
    end)

    local yes = AW.CreateButton(p, _G.YES, "green", 40, 15, nil, nil, nil, "AW_FONT_SMALL")
    p.yes = yes
    AW.SetPoint(yes, "BOTTOMRIGHT", no, "BOTTOMLEFT", 1, 0)
    yes:SetScript("OnClick", function()
        if p.onConfirm then p.onConfirm() end
        AW.Disable(p.yes, p.no)
        AddToHidingQueue(p)
    end)

    -- OnShow ---------------------------------------------------------------- --
    p:SetScript("OnShow", function()
        AW.Enable(yes, no)
        -- update height
        p:SetScript("OnUpdate", function()
            p.text:SetWidth(Round(p:GetWidth()-14))
            p:SetHeight(Round(p.text:GetHeight())+50)
            p:SetScript("OnUpdate", nil)
        end)
        -- play sound
        PlaySoundFile(AW.GetSound("pop"))
    end)

    -- OnHide --------------------------------------------------------------- --
    p:SetScript("OnHide", function()
        OnPopupHide(p)
        -- release
        confirmPool:Release(p)
    end)

    return p
end
confirmPool = CreateObjectPool(cpCreationFn)

---------------------------------------------------------------------
-- progressPool
---------------------------------------------------------------------
local ppCreationFn = function()
    local p = AW.CreateBorderedFrame(parent)
    p:Hide()

    CreateAnimation(p)
    p:EnableMouse(true)

    -- text ------------------------------------------------------------------ --
    local text = AW.CreateFontString(p)
    p.text = text
    AW.SetPoint(p.text, "LEFT", 7, 0)
    AW.SetPoint(p.text, "RIGHT", -7, 0)

    -- progressBar ----------------------------------------------------------- --
    local bar = AW.CreateStatusBar(p, nil, nil, 5, 5, "accent", nil, "percentage")
    p.bar = bar
    AW.SetPoint(bar, "BOTTOMLEFT")
    AW.SetPoint(bar, "BOTTOMRIGHT")

    AW.ClearPoints(bar.progressText)
    AW.SetPoint(bar.progressText, "BOTTOMRIGHT", -1, 1)
    bar.progressText:SetFontObject("AW_FONT_SMALL")

    p.callback = function(value)
        if p.isSmoothedBar then
            p.bar:SetSmoothedValue(value)
        else
            p.bar:SetBarValue(value)
        end
        if value >= bar.maxValue then
            if p:IsShown() then
                C_Timer.After(DEFAULT_PROGRESS_TIMEOUT, function()
                    AddToHidingQueue(p)
                end)
            end
        end
    end

    -- OnShow ---------------------------------------------------------------- --
    p:SetScript("OnShow", function()
        -- update height
        p:SetScript("OnUpdate", function()
            p.text:SetWidth(Round(p:GetWidth()-14))
            p:SetHeight(Round(p.text:GetHeight())+40)
            p:SetScript("OnUpdate", nil)
        end)
        -- play sound
        PlaySoundFile(AW.GetSound("pop"))
        -- check if is done
        if bar:GetValue() >= bar.maxValue then
            C_Timer.After(DEFAULT_PROGRESS_TIMEOUT, function()
                AddToHidingQueue(p)
            end)
        end
    end)

    -- OnHide --------------------------------------------------------------- --
    p:SetScript("OnHide", function()
        OnPopupHide(p)
        -- release
        progressPool:Release(p)
    end)

    return p
end
progressPool = CreateObjectPool(ppCreationFn)

---------------------------------------------------------------------
-- notification popup
---------------------------------------------------------------------
function AW.ShowNotificationPopup(text, timeout, width, justify)
    local p = notificationPool:Acquire()
    p.text:SetText(text)
    AW.SetWidth(p, width or DEFAULT_WIDTH)
    p:SetTimeout(timeout or DEFAULT_NOTIFICATION_TIMEOUT)
    p.text:SetJustifyH("CENTER" or justify)
    -- AW.StylizeFrame(p, color, borderColor)

    tinsert(popups, p)
    p.index = #popups
    ShowPopups(true)
end

---------------------------------------------------------------------
-- confirm popup
---------------------------------------------------------------------
function AW.ShowConfirmPopup(text, onConfirm, onCancel, width, justify)
    local p = confirmPool:Acquire()
    p.text:SetText(text)
    p.onConfirm = onConfirm
    p.onCancel = onCancel
    AW.SetWidth(p, width or DEFAULT_WIDTH)
    p.text:SetJustifyH("CENTER" or justify)

    tinsert(popups, p)
    p.index = #popups
    ShowPopups(true)
end

---------------------------------------------------------------------
-- progress popup
---------------------------------------------------------------------
function AW.ShowProgressPopup(text, maxValue, isSmoothedBar, width, justify)
    local p = progressPool:Acquire()
    AW.SetWidth(p, width or DEFAULT_WIDTH)
    p.text:SetText(text)
    p.text:SetJustifyH("CENTER" or justify)
    p.bar:SetMinMaxValues(0, maxValue)
    p.bar:SetBarValue(0)
    p.isSmoothedBar = isSmoothedBar

    tinsert(popups, p)
    p.index = #popups
    ShowPopups(true)

    return p.callback
end