local M = {}

M.set_background = function(config, backgrounds, bg)
    config.background = { backgrounds[bg] }
end

-- we're just trusting that user will specify proper
-- type of setting for a given config option
-- I'm guessing Wezterm will complain if a bad option is passed
local function simple_override(overrides, name, value)
    if value == 'true' or value == 'false' then
        value = value == 'true' -- convert to bool
    elseif string.match(value, '^%d*%.?%d+$') then
        value = tonumber(value) -- convert to numeric
    end
    overrides[name] = value

    return overrides
end

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
            M.set_background(overrides, profile_data.backgrounds, value)
        end
    else
        overrides = simple_override(overrides, name, value)
    end

    return overrides
end

return M
