local base64 = require('wezterm-config.base64_encode')
local M = {}

-- TODO: add some logic to make sure value becomes or is a string?
function M.set_wezterm_user_var(name, value)
    -- people have asked Wez about stuff like this before, to which he's linked
    -- https://wezfurlong.org/wezterm/recipes/passing-data.html
    -- his suggestions were implemented in this PR
    -- https://github.com/folke/zen-mode.nvim/pull/61
    -- which itself references reddit thread
    -- https://www.reddit.com/r/neovim/comments/xn1q75/how_to_use_chansend/
    -- unclear to me why using \033 isn't interpreted the same as \x1b
    -- there are some files in nvim that seem related to this but I don't understand them
    local stdout = vim.loop.new_tty(1, false)
    -- this uses a Lua-only dep
    local value_b64_enc = base64.encode(value)
    if os.getenv('TMUX') then
        -- also have to set this in tmux conf:
        -- set -g allow-passthrough on
        -- this assumes user has base64 tool in path
        -- stdout:write(
        --     ('\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\'):format(name, vim.fn.system({ 'base64' }, value))
        -- )
        stdout:write(
            ('\x1bPtmux;\x1b\x1b]1337;SetUserVar=%s=%s\007\x1b\\'):format(name, value_b64_enc)
        )
    else
        -- stdout:write(('\x1b]1337;SetUserVar=%s=%s\007'):format(name, vim.fn.system({ 'base64' }, value)))
        stdout:write(('\x1b]1337;SetUserVar=%s=%s\007'):format(name, value_b64_enc))
    end
    stdout:close()
end

return M
