local base64 = require('wezterm-config.base64_encode')
local M = {}

-- TODO: figure out if it's possible to use vim.json.encode()/decode() to
-- pass lua tables into this function and therefore avoid the overhead
-- of a profile_data.lua file and having to use a 'profile_' prefix.
-- I think one prob is that Wezterm side will receive the string representation
-- of the lua table via vim.json.encode(), but it wouldn't know how to convert back to
-- lua table b/c it doesn't have vim.json.decode()
-- actually it looks like wezterm has a wezterm.json_parse() func, but don't we have to
-- handle the fact that `value` is b64 encoded?

function M.__test_user_var()
    local name = 'background'
    local value = {
        {
            source = {
                Color = '#16161e',
            },
            height = '100%',
            width = '100%',
        },
    }
    -- TODO: lua table to string:
    -- why does it get square brackets around it?
    -- vim.json.decode on it looks to give correct output
    -- but it looks like when wezterm uses its wezterm.json_parse(),
    -- the square brackets are still there and looks like it's not quite a table b/c there's quotes around
    -- key names and colons instead of equals
    -- I do something like wezterm.json_parse(value)[1], but wouldn't it be better to get rid of those
    -- completely?
    -- so should we just roll out some helper func that modifies output of wezterm.json_parse()
    -- or does it make more sense to try to completely replace the role of wezterm.json_parse()?

    value = vim.json.encode(value)
    local stdout = vim.loop.new_tty(1, false)
    local value_b64_enc = base64.encode(value)
    print(value)
    print(vim.print(vim.json.decode(value))) -- string to lua table
    print(value_b64_enc)
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

---Override a Wezterm config option from within Neovim
---@param name string
---@param value string
function M.set_wezterm_user_var(name, value)
    -- TODO: add note to README about resetting a user var by passing value = '' ?
    if type(name) ~= 'string' then
        error("User var's name should be a string")
    end

    -- people have asked Wez about stuff like this before, to which he's linked
    -- https://wezfurlong.org/wezterm/recipes/passing-data.html
    -- his suggestions were implemented in this PR
    -- https://github.com/folke/zen-mode.nvim/pull/61 which itself references a Reddit thread
    -- https://www.reddit.com/r/neovim/comments/xn1q75/how_to_use_chansend/
    -- Folke has kindly allowed me to adapt the code here
    local stdout = vim.loop.new_tty(1, false)
    local value_b64_enc = base64.encode(value)
    -- TODO: does it make more sense to replace this os.getenv() call with a single flag/setting
    -- in setup config?
    if os.getenv('TMUX') then
        -- unclear to me why using \033 isn't interpreted the same as \x1b
        -- there are some files in nvim that seem like they could explain or have
        -- something to do with nvim-specific interpretation, but I don't understand them

        -- this uses a Lua-only dep instead of requiring the user to have base64 in their path
        stdout:write(('\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\'):format(name, value_b64_enc))
    else
        stdout:write(('\x1b]1337;SetUserVar=%s=%s\007'):format(name, value_b64_enc))
    end
    -- TODO: figure out if this is needed
    stdout:close()
end

---Initialize plugin
---@param config table | nil
function M.setup(config)
    -- NOTE: keeping this for future use
    -- local default_config = {}
    -- M.config = vim.tbl_deep_extend('force', default_config, config or {})

    -- vim.fn.stdpath('config') is typically $HOME/.config/nvim
    local wezterm_config = vim.fn.stdpath('config'):gsub('nvim', 'wezterm')
    vim.opt.rtp:append(wezterm_config)
end

return M
