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

    local newEnv = setmetatable(type(env) == "table" and env or {}, {__index = _G})

    local chunk, err = loadstring(script)
    if not chunk then return nil, err end

    setfenv(chunk, newEnv)

    return chunk
end

---@param script string lua code to compile
---@param env table environment table to set as the chunk's environment
---@return function|nil compiled chunk when successful
---@return string|nil error message when compilation fails
function AF.CompileWithEnv(script, env)
    if type(script) ~= "string" or script == "" then
        return nil, "empty script"
    end

    local chunk, err = loadstring(script)
    if not chunk then return nil, err end

    if env then
        setfenv(chunk, env)
    end

    return chunk
end