-- TODO:
-- simple workaround to avoid nvim trying to load this module
-- https://github.com/wez/wezterm/issues/4533#issuecomment-1874094722
-- is there a better alt?
if vim ~= nil then
    return
end

local wezterm = require('wezterm')
local M = {}

---@param var string
---@return boolean
function M.is_shell_integ_user_var(var)
    local shell_integ_user_vars = {
        'WEZTERM_PROG',
        'WEZTERM_USER',
        'WEZTERM_HOST',
        'WEZTERM_IN_TMUX',
    }
    for _, val in ipairs(shell_integ_user_vars) do
        if val == var then
            return true
        end
    end
    return false
end

---Interpret the Wezterm user var that is passed in and
---make the appropriate changes to the given overrides table;
---for use within a callback function in Wezterm config
---for the 'user-var-changed' event
---@param overrides table
---@param name string
---@param value string
---@return table
function M.override_user_var(overrides, name, value)
    if not M.is_shell_integ_user_var(name) then
        -- returns tbl if successfully parsed
        -- otherwise it returns 1 (?) so I guess an error code or at least
        -- something with type == 'number'

        -- local ok, parsed_val = pcall(wezterm.json_parse, value)
        local parsed_val = wezterm.json_parse(value)
        -- if type(parsed_val) == 'table' then
        --     parsed_val = parsed_val.value
        -- end

        if type(parsed_val) == 'table' then
            overrides[name] = parsed_val
        else
            if parsed_val == 'true' or parsed_val == 'false' then
                -- convert to bool
                parsed_val = parsed_val == 'true'
            elseif string.match(parsed_val, '^%d*%.?%d+$') then
                -- convert to number
                parsed_val = tonumber(parsed_val)
            end
            overrides[name] = parsed_val
        end
    end
    return overrides
end

return M
