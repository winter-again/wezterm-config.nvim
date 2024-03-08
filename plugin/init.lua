vim.keymap.set('n', '<leader><leader>1', function()
    wezterm_config.set_wezterm_user_var('background', profile_data.background.default)
end)
-- TODO:
-- simple workaround to avoid nvim trying to load this module
-- https://github.com/wez/wezterm/issues/4533#issuecomment-1874094722
-- is there a better alt?
if vim ~= nil then
    return
end

local wezterm = require('wezterm')
local M = {}

---Interpret the Wezterm user var that is passed in and
---make the appropriate changes to the given overrides table;
---for use within a callback function in Wezterm config
---for the 'user-var-changed' event
---@param overrides table
---@param name string
---@param value string
---@return table
function M.override_user_var(overrides, name, value)
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
