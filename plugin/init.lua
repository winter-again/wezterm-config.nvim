local wezterm = require('wezterm')
local M = {}

M.set_background = function(config, backgrounds, bg)
    config.background = { backgrounds[bg] }

    return config
end

-- we're just trusting that user will specify proper
-- type of setting for a given config option
local function simple_override(overrides, name, value)
    if value == 'true' or value == 'false' then
        value = value == 'true' -- convert to bool
        print('value is bool')
    elseif string.match(value, '^%d*%.?%d+$') then
        value = tonumber(value) -- convert to numeric
        print('value is numeric')
    else
        print('value is string')
    end
    overrides[name] = value

    return overrides
end

-- TODO: figure out if there's a way to clear overrides and return to
-- defaults without having to restart wezterm; like passing an empty overrides table?
M.user_var_override = function(overrides, name, value, profile_data)
    -- to draw a distinction between simple overrides and profile-type
    -- overrides, establish a required naming convention for user variables
    -- and use this to determine whether choices table needs to be utilized?
    if string.match(name, '^profile_') then
        -- instead of having to match each possible value
        -- it makes more sense remove the 'profile_' prefix
        -- and then use the resulting option
        name = string.gsub(name, 'profile_', '') -- remove the prefix
        if name == 'background' then
            overrides = M.set_background(overrides, profile_data.backgrounds, value)
        end
    else
        overrides = simple_override(overrides, name, value)
    end

    print('override fired')

    return overrides
end

return M
