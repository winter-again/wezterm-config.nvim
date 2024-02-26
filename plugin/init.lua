-- TODO:
-- simple workaround to avoid nvim trying to load this module
-- https://github.com/wez/wezterm/issues/4533#issuecomment-1874094722
-- is there a better alt?
if vim ~= nil then
    return
end

local wezterm = require('wezterm')
local M = {}

---@param overrides table
---@param name string
---@param value string
local function override_key_val(overrides, name, value)
    if value == 'true' or value == 'false' then
        -- convert to bool
        value = value == 'true'
    elseif string.match(value, '^%d*%.?%d+$') then
        -- convert to number
        value = tonumber(value)
    end
    overrides[name] = value
    return overrides
end

local function override_profile(overrides, var, profile_data, sel)
    overrides[var] = profile_data[var][sel]
    return overrides
end

local function check_profile_opt(opt)
    local sup_opts = { 'colors', 'background', 'font' }
    local is_sup = false
    for _, sup_opt in ipairs(sup_opts) do
        if opt == sup_opt then
            is_sup = true
        end
    end
    return is_sup
end

---interprets the Wezterm user var that got overridden and uses a specific helper
---function to apply overrides to the passed overrides table, for use within
---a callback function in Wezterm config
---@param overrides table
---@param name string
---@param value string
---@param profile_data table
---@return table
function M.__override_user_var(overrides, name, value, profile_data)
    if string.match(name, '^profile_') then
        local config_var = string.gsub(name, 'profile_', '') -- remove the prefix
        if check_profile_opt(config_var) then
            overrides = override_profile(overrides, config_var, profile_data, value)
        else
            -- this gets printed to Wezterm logs at the INFO level
            -- because print is an alias for wezterm.log_info()
            print("This profile option isn't currently supported")
        end
    else
        overrides = override_key_val(overrides, name, value)
    end
    return overrides
end

---Interpret the Wezterm user var that got overridden and use a specific helper
---function to apply overrides to the passed overrides table; for use within
---a callback function in Wezterm config
---@param overrides table
---@param name string
---@param value string
---@return table
function M.override_user_var(overrides, name, value)
    -- TODO: figure out how to just have one override func
    -- aka detect whether the value passed is table or something simple
    -- may have to put some condition on whether json_parse() works on the value?
    -- or do a check before calling parse func

    -- returns tbl if successfully parsed
    -- otherwise it returns 1 (?) so I guess an error code or at least
    -- something with type == 'number'
    local parsed_val = wezterm.json_parse(value)
    if type(parsed_val) == 'table' then
        overrides[name] = parsed_val
    else
        if value == 'true' or value == 'false' then
            -- convert to bool
            value = value == 'true'
        elseif string.match(value, '^%d*%.?%d+$') then
            -- convert to number
            value = tonumber(value)
        end
        overrides[name] = value
    end
    return overrides
end

return M
