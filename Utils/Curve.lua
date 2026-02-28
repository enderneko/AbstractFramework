---@class AbstractFramework
local AF = select(2, ...)

---------------------------------------------------------------------
--    ___     _          ___
--   / __|___| |___ _ _ / __|  _ _ ___ _____
--  | (__/ _ \ / _ \ '_| (_| || | '_\ V / -_)
--   \___\___/_\___/_|  \___\_,_|_|  \_/\___|
--
---------------------------------------------------------------------
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local cos, PI = math.cos, math.pi
local type, next, wipe = type, next, wipe
local UnpackColor = AF.UnpackColor

---@class AF_ColorCurve
local AF_ColorCurveMixin = {}

---@return AF_ColorCurve
function AF.CreateColorCurve()
    local curve = CreateFromMixins(AF_ColorCurveMixin)
    curve:Init()
    return curve
end

function AF_ColorCurveMixin:Init()
    self.points = {}
    self:SetType("linear")
end

local function ComparePoints(a, b)
    return a.x < b.x
end

local function AddPoint(self, x, y, skipSort)
    local r, g, b, a

    if type(y) == "string" then
        r, g, b, a = AF.GetColorRGB(y)
    elseif type(y) == "table" then
        r, g, b, a = AF.UnpackColor(y)
    end

    for _, point in next, self.points do
        if point.x == x then
            point.r, point.g, point.b, point.a = r, g, b, a
            return
        end
    end

    tinsert(self.points, {x = x, r = r, g = g, b = b, a = a})

    if not skipSort then
        tsort(self.points, ComparePoints)
    end
end

---@param x number
---@param y string|table "colorName" or {r, g, b, a}
function AF_ColorCurveMixin:AddPoint(x, y)
    AddPoint(self, x, y)
end

---@param index number
function AF_ColorCurveMixin:RemovePoint(index)
    if self.points[index] then
        tremove(self.points, index)
    end
end

---@param points table {{x, y}, ...}
function AF_ColorCurveMixin:SetPoints(points)
    wipe(self.points)
    for _, point in next, points do
        AddPoint(self, point[1], point[2], true)
    end
    tsort(self.points, ComparePoints)
end

function AF_ColorCurveMixin:ClearPoints()
    wipe(self.points)
end

---@return table
function AF_ColorCurveMixin:GetPoints()
    return self.points
end

---@return number
function AF_ColorCurveMixin:GetPointCount()
    return #self.points
end

-- Linear interpolation
local function EvaluateLinear(self, x)
    local points = self.points
    local n = #points
    local result = self._evalResult or {}
    self._evalResult = result

    if n == 0 then
        result[1], result[2], result[3], result[4] = 0, 0, 0, 0
        return result
    end

    local first = points[1]

    if n == 1 then
        result[1], result[2], result[3], result[4] = first.r, first.g, first.b, first.a or 1
        return result
    end

    local last = points[n]

    if x <= first.x then
        result[1], result[2], result[3], result[4] = first.r, first.g, first.b, first.a or 1
        return result
    end

    if x >= last.x then
        result[1], result[2], result[3], result[4] = last.r, last.g, last.b, last.a or 1
        return result
    end

    for i = 1, n - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]

        if x >= p1.x and x <= p2.x then
            local t = (x - p1.x) / (p2.x - p1.x)
            local a1, a2 = p1.a or 1, p2.a or 1
            result[1] = p1.r + (p2.r - p1.r) * t
            result[2] = p1.g + (p2.g - p1.g) * t
            result[3] = p1.b + (p2.b - p1.b) * t
            result[4] = a1 + (a2 - a1) * t
            return result
        end
    end

    result[1], result[2], result[3], result[4] = 0, 0, 0, 0
    return result
end

-- Step interpolation (no interpolation)
local function EvaluateStep(self, x)
    local points = self.points
    local n = #points
    local result = self._evalResult or {}
    self._evalResult = result

    if n == 0 then
        result[1], result[2], result[3], result[4] = 0, 0, 0, 0
        return result
    end

    local first = points[1]

    if n == 1 or x <= first.x then
        result[1], result[2], result[3], result[4] = first.r, first.g, first.b, first.a or 1
        return result
    end

    local last = points[n]

    if x >= last.x then
        result[1], result[2], result[3], result[4] = last.r, last.g, last.b, last.a or 1
        return result
    end

    for i = 1, n - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]

        if x >= p1.x and x < p2.x then
            result[1], result[2], result[3], result[4] = p1.r, p1.g, p1.b, p1.a or 1
            return result
        end
    end

    result[1], result[2], result[3], result[4] = last.r, last.g, last.b, last.a or 1
    return result
end

-- Cosine interpolation
local function EvaluateCosine(self, x)
    local points = self.points
    local n = #points
    local result = self._evalResult or {}
    self._evalResult = result

    if n == 0 then
        result[1], result[2], result[3], result[4] = 0, 0, 0, 0
        return result
    end

    local first = points[1]

    if n == 1 then
        result[1], result[2], result[3], result[4] = first.r, first.g, first.b, first.a or 1
        return result
    end

    local last = points[n]

    if x <= first.x then
        result[1], result[2], result[3], result[4] = first.r, first.g, first.b, first.a or 1
        return result
    end

    if x >= last.x then
        result[1], result[2], result[3], result[4] = last.r, last.g, last.b, last.a or 1
        return result
    end

    for i = 1, n - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]

        if x >= p1.x and x <= p2.x then
            local t = (x - p1.x) / (p2.x - p1.x)
            -- Cosine smoothing: t = (1 - cos(t * π)) / 2
            local smoothT = (1 - cos(t * PI)) / 2
            local a1, a2 = p1.a or 1, p2.a or 1
            result[1] = p1.r + (p2.r - p1.r) * smoothT
            result[2] = p1.g + (p2.g - p1.g) * smoothT
            result[3] = p1.b + (p2.b - p1.b) * smoothT
            result[4] = a1 + (a2 - a1) * smoothT
            return result
        end
    end

    result[1], result[2], result[3], result[4] = 0, 0, 0, 0
    return result
end

-- Cubic interpolation (Catmull-Rom spline)
local function EvaluateCubic(self, x)
    local points = self.points
    local n = #points
    local result = self._evalResult or {}
    self._evalResult = result

    if n == 0 then
        result[1], result[2], result[3], result[4] = 0, 0, 0, 0
        return result
    end

    local first = points[1]

    if n < 4 then
        -- Fall back to cosine interpolation
        return EvaluateCosine(self, x)
    end

    local last = points[n]

    if x <= first.x then
        result[1], result[2], result[3], result[4] = first.r, first.g, first.b, first.a or 1
        return result
    end

    if x >= last.x then
        result[1], result[2], result[3], result[4] = last.r, last.g, last.b, last.a or 1
        return result
    end

    for i = 2, n - 2 do
        local p1 = points[i]
        local p2 = points[i + 1]

        if x >= p1.x and x <= p2.x then
            local p0 = points[i - 1]
            local p3 = points[i + 2]

            local t = (x - p1.x) / (p2.x - p1.x)
            local t2 = t * t
            local t3 = t2 * t

            -- Catmull-Rom spline coefficients
            local c0 = -0.5 * t3 + t2 - 0.5 * t
            local c1 = 1.5 * t3 - 2.5 * t2 + 1
            local c2 = -1.5 * t3 + 2 * t2 + 0.5 * t
            local c3 = 0.5 * t3 - 0.5 * t2

            local a0, a1, a2, a3 = p0.a or 1, p1.a or 1, p2.a or 1, p3.a or 1
            result[1] = p0.r * c0 + p1.r * c1 + p2.r * c2 + p3.r * c3
            result[2] = p0.g * c0 + p1.g * c1 + p2.g * c2 + p3.g * c3
            result[3] = p0.b * c0 + p1.b * c1 + p2.b * c2 + p3.b * c3
            result[4] = a0 * c0 + a1 * c1 + a2 * c2 + a3 * c3
            return result
        end
    end

    -- Fall back to linear for edge segments
    return EvaluateLinear(self, x)
end

local evaluateFunctions = {
    linear = EvaluateLinear,
    step = EvaluateStep,
    cosine = EvaluateCosine,
    cubic = EvaluateCubic,
}

---@param curveType "linear"|"step"|"cosine"|"cubic"
function AF_ColorCurveMixin:SetType(curveType)
    curveType = curveType and curveType:lower() or "linear"
    local evaluateFunc = evaluateFunctions[curveType]
    if evaluateFunc then
        self.type = curveType
        self.Evaluate = evaluateFunc
    end
end

---@return string curveType
function AF_ColorCurveMixin:GetType()
    return self.type or "linear"
end

---@param x number
---@return number r
---@return number g
---@return number b
function AF_ColorCurveMixin:EvaluateUnpacked(x)
    return UnpackColor(self:Evaluate(x))
end

---------------------------------------------------------------------
-- Blizzard Curve
---------------------------------------------------------------------
if C_CurveUtil then
    local CreateCurve = C_CurveUtil.CreateCurve
    local CreateColorCurve = C_CurveUtil.CreateColorCurve
    local LuaCurveType = Enum.LuaCurveType

    local function GetTypeValue(curveType)
        if type(curveType) ~= "string" then
            return LuaCurveType.Linear
        end
        return LuaCurveType[AF.UpperFirst(curveType)] or LuaCurveType.Linear
    end

    ---@param points table {{position:number, color:string|table}, ...}
    ---@param curveType "linear"|"step"|"cosine"|"cubic"|nil
    function AF.CreateBlizzardColorCurve(points, curveType)
        local curve = CreateColorCurve()

        curve:SetType(GetTypeValue(curveType))
        for _, point in next, points do
            if type(point.color) == "string" then
                curve:AddPoint(point.position, CreateColor(AF.GetColorRGB(point.color)))
            elseif type(point.color) == "table" then
                curve:AddPoint(point.position, CreateColor(AF.UnpackColor(point.color)))
            end
        end

        return curve
    end

    function AF.GetAlphaCurve_HideWhenFull()
        local alphaCurve = CreateCurve()
        alphaCurve:SetType(LuaCurveType.Step)
        alphaCurve:AddPoint(0, 1)
        alphaCurve:AddPoint(1, 0)
        return alphaCurve
    end

    function AF.GetAlphaCurve_HideWhenEmpty()
        local alphaCurve = CreateCurve()
        alphaCurve:SetType(LuaCurveType.Step)
        alphaCurve:AddPoint(0, 0)
        alphaCurve:AddPoint(0.00000000000001, 1)
        return alphaCurve
    end

    function AF.GetAlphaCurve_HideWhenFullOrEmpty()
        local alphaCurve = CreateCurve()
        alphaCurve:SetType(LuaCurveType.Step)
        alphaCurve:AddPoint(0, 0)
        alphaCurve:AddPoint(0.00000000000001, 1)
        alphaCurve:AddPoint(0.99999999999999, 1)
        alphaCurve:AddPoint(1, 0)
        return alphaCurve
    end
end