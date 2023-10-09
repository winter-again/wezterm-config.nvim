local M = {}

M.set_background = function(config, choices, bg)
    config.background = {
        choices[bg]
    }
end

M.user_var_override = function(overrides, name, value, choices)
    if name == 'BG_CONFIG' then
        M.set_background(overrides, choices, value)
    elseif name == 'font_size' then
        overrides.font_size = tonumber(value)
    end

    return overrides
end

return M
