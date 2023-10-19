# wezterm-config.nvim

Neovim and [Wezterm](https://github.com/wez/wezterm) feel like the perfect match. 

Use this plugin to send Wezterm config overrides from within Neovim. This repo doubles as the source of both the Neovim plugin (`lua/wezterm-config`) and the Wezterm plugin (`plugin/`). Wezterm is extremely flexible and a joy to use, but I've still had to employ some pretty hacky solutions and make very opinionated choices here to tie the Neovim and Wezterm sides together. Because of this, the plugin is still a WIP. 

Below are instructions and suggestions for setting both pieces up.

## Installation and use

### Neovim

Using [folke/lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'winter-again/wezterm-config.nvim',
    config = true
}
```

### Wezterm

Wezterm has a [built-in system for incorporating remote plugins](https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd). Place the following in your Wezterm config file to get the Wezterm side of the plugin running. This will pull down the repo into your local plugin directory for Wezterm to use. 

```lua
local wezterm = require('wezterm')
local wezterm_config_nvim = wezterm.plugin.require('https://github.com/winter-again/wezterm-config.nvim')
-- rest of your config
```

You can use the built-in functionality for upating plugins too. If you have `config.automatically_reload_config` set to true (the default), then the plugin *should* be updated on startup and/or on saving your config. Otherwise, you could also set a keymap to trigger reloading the config and update plugins.

```lua
wezterm.plugin.update_all()
```

Crucially, add this snippet so that Wezterm will know how to respond to the config overrides that the Neovim side will send. More info on `profile_data` below:

```lua
wezterm.on('user-var-changed', function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    overrides = wezterm_config_nvim.override_user_var(overrides, name, value, profile_data)
    window:set_config_overrides(overrides)
end)
```

### tmux

The plugin should play nicely with [tmux](https://github.com/tmux/tmux). Add the following to your tmux conf file, [as advised by Wez](https://wezfurlong.org/wezterm/recipes/passing-data.html#user-vars).

```
set -g allow-passthrough on
```

### Putting it all together

Simple key-value style (like `config.font_size` or `config.hide_tab_bar_if_only_one_tab`) config overrides should work out-of-the-box. Here's an example of how to override Wezterm's font size from inside of Neovim. Note how the first argument to `require('wezterm-config').set_wezterm_user_var()` exactly matches the corresponding option in [Wezterm's config struct](https://wezfurlong.org/wezterm/config/lua/config/index.html):

```lua
vim.keymap.set('n', '<leader><leader>f', ':lua require("wezterm-config").set_wezterm_user_var("font_size", "20")<CR>')
```

For the more "complex" config options, the plugin currently only supports `config.colors` and `config.background`. For these overrides to work, you need to first follow two conventions. For the sake of clarity, here's an example for overriding `config.background`:

1. Specify a collection of pre-defined "profile" data in your Wezterm config directory. For example, create `~/.config/wezterm/profile_data.lua`. Here, each element of the `background` table can be thought of as a background "profile" that you can set from Neovim:

```lua
local M = {}

local background = {
    bg_1 = {
        source = '...',
        width = '...',
        -- additional options
        -- ...
    },
    -- additional entries
    -- ...
}

M.background = background

return M
```

Then from your Wezterm config, require this file so that the "user-var-changed" callback can reference it properly:

```lua
local profile_data = require('profile_data')
-- wezterm.on('user-var-changed', ...) goes below
```

2. When using `require('wezterm-config').set_wezterm_user_var()`, prefix the name of the config option with "profile_". To target `config.background` you'd use "profile_background". Again, using the exact Wezterm config option's name is crucial. The full function call to set Wezterm's background to profile "bg_1" would look like `require('wezterm-config').set_wezterm_user_var("profile_background", "bg_1")`. 

Now, you can define a keymap to trigger this function just like in the key-value case above. 

## Tips

You might find it helpful to be able to clear your config overrides, especially if there's been a mistake in an override resulting in some internal Wezterm error or you just want to restore defaults. This is how you can setup a Wezterm keymap to do this:

```lua
wezterm.on('clear-overrides', function(window, pane)
    window:set_config_overrides({})
end)

local override_keymap = {
    key = 'X',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.EmitEvent('clear-overrides')
}

table.insert(config.keys, override_keymap)
```
