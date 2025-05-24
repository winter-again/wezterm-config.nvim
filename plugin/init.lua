-- TODO:
-- simple workaround to avoid nvim trying to load this module
-- https://github.com/wez/wezterm/issues/4533#issuecomment-1874094722
-- is there a better alt?
if vim ~= nil then
	return
end

local wezterm = require("wezterm")
local M = {}

local function trim_quotes(s)
	return (s or ""):gsub("^['\"](.-)['\"]$", "%1")
end

---@param var string
---@return boolean
local function is_shell_integ_user_var(var)
	local shell_integ_user_vars = {
		WEZTERM_PROG = true,
		WEZTERM_USER = true,
		WEZTERM_HOST = true,
		WEZTERM_IN_TMUX = true,
	}
	return shell_integ_user_vars[var] == true
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
    if not is_shell_integ_user_var(name) then
        -- returns tbl if successfully parsed
        -- otherwise it returns 1 (?) so I guess an error code or at least
        -- something with type == 'number'
        local parsed_val = wezterm.json_parse(value)
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
    return overrides
    
	if name == "font" then
		local cleaned = trim_quotes(value)
		local success, font_obj = pcall(wezterm.font, cleaned)
		if success and font_obj then
			if font_obj.font and font_obj.font[1] and font_obj.font[1].family then
				font_obj.font[1].family = trim_quotes(font_obj.font[1].family)
			end
			overrides.font = font_obj
			wezterm.log_info("Applied FONT override. Cleaned value:", cleaned)
		else
			wezterm.log_error("Failed to create font object from sanitized input:", cleaned)
		end
		return overrides
    end
end

return M
