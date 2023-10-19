local M = {}

-- TODO: can this be more robust?
-- we're just trusting that user will specify acceptable
-- values for the config variable
-- if not, then they have to clear the overrides before continuing
-- to use the plugin
local function override_key_val(overrides, name, value)
    if value == 'true' or value == 'false' then
        value = value == 'true' -- convert to bool
    elseif string.match(value, '^%d*%.?%d+$') then
        value = tonumber(value) -- convert to numeric
    end
    overrides[name] = value

    return overrides
end

local function override_profile(overrides, var, profile_data, sel)
    overrides[var] = profile_data[var][sel]

    return overrides
end

local function check_profile_opt(opt)
    local sup_opts = { 'colors', 'background' }
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
function M.override_user_var(overrides, name, value, profile_data)
    -- TODO: add functionality to account for user
    -- not specifying profile_data table

    -- to draw a distinction between simple overrides and profile-type
    -- overrides, establish a required naming convention for certain user variables

    if string.match(name, '^profile_') then
        local config_var = string.gsub(name, 'profile_', '') -- remove the prefix
        print('hello from 1')
        overrides = override_profile(overrides, config_var, profile_data, value)
    else
        print('hello from 2')
        overrides = override_key_val(overrides, name, value)
    end

    return overrides
end

return M
