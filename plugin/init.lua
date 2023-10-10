local M = {}

-- we're just trusting that user will specify acceptable
-- values for the config variable
-- if not, then they have to clear the overrides before continuing
-- to use the plugin
local function override_key_val(overrides, name, value)
    if value == 'true' or value == 'false' then
        value = value == 'true' -- convert to bool
        -- print('value is bool')
    elseif string.match(value, '^%d*%.?%d+$') then
        value = tonumber(value) -- convert to numeric
        -- print('value is numeric')
    -- else
        -- print('value is string')
    end
    overrides[name] = value

    return overrides
end

-- support a handful of more complex overrides
-- all of these require passing some "profile" data from within
-- the wezterm config, which then allows users to pick one of
-- their profiles as the override

local function override_profile(overrides, var, profile_data, sel)
    -- print('var is ' .. var) -- 'background'
    -- print('sel is ' .. sel) -- 'bg_1'
    -- print(profile_data == nil)
    overrides[var] = profile_data[var][sel]

    return overrides
end

-- TODO: add functionality to account for user
-- not specifying profile_data
M.override_user_var = function(overrides, name, value, profile_data)
    -- to draw a distinction between simple overrides and profile-type
    -- overrides, establish a required naming convention for user variables
    -- if the user wants to use this function as a single entry point into
    -- into the plugin
    if string.match(name, '^profile_') then
        local config_var = string.gsub(name, 'profile_', '') -- remove the prefix
        -- there's probably a better way to know which variable-specific override
        -- func to call instead of using series of if statements
        -- need to handle for invalid config_var?
        -- there's also the expectation that profile_data has the fields ref below
        -- if config_var == 'background' then
        --     overrides = override_background(overrides, profile_data.backgrounds, value)
        -- elseif config_var == 'colors' then
        --     overrides = override_colors(overrides, profile_data.colors, value)
        -- end
        overrides = override_profile(overrides, config_var, profile_data, value)
    else
        overrides = override_key_val(overrides, name, value)
    end

    return overrides
end

return M
