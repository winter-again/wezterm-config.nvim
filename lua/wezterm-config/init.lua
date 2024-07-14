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
    value = vim.json.encode(value)

    -- local vim_ver_ge_v0_10 = vim.version.ge(vim.version(), { 0, 10, 0 })
    local uv
    local base64
    -- if vim_ver_ge_v0_10 == true then
    --     uv = vim.uv
    --     base64 = vim.base64
    -- else
    --     uv = vim.loop
    --     base64 = require('wezterm-config.base64_encode')
    -- end

    if vim.uv then
        uv = vim.uv
    else
        uv = vim.loop
    end

    if vim.base64 then
        base64 = vim.base64
    else
        base64 = require('wezterm-config.base64_encode')
    end
    local stdout = uv.new_tty(1, false)
    local value_b64_enc = base64.encode(value)

    local esc_seq
    if os.getenv('TMUX') then
        esc_seq = '\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\'
    else
        esc_seq = '\x1b]1337;SetUserVar=%s=%s\007'
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
    local value_tbl
    if value_type == 'boolean' or value_type == 'number' then
        value = tostring(value)
        value_tbl = vim.json.encode({
            value = value,
        })
    elseif value_type == 'table' then
        -- NOTE: remember that config.background is like { { source = { File = '...' } }, ... }
        -- looks like the outermost pair(s) of curly braces get converted/interpreted as array []
        -- by vim.json.encode()
        -- actually it seems to work without the gsub...
        value_tbl = vim.json.encode({ value = value })
        -- value = string.gsub(value, '[%[%]]', '')
    end

    P(value_tbl)

    -- NOTE: v0.10 adds vim.version.ge() and vim.version.le() so shouldn't use it yet since v0.10 isn't out
    -- NOTE: v0.10 renames vim.loop to vim.uv and vim.base64 module is added
    -- https://neovim.io/doc/user/news.html
    -- local vim_ver_ge_v0_10 = vim.version.ge(vim.version(), { 0, 10, 0 })
    local uv
    local base64
    -- if vim_ver_ge_v0_10 == true then
    --     uv = vim.uv
    --     base64 = vim.base64
    -- else
    --     uv = vim.loop
    --     base64 = require('wezterm-config.base64_encode')
    -- end

    -- if vim.uv then
    --     uv = vim.uv
    -- else
    --     uv = vim.loop
    -- end
    --
    -- if vim.base64 then
    --     base64 = vim.base64
    -- else
    --     base64 = require('wezterm-config.base64_encode')
    -- end

    if vim.version().minor >= 10 then
        uv = vim.uv
        base64 = vim.base64
    else
        uv = vim.loop
        base64 = require('wezterm-config.base64_encode')
    end

    local stdout = uv.new_tty(1, false)
    local value_b64_enc = base64.encode(value_tbl)

    -- people have asked Wez about stuff like this before, to which he's linked
    -- https://wezfurlong.org/wezterm/recipes/passing-data.html
    -- his suggestions were implemented in this PR
    -- https://github.com/folke/zen-mode.nvim/pull/61 which itself references a Reddit thread
    -- https://www.reddit.com/r/neovim/comments/xn1q75/how_to_use_chansend/
    -- Folke has kindly allowed me to adapt the code here
    local esc_seq
    if os.getenv('TMUX') then
        -- unclear to me why using \033 isn't interpreted the same as \x1b
        -- there are some files in nvim that seem like they could explain or have
        -- something to do with nvim-specific interpretation, but I don't understand them
        esc_seq = '\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\'
    else
        esc_seq = '\x1b]1337;SetUserVar=%s=%s\007'
    end
    stdout:write(esc_seq:format(name, value_b64_enc))
    stdout:close()
end

---Setup plugin
---@param config table | nil
function M.setup(config)
    local default_config = {
        append_wezterm_to_rtp = false,
    }
    M.config = vim.tbl_deep_extend('force', default_config, config or {})

    if M.config.append_wezterm_to_rtp == true then
        -- vim.fn.stdpath('config') is typically $HOME/.config/nvim
        local wezterm_config = vim.fn.stdpath('config'):gsub('nvim', 'wezterm')
        vim.opt.rtp:append(wezterm_config)
    end
end

return M
