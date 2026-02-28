---@class AbstractFramework
local AF = _G.AbstractFramework

local GetTime = GetTime
local NewTicker = C_Timer.NewTicker
local issecretvalue = issecretvalue or AF.noop_false

---------------------------------------------------------------------
-- local
---------------------------------------------------------------------
local ticker
local timers = {}
local statuses = {}

local StartTicker, StopTicker, UpdateTimers, UpdateStatus

UpdateTimers = function()
    local shouldStop = true

    local now = GetTime()
    for timer in next, timers do
        local guid = timer._timerGUID
        if guid then
            shouldStop = false
            local sec = now - statuses[guid].start
            timer:_callback(statuses[guid].status, sec)
        end
    end

    if shouldStop then
        StopTicker()
    end
end

StartTicker = function()
    if not ticker then
        ticker = NewTicker(1, UpdateTimers)
    end
end

StopTicker = function()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

UpdateStatus = function(guid, status)
    if not guid then return end

    if not status then
        statuses[guid] = nil
        return
    end

    if not statuses[guid] then
        statuses[guid] = {
            status = status,
            start = GetTime(),
        }
    elseif statuses[guid]["status"] ~= status then
        statuses[guid]["status"] = status
        statuses[guid]["start"] = GetTime()
    end
end

---------------------------------------------------------------------
-- AF_StatusTimerMixin
---------------------------------------------------------------------
---@class AF_StatusTimer
AF_StatusTimerMixin = {}

---@param func fun(self, status, sec)
function AF_StatusTimerMixin:SetCallback(func)
    self._callback = func
end

function AF_StatusTimerMixin:SetTimerGUID(guid)
    if guid and not issecretvalue(guid) then
        self._timerGUID = guid
    end
end

function AF_StatusTimerMixin:ClearTimerGUID()
    self._timerGUID = nil
end

function AF_StatusTimerMixin:IsTimerGUIDValid()
    return self._timerGUID ~= nil
end

local VALID_STATUSES = {
    OFFLINE = true,
    PENDING = true,
    ACCEPTED = true,
    DECLINED = true,
    AFK = true,
    FEIGN = true,
    GHOST = true,
    DEAD = true,
}

---@param status "OFFLINE"|"PENDING"|"ACCEPTED"|"DECLINED"|"AFK"|"FEIGN"|"GHOST"|"DEAD"|nil
function AF_StatusTimerMixin:StartTimer(status)
    if not (self:IsTimerGUIDValid() and status and VALID_STATUSES[status]) then
        self:StopTimer()
        return
    end

    local guid = self._timerGUID

    -- add to timers
    timers[self] = true

    -- update now
    UpdateStatus(guid, status)
    local sec = GetTime() - statuses[guid].start
    self:_callback(status, sec)

    -- start ticker
    StartTicker()
end

function AF_StatusTimerMixin:StopTimer(clearStatus)
    timers[self] = nil

    if clearStatus then
        UpdateStatus(self._timerGUID, nil)
    end

    if not next(timers) then
        StopTicker()
    end
end