local uv = vim.uv or vim.loop
local base64 = vim.base64 or require('wezterm-config.base64_encode')

---@class WeztermConfig
local M = {}

---For testing purposes only
function M.__test_bg_override()
    local name = 'background'
    local value = {
        {
            source = {
                Color = '#16161e',
            },
            width = '100%',
            height = '100%',
            opacity = 1.0,
        },
    }
    local data = vim.json.encode(value)

    local stdout = uv.new_tty(1, false)
    if not stdout then
        return
    end

    local value_b64_enc = base64.encode(data)
    local esc_seq = [[\x1b]1337;SetUserVar=%s=%s\007]]
    if os.getenv('TMUX') then
        esc_seq = [[\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\]]
    end
    stdout:write(esc_seq:format(name, value_b64_enc))
    stdout:close()
end

---Override a Wezterm config option from within Neovim
---@param name string
---@param value string | boolean | number | table | nil
function M.set_wezterm_user_var(name, value)
    if type(name) ~= 'string' then
        error("User var's name should be a string")
    end

    local value_type = type(value)
    -- NOTE: remember that config.background is like { { source = { File = '...' } }, ... }
    -- looks like the outermost pair(s) of curly braces get converted/interpreted as array []
    -- by vim.json.encode()
    local data = vim.list_contains({ 'boolean', 'number' }, value_type) and tostring(value) or value
    local value_out = vim.json.encode(data)

    local stdout = uv.new_tty(1, false)
    if not stdout then
        return
    end

    local value_b64_enc = base64.encode(value_out)

    -- people have asked Wez about stuff like this before, to which he's linked
    -- https://wezfurlong.org/wezterm/recipes/passing-data.html
    -- his suggestions were implemented in this PR
    -- https://github.com/folke/zen-mode.nvim/pull/61 which itself references a Reddit thread
    -- https://www.reddit.com/r/neovim/comments/xn1q75/how_to_use_chansend/
    -- Folke has kindly allowed me to adapt the code here
    local esc_seq = [[\x1b]1337;SetUserVar=%s=%s\007]]
    if os.getenv('TMUX') then
        -- unclear to me why using \033 isn't interpreted the same as \x1b
        -- there are some files in nvim that seem like they could explain or have
        -- something to do with nvim-specific interpretation, but I don't understand them
        esc_seq = [[\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\]]
    end
    stdout:write(esc_seq:format(name, value_b64_enc))
    stdout:close()
end

---Setup plugin
---@param config? WeztermConfigOpts
function M.setup(config)
    ---@class WeztermConfigOpts
    local default_config = {
        append_wezterm_to_rtp = false,
    }
    M.config = vim.tbl_deep_extend('force', default_config, config or {})

    if not M.config.append_wezterm_to_rtp then
        return
    end

    -- vim.fn.stdpath('config') is typically $HOME/.config/nvim
    local wezterm_config = vim.fn.stdpath('config'):gsub('nvim', 'wezterm')
    if not vim.list_contains(vim.split(vim.o.rtp, ',', { trimempty = true, plain = true }), wezterm_config) then
        vim.o.rtp = vim.o.rtp .. (vim.o.rtp:sub(-1) == ',' and ',' or '') .. wezterm_config
    end
end

return M
