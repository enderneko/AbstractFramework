---@class AbstractFramework
local AF = _G.AbstractFramework

local INITIAL_WIDTH = 720
local INITIAL_HEIGHT = 480
local SEPARATOR = AF.WrapTextInColor(" | ", "darkgray")
local TITLE_PATTERN = "%s" .. SEPARATOR .. "%d×%d" .. SEPARATOR .. "%.2f%%"
local MIN_SCALE = 0.1
local MAX_SCALE = 5.0

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

    f:SetTitle("")
    f.panel.image:SetTexture(nil)
    f.panel.image:SetPoint("CENTER")
    f.panel.image:SetAlpha(0)
    f.panel.image:SetSize(0, 0)

    f.path = nil
    f.scale = 1.0
    f.fileName = nil
    f.imageWidth = nil
    f.imageHeight = nil

    pool:Release(f)
end

---------------------------------------------------------------------
-- LoadImage
---------------------------------------------------------------------
local function ImageViewer_OnTick(ticker)
    local f = ticker.owner

    if not f.panel.image:IsObjectLoaded() then return end
    ticker:Cancel()
    f.ticker = nil

    local w, h = f.panel.image:GetSize()
    if w == 0 or h == 0 then
        f.panel.image:SetTexture(AF.GetIcon("NoImage"))
        f.panel.image:SetPoint("CENTER")
        f.panel.image:SetAlpha(0.5)
        f.imageWidth = nil
        f.imageHeight = nil
        return
    end

    f.imageWidth = AF.Round(w)
    f.imageHeight = AF.Round(h)

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
end

local function ImageViewerPanel_OnMouseWheel(panel, delta)
    local f = panel:GetParent()
    if f.mode ~= "image" then return end
    if not f.imageWidth or not f.imageHeight then return end
    if panel.isDragging then return end

    local oldScale = f.scale
    local newScale = AF.Clamp(f.scale * (delta > 0 and 1.1 or 0.9), MIN_SCALE, MAX_SCALE)
    f.scale = newScale

    local displayW = floor(f.imageWidth * newScale + 0.5)
    local displayH = floor(f.imageHeight * newScale + 0.5)
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

function AF_ImageViewerMixin:LoadImage(path, frameWidth, frameHeight)
    assert(type(path) == "string", "Path must be a string")

    self.mode = "image"
    self.path = path
    self.scale = 1.0
    self.fileName = path:match("([^\\/:]+)$")

    self:SetSize(frameWidth or INITIAL_WIDTH, frameHeight or INITIAL_HEIGHT)
    self:ClearAllPoints()
    self:SetPoint("CENTER")
    self:Show()

    self.panel.image:SetAlpha(0)
    self.panel.image:SetSize(0, 0)
    self.panel.image:SetTextureOrAtlas(path)

    self.ticker = C_Timer.NewTicker(0.1, ImageViewer_OnTick)
    self.ticker.owner = self

    ImageViewer_UpdateTitle(self)
end

---------------------------------------------------------------------
-- pool
---------------------------------------------------------------------
pool = AF.CreateObjectPool(function(pool)
    local f = AF.CreateHeaderedFrame(AF.UIParent, "AFImageViewer" .. (pool:GetNumActive() + 1), nil, nil, nil, "HIGH", 777, true)
    f:Hide()
    f:SetClampRectInsets(0, 0, 0, 0)
    f:SetTitleJustify("LEFT")

    AF.SetFrameLevel(f.header, 5)
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

    f.resizeBtn = AF.CreateResizeButton(f, 100, 100)
    AF.SetFrameLevel(f.resizeBtn, 10)

    Mixin(f, AF_ImageViewerMixin)

    return f
end)

---------------------------------------------------------------------
-- image
---------------------------------------------------------------------
function AF.ImageViewer_LoadImage(path, frameWidth, frameHeight)
    pool:Acquire():LoadImage(path, frameWidth, frameHeight)
end

---------------------------------------------------------------------
-- image sequence
---------------------------------------------------------------------
function AF.ImageViewer_LoadImageSequence()

end

---------------------------------------------------------------------
-- flipbook
---------------------------------------------------------------------
function AF.ImageViewer_LoadFlipBook()

end