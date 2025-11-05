---@class AbstractFramework
local AF = _G.AbstractFramework

---@class AF_ImagePane:AF_BorderedFrame
local AF_ImagePaneMixin = {}

local function ImagePane_SequenceOnTick(timer)
    local pane = timer.owner
    pane.currentIndex = pane.currentIndex + 1
    if pane.currentIndex > pane.endIndex then
        pane.currentIndex = pane.startIndex
    end

    local imagePath = pane.path:format(pane.currentIndex)
    pane.image:SetTexture(imagePath)
end

local function ImagePane_PlaySequence(self)
    if not self.startIndex or not self.endIndex then return end
    if self.endIndex <= self.startIndex then return end

    if self.timer then
        self.timer:Cancel()
        self.timer = nil
    end

    self.timer = C_Timer.NewTicker(self.interval, ImagePane_SequenceOnTick)
    self.timer.owner = self
end

local function ImagePane_PlayFlipBook(self)
    self.animation:Stop()
    self.image:SetTexCoord(0, 1, 0, 1)
    self.animation:Restart()
end

local function ImagePane_ApplySize(pane, w, h, p)
    if pane.expandable == "horizontal" then
        pane:SetWidth(w + p * 2)
    elseif pane.expandable == "vertical" then
        pane:SetHeight(h + p * 2)
    end
    pane.image:SetSize(w, h)
end

local function ImagePane_Load(loader)
    local pane = loader.owner

    if not pane.image:IsObjectLoaded() then return end
    loader:Cancel()
    pane.loader = nil

    local rawW, rawH = pane.image:GetSize()
    rawW, rawH = AF.Round(rawW), AF.Round(rawH)

    local success
    if rawW == 0 or rawH == 0 then
        pane.image:SetTexCoord(0, 1, 0, 1)
        pane.image:SetTexture(AF.GetIcon("NoImage"))
        rawW, rawH = 64, 64
        success = false
    else
        success = true
    end

    if success and pane.mode == "flipbook" then
        rawW = AF.Round(rawW / pane.columns)
        rawH = AF.Round(rawH / pane.rows)
        pane.animation.flipbook:SetFlipBookFrameWidth(rawW) -- SetFlipBookFrameWidth(0)
        pane.animation.flipbook:SetFlipBookFrameHeight(rawH) -- SetFlipBookFrameHeight(0)
    end

    -- resize
    local convertedW, convertedH = AF.ConvertPixelsForRegion(rawW, pane), AF.ConvertPixelsForRegion(rawH, pane)
    local padding = AF.ConvertPixelsForRegion(pane.padding, pane)
    local maxW, maxH = pane:GetSize()

    if maxW == 0 and maxH == 0 then
        ImagePane_ApplySize(pane, 0, 0, padding)
        pane.image:SetAlpha(0)
        return
    end

    maxW = maxW - padding * 2
    maxH = maxH - padding * 2

    if success and pane.displayMode == "fit" then
        -- fit: scale (up or down) to fill the constrained direction
        if pane.expandable == "horizontal" then
            -- force height to fill, scale width accordingly
            local scale = maxH / convertedH
            convertedH = maxH
            convertedW = convertedW * scale
            ImagePane_ApplySize(pane, convertedW, convertedH, padding)

        elseif pane.expandable == "vertical" then
            -- force width to fill, scale height accordingly
            local scale = maxW / convertedW
            convertedW = maxW
            convertedH = convertedH * scale
            ImagePane_ApplySize(pane, convertedW, convertedH, padding)

        else -- "none"
            -- scale to best-fit the available area (can scale up)
            local scale = math.min(maxW / convertedW, maxH / convertedH)
            ImagePane_ApplySize(pane, convertedW * scale, convertedH * scale, padding)
        end
    else -- "center"
        -- center: keep native size unless it exceeds available area
        if pane.expandable == "horizontal" then
            -- fixed height, shrink height if necessary and scale width
            if convertedH > maxH then
                local scale = maxH / convertedH
                convertedH = maxH
                convertedW = convertedW * scale
            end
            ImagePane_ApplySize(pane, convertedW, convertedH, padding)

        elseif pane.expandable == "vertical" then
            -- fixed width, shrink width if necessary and scale height
            if convertedW > maxW then
                local scale = maxW / convertedW
                convertedW = maxW
                convertedH = convertedH * scale
            end
            ImagePane_ApplySize(pane, convertedW, convertedH, padding)

        else -- "none"
            -- fixed area, only shrink to fit
            if convertedW > maxW or convertedH > maxH then
                local scale = math.min(maxW / convertedW, maxH / convertedH)
                ImagePane_ApplySize(pane, convertedW * scale, convertedH * scale, padding)
            else
                ImagePane_ApplySize(pane, convertedW, convertedH, padding)
            end
        end
    end

    if success then
        AF.FrameFadeIn(pane.image, nil, 0, 1)
    else
        AF.FrameFadeIn(pane.image, nil, 0, 0.5)
    end

    if pane.loadedCallback then
        pane.loadedCallback(pane:GetWidth(), pane:GetHeight(), rawW, rawH)
    end

    if not success then return end

    if pane.mode == "sequence" then
        -- give a bit more time for preloading
        pane.timer = C_Timer.NewTimer(0.1, function()
            ImagePane_PlaySequence(pane)
        end)
    elseif pane.mode == "flipbook" then
        ImagePane_PlayFlipBook(pane)
    end
end

---@param path string
function AF_ImagePaneMixin:LoadImage(path)
    assert(type(path) == "string", "path must be a string")

    self.mode = "image"
    self.path = path

    self.image:SetAlpha(0)
    self.image:SetSize(0, 0)
    self.image:SetTextureOrAtlas(path)
    self.image:SetTexCoord(0, 1, 0, 1)

    self.loader = C_Timer.NewTicker(0.1, ImagePane_Load)
    self.loader.owner = self
end

---@param path string
---@param nameFormat string e.g. "image_%02d.png"
---@param startIndex number
---@param endIndex number
---@param interval number seconds for each image
function AF_ImagePaneMixin:LoadImageSequence(path, nameFormat, startIndex, endIndex, interval)
    assert(type(path) == "string", "path must be a string")
    assert(type(nameFormat) == "string", "nameFormat must be a string")
    assert(type(startIndex) == "number", "startIndex must be a number")
    assert(type(endIndex) == "number", "endIndex must be a number")
    -- assert(endIndex > startIndex, "endIndex must be greater than startIndex")
    assert(type(interval) == "number", "interval must be a number")

    if path:sub(-1) ~= "/" and path:sub(-1) ~= "\\" then
        path = path .. "\\"
    end
    path = path .. nameFormat

    -- try preloading images
    for i = startIndex, endIndex do
        AF.PreloadTexture(path:format(i))
    end

    self.mode = "sequence"
    self.path = path

    self.startIndex = startIndex
    self.endIndex = endIndex
    self.interval = interval
    self.currentIndex = startIndex

    self.image:SetAlpha(0)
    self.image:SetSize(0, 0)
    self.image:SetTexture(path:format(startIndex))

    self.loader = C_Timer.NewTicker(0.1, ImagePane_Load)
    self.loader.owner = self
end

---@param path string
---@param rows number
---@param columns number
---@param frames number
---@param duration number total seconds to play all frames once
function AF_ImagePaneMixin:LoadFlipBook(path, rows, columns, frames, duration)
    assert(type(path) == "string", "path must be a string")
    assert(type(rows) == "number", "rows must be a number")
    assert(type(columns) == "number", "columns must be a number")
    assert(type(frames) == "number", "frames must be a number")
    assert(type(duration) == "number", "duration must be a number")

    self.mode = "flipbook"
    self.path = path

    self.rows = rows
    self.columns = columns
    self.frames = frames
    self.duration = duration

    self.animation.flipbook:SetDuration(duration)
    self.animation.flipbook:SetFlipBookRows(rows)
    self.animation.flipbook:SetFlipBookColumns(columns)
    self.animation.flipbook:SetFlipBookFrames(frames)
    self.animation:Stop()

    self.image:SetAlpha(0)
    self.image:SetSize(0, 0)
    self.image:SetTexCoord(0, 1 / columns, 0, 1 / rows)
    self.image:SetTexture(path)

    self.loader = C_Timer.NewTicker(0.1, ImagePane_Load)
    self.loader.owner = self
end

function AF_ImagePaneMixin:Reload()
    if not self.path then return end

    if self.mode == "image" then
        self:LoadImage(self.path)
    elseif self.mode == "sequence" then
        self:LoadImageSequence(self.path, nil, self.startIndex, self.endIndex, self.interval)
    elseif self.mode == "flipbook" then
    end
end

function AF_ImagePaneMixin:Clear()
    if self.loader then
        self.loader:Cancel()
        self.loader = nil
    end

    if self.timer then
        self.timer:Cancel()
        self.timer = nil
    end

    self.animation:Stop()

    self.mode = nil
    self.path = nil
    self.startIndex = nil
    self.endIndex = nil
    self.interval = nil
    self.currentIndex = nil
    self.rows = nil
    self.columns = nil
    self.frames = nil
    self.duration = nil

    self.image:SetTexture(nil)
    self.image:SetTexCoord(0, 1, 0, 1)
    self.image:SetSize(0, 0)
    self.image:SetAlpha(0)
end

---@param displayMode "center"|"fit"
function AF_ImagePaneMixin:SetDisplayMode(displayMode)
    assert(displayMode == "center" or displayMode == "fit", "displayMode must be 'center' or 'fit'")
    self.displayMode = displayMode
end

---@param expandable "horizontal"|"vertical"|"none"
function AF_ImagePaneMixin:SetExpandable(expandable)
    assert(expandable == "horizontal" or expandable == "vertical" or expandable == "none", "expandable must be 'horizontal', 'vertical', or 'none'")
    self.expandable = expandable
end

---@param callback fun(paneWidth: number, paneHeight: number, rawImageWidth: number, rawImageHeight: number)|nil
function AF_ImagePaneMixin:SetLoadedCallback(callback)
    self.loadedCallback = callback
end

---@param parent Frame
---@param padding number|nil default is 0
---@param displayMode "center"|"fit" default is "center"
---@param expandable "horizontal"|"vertical"|"none" default is "none"
---@return AF_ImagePane
function AF.CreateImagePane(parent, padding, displayMode, expandable)
    local pane = AF.CreateBorderedFrame(parent)
    Mixin(pane, AF_ImagePaneMixin)
    pane:SetClipsChildren(true)

    local image = AF.CreateTexture(pane)
    pane.image = image
    image:SetPoint("CENTER")

    local animation = pane:CreateAnimationGroup()
    pane.animation = animation
    animation:SetLooping("REPEAT")

    local flipbook = animation:CreateAnimation("FlipBook")
    animation.flipbook = flipbook
    flipbook:SetTarget(image)

    animation:Stop()

    pane.padding = padding or 0
    pane.expandable = expandable or "none"
    pane.displayMode = displayMode or "center"

    return pane
end