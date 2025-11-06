---@class AbstractFramework
local AF = _G.AbstractFramework

---@param script string lua code to compile
---@param env table|nil optional environment table to merge with global env
---@return function|nil compiled chunk when successful
---@return string|nil error message when compilation fails
function AF.CompileWithGlobalEnv(script, env)
    if type(script) ~= "string" or script == "" then
        return nil, "empty script"
    end

    local newEnv = setmetatable({}, { __index = _G })

    if type(env) == "table" then
        AF.MergeRaw(newEnv, env)
    end

    local chunk, err = loadstring(script)
    if not chunk then return nil, err end

    if setfenv then
        setfenv(chunk, newEnv)
    end

    return chunk
end