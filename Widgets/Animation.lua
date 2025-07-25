---@class AbstractFramework
local AF = _G.AbstractFramework

local next = next
local abs, min, max = math.abs, math.min, math.max

-----------------------------------------------------------------------------
--                        manager based animations                         --
-----------------------------------------------------------------------------
local ANIMATION_INTERVAL = 0.025

---------------------------------------------------------------------
-- alpha - inspired by ElvUI
---------------------------------------------------------------------
local FADEFRAMES, FADEMANAGER = {}, CreateFrame("FRAME")

local function Fading(_, elapsed)
    FADEMANAGER.timer = (FADEMANAGER.timer or 0) + elapsed

    if FADEMANAGER.timer > ANIMATION_INTERVAL then
        FADEMANAGER.timer = 0

        for frame, info in next, FADEFRAMES do
            if frame:IsVisible() then
                info.fadeTimer = (info.fadeTimer or 0) + (elapsed + ANIMATION_INTERVAL)
            else -- faster for hidden frames
                info.fadeTimer = info.timeToFade + 1
            end

            if info.fadeTimer < info.timeToFade then
                if info.mode == "IN" then
                    frame:SetAlpha((info.fadeTimer / info.timeToFade) * info.diffAlpha + info.startAlpha)
                else
                    frame:SetAlpha(((info.timeToFade - info.fadeTimer) / info.timeToFade) * info.diffAlpha + info.endAlpha)
                end
            else
                frame:SetAlpha(info.endAlpha)
                if frame and FADEFRAMES[frame] then
                    if frame._fade then
                        frame._fade.fadeTimer = nil
                    end
                    FADEFRAMES[frame] = nil
                end
            end
        end

        if not next(FADEFRAMES) then
            FADEMANAGER:SetScript("OnUpdate", nil)
        end
    end
end

local function FrameFade(frame, info)
    frame:SetAlpha(info.startAlpha)

    if not frame:IsProtected() then
        frame:Show()
    end

    if not FADEFRAMES[frame] then
        FADEFRAMES[frame] = info
        FADEMANAGER:SetScript("OnUpdate", Fading)
    else
        FADEFRAMES[frame] = info
    end
end

function AF.FrameFadeIn(frame, timeToFade, startAlpha, endAlpha)
    if frame._fade then
        frame._fade.fadeTimer = nil
    else
        frame._fade = {}
    end

    frame._fade.mode = "IN"
    frame._fade.timeToFade = timeToFade or 0.25
    frame._fade.startAlpha = startAlpha or frame:GetAlpha()
    frame._fade.endAlpha = endAlpha or 1
    frame._fade.diffAlpha = frame._fade.endAlpha - frame._fade.startAlpha

    if frame._fade.startAlpha ~= frame._fade.endAlpha then
        FrameFade(frame, frame._fade)
    end
end

function AF.FrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
    if frame._fade then
        frame._fade.fadeTimer = nil
    else
        frame._fade = {}
    end

    frame._fade.mode = "OUT"
    frame._fade.timeToFade = timeToFade
    frame._fade.startAlpha = startAlpha or frame:GetAlpha()
    frame._fade.endAlpha = endAlpha or 0
    frame._fade.diffAlpha = frame._fade.startAlpha - frame._fade.endAlpha

    if frame._fade.startAlpha ~= frame._fade.endAlpha then
        FrameFade(frame, frame._fade)
    end
end

---------------------------------------------------------------------
-- continual fade in and out
---------------------------------------------------------------------
local CONTINUAL_FADEFRAMES, CONTINUAL_FADEMANAGER = {}, CreateFrame("FRAME")

local function ContinualFading(_, elapsed)
    CONTINUAL_FADEMANAGER.timer = (CONTINUAL_FADEMANAGER.timer or 0) + elapsed

    if CONTINUAL_FADEMANAGER.timer > ANIMATION_INTERVAL then
        CONTINUAL_FADEMANAGER.timer = 0

        for frame, info in next, CONTINUAL_FADEFRAMES do
            info.fadeTimer = (info.fadeTimer or 0) + ANIMATION_INTERVAL

            if info.phase == "IN" then
                if info.fadeTimer < info.timeToFade then
                    frame:SetAlpha((info.fadeTimer / info.timeToFade))
                else
                    frame:SetAlpha(1)
                    info.phase = "HOLD"
                    info.fadeTimer = 0
                end
            elseif info.phase == "HOLD" then
                if info.fadeTimer >= info.holdTime then
                    info.phase = "OUT"
                    info.fadeTimer = 0
                end
            elseif info.phase == "OUT" then
                if info.fadeTimer < info.timeToFade then
                    frame:SetAlpha(1 - (info.fadeTimer / info.timeToFade))
                else
                    frame:SetAlpha(0)
                    if not frame:IsProtected() then
                        frame:Hide()
                    end
                    if frame and CONTINUAL_FADEFRAMES[frame] then
                        CONTINUAL_FADEFRAMES[frame] = nil
                        if frame._continualFade then frame._continualFade.fadeTimer = nil end
                    end
                end
            end
        end

        if not next(CONTINUAL_FADEFRAMES) then
            CONTINUAL_FADEMANAGER:SetScript("OnUpdate", nil)
        end
    end
end

local function FrameFadeInOut(frame, info)
    frame:SetAlpha(0)

    if not frame:IsProtected() then
        frame:Show()
    end

    CONTINUAL_FADEFRAMES[frame] = info
    CONTINUAL_FADEMANAGER:SetScript("OnUpdate", ContinualFading)
end

function AF.FrameFadeInOut(frame, timeToFade, holdTime)
    if frame._continualFade then
        frame._continualFade.fadeTimer = nil
    else
        frame._continualFade = {}
    end

    local info = frame._continualFade
    info.timeToFade = timeToFade or 0.25
    info.holdTime = holdTime or 0.5
    info.phase = "IN"
    info.fadeTimer = 0

    FrameFadeInOut(frame, info)
end

---------------------------------------------------------------------
-- zoom
---------------------------------------------------------------------
local ZOOMFRAMES, ZOOMMANAGER = {}, CreateFrame("FRAME")

local function Zooming(_, elapsed)
    ZOOMMANAGER.timer = (ZOOMMANAGER.timer or 0) + elapsed

    if ZOOMMANAGER.timer > ANIMATION_INTERVAL then
        ZOOMMANAGER.timer = 0

        for frame, info in next, ZOOMFRAMES do
            if frame:IsVisible() then
                info.zoomTimer = (info.zoomTimer or 0) + (elapsed + ANIMATION_INTERVAL)
            else -- faster for hidden frames
                info.zoomTimer = info.timeToZoom + 1
            end

            if info.zoomTimer < info.timeToZoom then
                if info.mode == "IN" then
                    frame:SetScale((info.zoomTimer / info.timeToZoom) * info.diffScale + info.startScale)
                else
                    frame:SetScale(((info.timeToZoom - info.zoomTimer) / info.timeToZoom) * info.diffScale + info.endScale)
                end
            else
                frame:SetScale(info.endScale)
                -- NOTE: remove from ZOOMFRAMES
                if frame and ZOOMFRAMES[frame] then
                    if frame._zoom then
                        frame._zoom.zoomTimer = nil
                    end
                    ZOOMFRAMES[frame] = nil
                end
            end
        end

        if not next(ZOOMFRAMES) then
            ZOOMMANAGER:SetScript("OnUpdate", nil)
        end
    end
end

local function FrameZoom(frame, info)
    frame:SetScale(info.startScale)

    if not frame:IsProtected() then
        frame:Show()
    end

    if not ZOOMFRAMES[frame] then
        ZOOMFRAMES[frame] = info
        ZOOMMANAGER:SetScript("OnUpdate", Zooming)
    else
        ZOOMFRAMES[frame] = info
    end
end

function AF.FrameZoomIn(frame, timeToZoom, startScale, endScale)
    if frame._zoom then
        frame._zoom.zoomTimer = nil
    else
        frame._zoom = {}
    end

    frame._zoom.mode = "IN"
    frame._zoom.timeToZoom = timeToZoom or 0.25
    frame._zoom.startScale = startScale or frame:GetScale()
    frame._zoom.endScale = endScale or 1
    frame._zoom.diffScale = frame._zoom.endScale - frame._zoom.startScale

    FrameZoom(frame, frame._zoom)
end

function AF.FrameZoomOut(frame, timeToZoom, startScale, endScale)
    if frame._zoom then
        frame._zoom.zoomTimer = nil
    else
        frame._zoom = {}
    end

    frame._zoom.mode = "OUT"
    frame._zoom.timeToZoom = timeToZoom
    frame._zoom.startScale = startScale or frame:GetScale()
    frame._zoom.endScale = endScale or 0
    frame._zoom.diffScale = frame._zoom.startScale - frame._zoom.endScale

    FrameZoom(frame, frame._zoom)
end

function AF.FrameZoomTo(frame, timeToZoom, endScale)
    if frame._zoom then
        frame._zoom.zoomTimer = nil
    else
        frame._zoom = {}
    end

    frame._zoom.timeToZoom = timeToZoom
    frame._zoom.startScale = frame:GetScale()
    frame._zoom.endScale = endScale
    frame._zoom.diffScale = abs(frame._zoom.startScale - frame._zoom.endScale)

    if frame._zoom.startScale > frame._zoom.endScale then
        frame._zoom.mode = "OUT"
        FrameZoom(frame, frame._zoom)
    elseif frame._zoom.startScale < frame._zoom.endScale then
        frame._zoom.mode = "IN"
        FrameZoom(frame, frame._zoom)
    end
end

---------------------------------------------------------------------
-- size
---------------------------------------------------------------------
local SIZEFRAMES, SIZEMANAGER = {}, CreateFrame("FRAME")

local function Sizing(_, elapsed)
    SIZEMANAGER.timer = (SIZEMANAGER.timer or 0) + elapsed

    if SIZEMANAGER.timer > ANIMATION_INTERVAL then
        SIZEMANAGER.timer = 0

        for frame, info in next, SIZEFRAMES do
            if frame:IsVisible() then
                info.sizeTimer = (info.sizeTimer or 0) + (elapsed + ANIMATION_INTERVAL)
            else -- faster for hidden frames
                info.sizeTimer = info.timeToSize + 1
            end

            if info.sizeTimer < info.timeToSize then
                local progress = info.sizeTimer / info.timeToSize
                local currentWidth = info.startWidth + info.diffWidth * progress
                local currentHeight = info.startHeight + info.diffHeight * progress

                frame:SetSize(currentWidth, currentHeight)
            else
                frame:SetSize(info.endWidth, info.endHeight)
                -- NOTE: remove from SIZEFRAMES
                if frame and SIZEFRAMES[frame] then
                    if frame._size then
                        frame._size.sizeTimer = nil
                    end
                    SIZEFRAMES[frame] = nil
                end
            end
        end

        if not next(SIZEFRAMES) then
            SIZEMANAGER:SetScript("OnUpdate", nil)
        end
    end
end

local function FrameSize(frame, info)
    frame:SetSize(info.startWidth, info.startHeight)

    if not frame:IsProtected() then
        frame:Show()
    end

    if not SIZEFRAMES[frame] then
        SIZEFRAMES[frame] = info
        SIZEMANAGER:SetScript("OnUpdate", Sizing)
    else
        SIZEFRAMES[frame] = info
    end
end

local function FixZero(n)
    if n == 0 then
        return 0.001
    end
    return n
end

function AF.FrameSizeTo(frame, timeToSize, startWidth, startHeight, endWidth, endHeight)
    if frame._size then
        frame._size.sizeTimer = nil
    else
        frame._size = {}
    end

    frame._size.timeToSize = timeToSize or 0.25
    frame._size.startWidth = FixZero(startWidth or frame:GetWidth())
    frame._size.startHeight = FixZero(startHeight or frame:GetHeight())
    frame._size.endWidth = FixZero(endWidth or frame:GetWidth())
    frame._size.endHeight = FixZero(endHeight or frame:GetHeight())
    frame._size.diffWidth = frame._size.endWidth - frame._size.startWidth
    frame._size.diffHeight = frame._size.endHeight - frame._size.startHeight

    if frame._size.startWidth ~= frame._size.endWidth or frame._size.startHeight ~= frame._size.endHeight then
        FrameSize(frame, frame._size)
    end
end

function AF.FrameResizeWidth(frame, timeToSize, startWidth, endWidth)
    local currentHeight = frame:GetHeight()
    AF.FrameSizeTo(frame, timeToSize, startWidth, currentHeight, endWidth, currentHeight)
end

function AF.FrameResizeHeight(frame, timeToSize, startHeight, endHeight)
    local currentWidth = frame:GetWidth()
    AF.FrameSizeTo(frame, timeToSize, currentWidth, startHeight, currentWidth, endHeight)
end





-----------------------------------------------------------------------------
--                         self managed animations                         --
-----------------------------------------------------------------------------
---------------------------------------------------------------------
-- fade-in/out animation group
---------------------------------------------------------------------
local fade_in_out = {
    FadeIn = function(region)
        if not region.fadeIn:IsPlaying() then
            region.fadeIn:Play()
        end
    end,

    FadeOut = function(region)
        if not region.fadeOut:IsPlaying() then
            region.fadeOut:Play()
        end
    end,

    ShowNow = function(region)
        region.fadeIn:Stop()
        region.fadeOut:Stop()
        region:SetAlpha(1)
        region:Show()
    end,

    HideNow = function(region)
        region.fadeIn:Stop()
        region.fadeOut:Stop()
        region:SetAlpha(0)
        region:Hide()
    end,
}

function AF.CreateFadeInOutAnimation(region, duration, noHide)
    duration = duration or 0.25

    local in_ag = region:CreateAnimationGroup()
    region.fadeIn = in_ag

    local out_ag = region:CreateAnimationGroup()
    region.fadeOut = out_ag

    for k, v in pairs(fade_in_out) do
        region[k] = v
    end

    -- in -----------------------------------------------------------
    local in_a = in_ag:CreateAnimation("Alpha")
    in_ag.alpha = in_a
    in_a:SetFromAlpha(0)
    in_a:SetToAlpha(1)
    in_a:SetDuration(duration)

    in_ag:SetScript("OnPlay", function()
        out_ag:Stop()
        region:Show()
    end)

    in_ag:SetScript("OnFinished", function()
        region:SetAlpha(1)
    end)
    -----------------------------------------------------------------

    -- out ----------------------------------------------------------
    local out_a = out_ag:CreateAnimation("Alpha")
    out_ag.alpha = out_a
    out_a:SetFromAlpha(1)
    out_a:SetToAlpha(0)
    out_a:SetDuration(duration)

    out_ag:SetScript("OnPlay", function()
        in_ag:Stop()
        region:Show()
    end)

    out_ag:SetScript("OnFinished", function()
        region:SetAlpha(0)
        if not noHide then
            region:Hide()
        end
    end)
    -----------------------------------------------------------------
end

function AF.SetFadeInOutAnimationDuration(region, duration)
    if not (duration and region.fadeIn and region.fadeOut) then return end

    region.fadeIn.alpha:SetDuration(duration)
    region.fadeOut.alpha:SetDuration(duration)
end

---------------------------------------------------------------------
-- continual fade-in-out
---------------------------------------------------------------------
local function FadeInOut(region)
    region.fade:Restart()
end

function AF.CreateContinualFadeInOutAnimation(region, duration, delay)
    duration = duration or 0.25
    delay = delay or 1

    region.FadeInOut = FadeInOut

    local ag = region:CreateAnimationGroup()
    region.fade = ag

    -- in -----------------------------------------------------------
    local in_a = ag:CreateAnimation("Alpha")
    ag.fadeIn = in_a
    in_a:SetOrder(1)
    in_a:SetFromAlpha(0)
    in_a:SetToAlpha(1)
    in_a:SetDuration(duration)
    -----------------------------------------------------------------

    -- out ----------------------------------------------------------
    local out_a = ag:CreateAnimation("Alpha")
    ag.fadeOut = out_a
    out_a:SetOrder(2)
    out_a:SetStartDelay(delay)
    out_a:SetFromAlpha(1)
    out_a:SetToAlpha(0)
    out_a:SetDuration(duration)
    -----------------------------------------------------------------

    ag:SetScript("OnPlay", function()
        region:Show()
    end)
    ag:SetScript("OnFinished", function()
        region:Hide()
    end)
end

---------------------------------------------------------------------
-- blink
---------------------------------------------------------------------
function AF.CreateBlinkAnimation(region, duration, enableShowHideHook)
    local blink = region:CreateAnimationGroup()
    region.blink = blink

    local alpha = blink:CreateAnimation("Alpha")
    blink.alpha = alpha
    alpha:SetFromAlpha(0.25)
    alpha:SetToAlpha(1)
    alpha:SetDuration(duration or 0.5)

    blink:SetLooping("BOUNCE")

    if enableShowHideHook then
        region:HookScript("OnShow", function()
            blink:Play()
        end)
        region:HookScript("OnHide", function()
            blink:Stop()
        end)
    else
        blink:Play()
    end
end

---------------------------------------------------------------------
-- resize with animation
---------------------------------------------------------------------
---@param frame Frame
---@param targetWidth? number
---@param targetHeight? number
---@param frequency? number default 0.015
---@param onStart? function called when animation starts
---@param onFinish? function called when animation ends
---@param onChange? function called when size changes, with currentWidth and currentHeight as parameters
---@param steps? number total steps to final size, default 7
---@param anchorPoint? string TOPLEFT|TOPRIGHT|BOTTOMLEFT|BOTTOMRIGHT
function AF.AnimatedResize(frame, targetWidth, targetHeight, frequency, steps, onStart, onFinish, onChange, anchorPoint)
    if frame._animatedResizeTimer then
        frame._animatedResizeTimer:Cancel()
        frame._animatedResizeTimer = nil
    end

    frequency = frequency or 0.015
    steps = steps or 7

    if anchorPoint then
        -- anchorPoint is only for those frames of which the direct parent is UIParent
        assert(frame:GetParent() == AF.UIParent)
        local left = AF.Round(frame:GetLeft())
        local right = AF.Round(frame:GetRight())
        local top = AF.Round(frame:GetTop())
        local bottom = AF.Round(frame:GetBottom())

        AF.ClearPoints(frame)
        if anchorPoint == "TOPLEFT" then
            frame:SetPoint("TOPLEFT", AF.UIParent, "BOTTOMLEFT", left, top)
        elseif anchorPoint == "TOPRIGHT" then
            frame:SetPoint("TOPRIGHT", AF.UIParent, "BOTTOMLEFT", right, top)
        elseif anchorPoint == "BOTTOMLEFT" then
            frame:SetPoint("BOTTOMLEFT", AF.UIParent, "BOTTOMLEFT", left, bottom)
        elseif anchorPoint == "BOTTOMRIGHT" then
            frame:SetPoint("BOTTOMRIGHT", AF.UIParent, "BOTTOMLEFT", right, bottom)
        end
    end

    if onStart then onStart() end

    local currentHeight = frame._height or frame:GetHeight()
    local currentWidth = frame._width or frame:GetWidth()
    targetWidth = targetWidth or currentWidth
    targetHeight = targetHeight or currentHeight

    local diffW = (targetWidth - currentWidth) / steps
    local diffH = (targetHeight - currentHeight) / steps

    frame._animatedResizeTimer = C_Timer.NewTicker(frequency, function()
        if not AF.ApproxZero(diffW) then
            if diffW > 0 then
                currentWidth = min(currentWidth + diffW, targetWidth)
            else
                currentWidth = max(currentWidth + diffW, targetWidth)
            end
            AF.SetWidth(frame, currentWidth)
        end

        if not AF.ApproxZero(diffH) then
            if diffH > 0 then
                currentHeight = min(currentHeight + diffH, targetHeight)
            else
                currentHeight = max(currentHeight + diffH, targetHeight)
            end
            AF.SetHeight(frame, currentHeight)
        end

        if onChange then
            onChange(currentWidth, currentHeight)
        end

        if AF.ApproxEqual(currentWidth, targetWidth) and AF.ApproxEqual(currentHeight, targetHeight) then
            frame._animatedResizeTimer:Cancel()
            frame._animatedResizeTimer = nil
            if targetWidth then AF.SetWidth(frame, targetWidth) end
            if targetHeight then AF.SetHeight(frame, targetHeight) end
            if onFinish then onFinish() end
        end
    end)
end