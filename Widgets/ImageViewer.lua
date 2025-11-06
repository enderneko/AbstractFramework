---@class AbstractFramework
local AF = _G.AbstractFramework

local INITIAL_WIDTH = 720
local INITIAL_HEIGHT = 480
local SEPARATOR = AF.WrapTextInColor(" | ", "darkgray")
local TITLE_PATTERN = "%s" .. SEPARATOR .. "%d×%d" .. SEPARATOR .. "%.2f%%"
local MIN_SCALE = 0.1
local MAX_SCALE = 5.0

---------------------------------------------------------------------
-- preload
---------------------------------------------------------------------
local preloaderPool = AF.CreateObjectPool(function(pool)
    local tex = AF.UIParent:CreateTexture(nil, "ARTWORK")
    C_Timer.After(0.5, function()
        pool:Release(tex)
    end)
    return tex
end)

function AF.PreloadTexture(path)
    preloaderPool:Acquire():SetTexture(path)
end

---------------------------------------------------------------------
-- AF_ImageViewer
---------------------------------------------------------------------
local pool

---@class AF_ImageViewer:AF_HeaderedFrame
local AF_ImageViewerMixin = {}

local function ImageViewer_UpdateTitle(self)
    self.header.text:SetFormattedText(TITLE_PATTERN,
        self.fileName or "N/A",
        self.imageWidth or 0, self.imageHeight or 0,
        self.scale * 100
    )
end

local function ImageViewer_OnClose(closeBtn)
    local f = closeBtn:GetParent():GetParent()
    f:Hide()

    if f.loader then
        f.loader:Cancel()
        f.loader = nil
    end

    if f.ticker then
        f.ticker:Cancel()
        f.ticker = nil
    end

    f:SetTitle("")
    f.panel.image:SetTexture(nil)
    f.panel.image:SetPoint("CENTER")
    f.panel.image:SetAlpha(0)
    f.panel.image:SetSize(0, 0)

    f.mode = nil

    f.path = nil
    f.scale = 1.0
    f.fileName = nil
    f.imageWidth = nil
    f.imageHeight = nil

    f.interval = nil
    f.startIndex = nil
    f.endIndex = nil
    f.currentIndex = nil

    f.rows = nil
    f.columns = nil
    f.frames = nil
    f.duration = nil
    f.animation:Stop()
    f.panel.image:SetTexCoord(0, 1, 0, 1)

    pool:Release(f)
end

---------------------------------------------------------------------
-- play image sequence
---------------------------------------------------------------------
local function ImageViewer_SequenceOnTick(ticker)
    local f = ticker.owner
    f.currentIndex = f.currentIndex + 1
    if f.currentIndex > f.endIndex then
        f.currentIndex = f.startIndex
    end

    local imagePath = f.path:format(f.currentIndex)
    f.panel.image:SetTexture(imagePath)
end

local function ImageViewer_PlaySequence(self)
    if not self.startIndex or not self.endIndex then return end
    if self.endIndex <= self.startIndex then return end

    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    self.ticker = C_Timer.NewTicker(self.interval, ImageViewer_SequenceOnTick)
    self.ticker.owner = self
end

---------------------------------------------------------------------
-- play flipbook
---------------------------------------------------------------------
local function ImageViewer_PlayFlipBook(self)
    self.animation:Stop()
    self.panel.image:SetTexCoord(0, 1, 0, 1)
    self.animation:Restart()
end

---------------------------------------------------------------------
-- load image
---------------------------------------------------------------------
local function ImageViewer_Load(loader)
    local f = loader.owner

    if not f.panel.image:IsObjectLoaded() then return end
    loader:Cancel()
    f.loader = nil

    local w, h = f.panel.image:GetSize()
    w, h = AF.Round(w), AF.Round(h)

    if w == 0 or h == 0 then
        f.panel.image:SetTexCoord(0, 1, 0, 1)
        f.panel.image:SetTexture(AF.GetIcon("NoImage"))
        f.panel.image:SetPoint("CENTER")
        f.panel.image:SetAlpha(0.5)
        f.imageWidth = nil
        f.imageHeight = nil
        return
    end

    if f.mode == "flipbook" then
        w = AF.Round(w / f.columns)
        h = AF.Round(h / f.rows)
        f.animation.flipbook:SetFlipBookFrameWidth(w)
        f.animation.flipbook:SetFlipBookFrameHeight(h)
    end

    f.imageWidth = w
    f.imageHeight = h

    -- resize
    local panelW, panelH = f.panel:GetSize()
    local scale = 1.0
    if w > panelW or h > panelH then
        scale = min(panelW / w, panelH / h)
    end

    local displayW = AF.Round(w * scale)
    local displayH = AF.Round(h * scale)

    f.panel.image:SetSize(displayW, displayH)
    f.panel.image:SetPoint("CENTER")
    f.panel.image:SetAlpha(1)
    f.scale = scale

    ImageViewer_UpdateTitle(f)

    if f.mode == "sequence" then
        -- give a bit more time for preloading
        C_Timer.After(0.1, function()
            ImageViewer_PlaySequence(f)
        end)
    elseif f.mode == "flipbook" then
        ImageViewer_PlayFlipBook(f)
    end
end

---------------------------------------------------------------------
-- resize & drag
---------------------------------------------------------------------
local function ImageViewerPanel_OnMouseWheel(panel, delta)
    local f = panel:GetParent()
    if not f.imageWidth or not f.imageHeight then return end
    if panel.isDragging then return end

    local oldScale = f.scale
    local newScale = AF.Clamp(f.scale * (delta > 0 and 1.1 or 0.9), MIN_SCALE, MAX_SCALE)
    if oldScale == newScale then return end

    if (oldScale < 1.0 and newScale > 1.0) or (oldScale > 1.0 and newScale < 1.0) then
        -- snap to 1.0
        newScale = 1.0
    end
    f.scale = newScale

    local displayW = AF.Round(f.imageWidth * newScale)
    local displayH = AF.Round(f.imageHeight * newScale)
    panel.image:SetSize(displayW, displayH)

    ImageViewer_UpdateTitle(f)

    --! adjust position to keep image inside panel
    local curX, curY = select(4, panel.image:GetPoint())
    local offsetX, offsetY = 0, 0
    local scaleRatio = newScale / oldScale

    if delta < 0 then
        --! zoom out
        local pL, pR, pT, pB = panel:GetLeft(), panel:GetRight(), panel:GetTop(), panel:GetBottom()
        local iL, iR, iT, iB = panel.image:GetLeft(), panel.image:GetRight(), panel.image:GetTop(), panel.image:GetBottom()

        -- x
        if panel.image:GetWidth() < panel:GetWidth() then -- image covers panel horizontally
            offsetX = -curX -- move to centerX
        elseif iL > pL and iR > pR then -- gap is on the left, and right side is out
            if iL - pL < iR - pR then -- left gap < right overflow
                offsetX = -(iL - pL) -- move left side to panel left
            else
                offsetX = -curX -- move to centerX
            end
        elseif iR < pR and iL < pL then -- gap is on the right, and left side is out
            if pR - iR < pL - iL then -- right gap < left overflow
                offsetX = pR - iR -- move right side to panel right
            else
                offsetX = -curX -- move to centerX
            end
        else
            offsetX = curX * scaleRatio - curX
        end

        -- y
        if panel.image:GetHeight() < panel:GetHeight() then -- image covers panel vertically
            offsetY = -curY -- move to centerY
        elseif iB > pB and iT > pT then -- gap is on the bottom, and top side is out
            if iB - pB < iT - pT then -- bottom gap < top overflow
                offsetY = -(iB - pB) -- move bottom side to panel bottom
            else
                offsetY = -curY -- move to centerY
            end
        elseif iT < pT and iB < pB then -- gap is on the top, and bottom side is out
            if pT - iT < pB - iB then -- top gap < bottom overflow
                offsetY = pT - iT -- move top side to panel top
            else
                offsetY = -curY -- move to centerY
            end
        else
            offsetY = curY * scaleRatio - curY
        end

        panel.image:SetPoint("CENTER", curX + offsetX, curY + offsetY)
    else
        offsetX = curX * scaleRatio - curX
        offsetY = curY * scaleRatio - curY
        panel.image:SetPoint("CENTER", curX + offsetX, curY + offsetY)
    end
end

local function ImageViewerPanel_OnDragging(panel)
    panel.newMouseX, panel.newMouseY = GetCursorPosition()
    if panel.newMouseX == panel.lastMouseX and panel.newMouseY == panel.lastMouseY then return end

    panel.lastMouseX = panel.newMouseX
    panel.lastMouseY = panel.newMouseY

    local newX = panel.startX + AF.Clamp((panel.newMouseX - panel.mouseX) / panel.effectiveScale, panel.minOffsetX, panel.maxOffsetX)
    local newY = panel.startY + AF.Clamp((panel.newMouseY - panel.mouseY) / panel.effectiveScale, panel.minOffsetY, panel.maxOffsetY)

    panel.image:SetPoint("CENTER", newX, newY)
end

local function GetMinMaxOffsets(panel)
    local pL, pR, pT, pB = panel:GetLeft(), panel:GetRight(), panel:GetTop(), panel:GetBottom()
    local iL, iR, iT, iB = panel.image:GetLeft(), panel.image:GetRight(), panel.image:GetTop(), panel.image:GetBottom()

    -- local scale = panel:GetScale()

    local minOffsetX, maxOffsetX, minOffsetY, maxOffsetY = 0, 0, 0, 0

    -- minOffsetX
    if iR > pR then minOffsetX = pR - iR end
    -- maxOffsetX
    if iL < pL then maxOffsetX = pL - iL end
    -- minOffsetY
    if iT > pT then minOffsetY = pT - iT end
    -- maxOffsetY
    if iB < pB then maxOffsetY = pB - iB end

    return minOffsetX, maxOffsetX, minOffsetY, maxOffsetY
end

local function ImageViewerPanel_OnMouseDown(panel, button)
    if button ~= "LeftButton" then return end

    panel.isDragging = true
    panel.effectiveScale = panel:GetEffectiveScale()
    panel.mouseX, panel.mouseY = GetCursorPosition()
    panel.lastMouseX, panel.lastMouseY = panel.mouseX, panel.mouseY
    panel.startX, panel.startY = select(4, panel.image:GetPoint())
    panel.minOffsetX, panel.maxOffsetX, panel.minOffsetY, panel.maxOffsetY = GetMinMaxOffsets(panel)

    panel:SetScript("OnUpdate", ImageViewerPanel_OnDragging)
end

local function ImageViewerPanel_OnMouseUp(panel, button)
    if button ~= "LeftButton" then return end
    panel.isDragging = false
    panel:SetScript("OnUpdate", nil)
end

---------------------------------------------------------------------
-- LoadImage
---------------------------------------------------------------------
---@param path string
---@param windowWidth number|nil
---@param windowHeight number|nil
function AF_ImageViewerMixin:LoadImage(path, windowWidth, windowHeight)
    assert(type(path) == "string", "path must be a string")

    self.mode = "image"
    self.path = path
    self.scale = 1.0
    self.fileName = path:match("([^\\/:]+)$")

    self:SetSize(windowWidth or INITIAL_WIDTH, windowHeight or INITIAL_HEIGHT)
    self:ClearAllPoints()
    self:SetPoint("CENTER")
    self:Show()

    self.panel.image:SetAlpha(0)
    self.panel.image:SetSize(0, 0)
    self.panel.image:SetTextureOrAtlas(path)

    self.loader = C_Timer.NewTicker(0.1, ImageViewer_Load)
    self.loader.owner = self

    ImageViewer_UpdateTitle(self)
end

---------------------------------------------------------------------
-- LoadImageSequence
---------------------------------------------------------------------
---@param path string
---@param nameFormat string|nil e.g. "image_%02d.png", if nil, path is used directly with index formatting
---@param startIndex number
---@param endIndex number
---@param interval number seconds for each image
---@param windowWidth number|nil
---@param windowHeight number|nil
function AF_ImageViewerMixin:LoadImageSequence(path, nameFormat, startIndex, endIndex, interval, windowWidth, windowHeight)
    assert(type(path) == "string", "path must be a string")
    -- assert(type(nameFormat) == "string", "nameFormat must be a string")
    assert(type(startIndex) == "number", "startIndex must be a number")
    assert(type(endIndex) == "number", "endIndex must be a number")
    -- assert(endIndex > startIndex, "endIndex must be greater than startIndex")
    assert(type(interval) == "number", "interval must be a number")

    if nameFormat then
        if path:sub(-1) ~= "/" and path:sub(-1) ~= "\\" then
            path = path .. "\\"
        end
        path = path .. nameFormat
    end

    -- try preloading images
    for i = startIndex, endIndex do
        AF.PreloadTexture(path:format(i))
    end

    self.mode = "sequence"
    self.path = path
    self.scale = 1.0
    self.fileName = path:format(startIndex):match("([^\\/:]+)$")

    self.startIndex = startIndex
    self.endIndex = endIndex
    self.interval = interval
    self.currentIndex = startIndex

    self:SetSize(windowWidth or INITIAL_WIDTH, windowHeight or INITIAL_HEIGHT)
    self:ClearAllPoints()
    self:SetPoint("CENTER")
    self:Show()

    self.panel.image:SetAlpha(0)
    self.panel.image:SetSize(0, 0)
    self.panel.image:SetTexture(path:format(startIndex))

    self.loader = C_Timer.NewTicker(0.1, ImageViewer_Load)
    self.loader.owner = self

    ImageViewer_UpdateTitle(self)
end

---------------------------------------------------------------------
-- LoadFlipBook
---------------------------------------------------------------------
---@param path string
---@param rows number
---@param columns number
---@param frames number
---@param duration number total seconds to play all frames once
---@param windowWidth number|nil
---@param windowHeight number|nil
function AF_ImageViewerMixin:LoadFlipBook(path, rows, columns, frames, duration, windowWidth, windowHeight)
    assert(type(path) == "string", "path must be a string")
    assert(type(rows) == "number", "rows must be a number")
    assert(type(columns) == "number", "columns must be a number")
    assert(type(frames) == "number", "frames must be a number")
    assert(type(duration) == "number", "duration must be a number")

    self.mode = "flipbook"
    self.path = path
    self.scale = 1.0
    self.fileName = path:match("([^\\/:]+)$")

    self.rows = rows
    self.columns = columns
    self.frames = frames
    self.duration = duration

    self.animation.flipbook:SetDuration(duration)
    self.animation.flipbook:SetFlipBookRows(rows)
    self.animation.flipbook:SetFlipBookColumns(columns)
    self.animation.flipbook:SetFlipBookFrames(frames)
    self.animation:Stop()

    self:SetSize(windowWidth or INITIAL_WIDTH, windowHeight or INITIAL_HEIGHT)
    self:ClearAllPoints()
    self:SetPoint("CENTER")
    self:Show()

    self.panel.image:SetAlpha(0)
    self.panel.image:SetSize(0, 0)
    self.panel.image:SetTexCoord(0, 1 / columns, 0, 1 / rows)
    self.panel.image:SetTexture(path)

    self.loader = C_Timer.NewTicker(0.1, ImageViewer_Load)
    self.loader.owner = self

    ImageViewer_UpdateTitle(self)
end

---------------------------------------------------------------------
-- pool
---------------------------------------------------------------------
pool = AF.CreateObjectPool(function(pool)
    local f = AF.CreateHeaderedFrame(AF.UIParent, "AFImageViewer" .. (pool:GetNumActive() + 1), nil, nil, nil, "HIGH", 777, true)
    f:Hide()
    f:SetTitleJustify("LEFT")

    f.header.closeBtn:SetOnClick(ImageViewer_OnClose)
    f.header.text:SetFontObject("AF_FONT_NORMAL")

    local panel = CreateFrame("Frame", nil, f)
    f.panel = panel
    panel:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT")
    panel:SetPoint("BOTTOMRIGHT")
    panel:SetScript("OnMouseWheel", ImageViewerPanel_OnMouseWheel)
    panel:SetScript("OnMouseDown", ImageViewerPanel_OnMouseDown)
    panel:SetScript("OnMouseUp", ImageViewerPanel_OnMouseUp)
    panel:SetClipsChildren(true)

    local image = AF.CreateTexture(panel)
    panel.image = image
    image:SetPoint("CENTER")
    image:SetAlpha(0)
    image:SetSize(0, 0)

    local animation = f:CreateAnimationGroup()
    f.animation = animation
    animation:SetLooping("REPEAT")

    local flipbook = animation:CreateAnimation("FlipBook")
    animation.flipbook = flipbook
    flipbook:SetTarget(image)

    animation:Stop()

    f.resizeBtn = AF.CreateResizeButton(f, 100, 100)
    AF.SetFrameLevel(f.resizeBtn, 10)

    Mixin(f, AF_ImageViewerMixin)

    return f
end)

---------------------------------------------------------------------
-- api
---------------------------------------------------------------------
---@param path string
---@param windowWidth number|nil
---@param windowHeight number|nil
function AF.ImageViewer_LoadImage(path, windowWidth, windowHeight)
    pool:Acquire():LoadImage(path, windowWidth, windowHeight)
end

-- NOT RECOMMENDED FOR LARGE IMAGES<br/>
-- event with a preloader, images may flicker when loading a sequence
---@param path string
---@param nameFormat string|nil e.g. "image_%02d.png", if nil, path is used directly with index formatting
---@param startIndex number
---@param endIndex number
---@param interval number
---@param windowWidth number|nil
---@param windowHeight number|nil
function AF.ImageViewer_LoadImageSequence(path, nameFormat, startIndex, endIndex, interval, windowWidth, windowHeight)
    pool:Acquire():LoadImageSequence(path, nameFormat, startIndex, endIndex, interval, windowWidth, windowHeight)
end

---@param path string
---@param rows number
---@param columns number
---@param frames number
---@param duration number
---@param windowWidth number|nil
---@param windowHeight number|nil
function AF.ImageViewer_LoadFlipBook(path, rows, columns, frames, duration, windowWidth, windowHeight)
    pool:Acquire():LoadFlipBook(path, rows, columns, frames, duration, windowWidth, windowHeight)
end