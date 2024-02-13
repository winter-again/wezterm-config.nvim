local base64 = require('wezterm-config.base64_encode')
local M = {}

---sends a Wezterm config override from within Neovim
---@param name string
---@param value string
function M.set_wezterm_user_var(name, value)
    -- TODO: is it too much to just auto convert to string and send off to Wezterm?
    if type(name) ~= 'string' then
        name = tostring(name)
    end
    if type(value) ~= 'string' then
        value = tostring(value)
    end
    -- people have asked Wez about stuff like this before, to which he's linked
    -- https://wezfurlong.org/wezterm/recipes/passing-data.html
    -- his suggestions were implemented in this PR
    -- https://github.com/folke/zen-mode.nvim/pull/61 which itself references a Reddit thread
    -- https://www.reddit.com/r/neovim/comments/xn1q75/how_to_use_chansend/
    -- Folke has kindly allowed me to adapt the code here
    local stdout = vim.loop.new_tty(1, false)
    local value_b64_enc = base64.encode(value)
    if os.getenv('TMUX') then
        -- unclear to me why using \033 isn't interpreted the same as \x1b
        -- there are some files in nvim that seem like they could explain or have
        -- something to do with nvim-specific interpretation, but I don't understand them

        -- this uses a Lua-only dep instead of requiring the user to have base64 in their path
        stdout:write(('\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\'):format(name, value_b64_enc))
    else
        stdout:write(('\x1b]1337;SetUserVar=%s=%s\007'):format(name, value_b64_enc))
    end
    stdout:close()
end

---Convenience function for getting profile data
-- function M.get_profile_data()
--     local profile_data = require(M.config.profile_data_name)
--     return profile_data
-- end

---Plugin setup function
---@param opts table
function M.setup(opts)
    -- NOTE: keeping this for future use
    -- local default_opts = {}
    -- M.config = vim.tbl_deep_extend('force', default_opts, opts or {})
    -- vim.fn.stdpath('config') is typically $HOME/.config/nvim
    local wezterm_config = vim.fn.stdpath('config'):gsub('nvim', 'wezterm')
    vim.opt.rtp:append(wezterm_config)
end

return M
