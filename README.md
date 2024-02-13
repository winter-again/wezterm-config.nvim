# wezterm-config.nvim

Neovim and [Wezterm](https://github.com/wez/wezterm) feel like the perfect match. 

Use this plugin to send Wezterm config overrides from within Neovim. This repo doubles as the source of both the Neovim plugin (`lua/wezterm-config`) and the Wezterm plugin (`plugin/`). Wezterm is extremely flexible and a joy to use, but I've still had to employ some pretty hacky solutions and make very opinionated choices here to tie the Neovim and Wezterm sides together. Because of this, the plugin is still a WIP, but I don't see most of the core functionality changing unless Wezterm changes a lot. 

Below are instructions and suggestions for setting both pieces up.

## Installation and use

### Neovim

Using [folke/lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'winter-again/wezterm-config.nvim',
    config = function()
        -- the setup function will append '$HOME/.config/wezterm' to
        -- the Neovim RTP, meaning you can directly access the profile
        -- data mentioned below from within Neovim
        require('wezterm_config').setup()
    end
}
```

### Wezterm

Wezterm has a [built-in system for incorporating remote plugins](https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd). Place the following in your Wezterm config file to get the Wezterm side of the plugin running. This will pull down the repo into your local plugin directory for Wezterm to use. 

```lua
local wezterm = require('wezterm')
local wezterm_config_nvim = wezterm.plugin.require('https://github.com/winter-again/wezterm-config.nvim')
-- rest of your config
```

Crucially, add this snippet so that Wezterm will know how to respond to the config overrides that the Neovim side will send. More info on what `profile_data` is later:

```lua
wezterm.on('user-var-changed', function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    overrides = wezterm_config_nvim.override_user_var(overrides, name, value, profile_data)
    window:set_config_overrides(overrides)
end)
```

### Putting it all together

Simple key-value style (like `config.font_size` or `config.hide_tab_bar_if_only_one_tab`) config overrides should work out-of-the-box. Here's an example of how to override Wezterm's font size from inside of Neovim. Note how the first argument to `require('wezterm-config').set_wezterm_user_var()` exactly matches the corresponding config option in [Wezterm's config struct](https://wezfurlong.org/wezterm/config/lua/config/index.html):

```lua
local wezterm_config = require('wezterm-config')
vim.keymap.set('n', '<leader><leader>f', function() wezterm_config.set_wezterm_user_var('font_size', '20'))
```

For the more "complex" config options that take Lua tables as their values, see `check_profile_opts` in `plugin/init.lua` to see what's currently supported. Since the Neovim side of the plugin is essentially limited to sending key-value data to Wezterm, we need to specify the actual data for the overrides elsewhere. For these overrides to work, you need to first follow two conventions. Here's an example for overriding `config.background`:

1. Specify a collection of pre-defined "profile" data (just a Lua module) at `~/.config/wezterm/lua/`. I use `~/.config/wezterm/lua/profile_data.lua`. In this file, each element of `M.background` is a table that you're telling Wezterm to reference when setting the background config option. You can reference Wezterm's [docs](https://wezfurlong.org/wezterm/config/lua/config/background.html) to see how each *element* of `M.background` emulates what Wezterm's `config.background` expects:

```lua
local M = {}

M.background = {
    bg_1 = {
        {
            source = '...',
            width = '...',
            -- additional options
            -- ...
        },
    },
    -- additional entries
    -- ...
}

return M
```

Then from your Wezterm config, require this file so that the "user-var-changed" callback can reference it properly:

```lua
local profile_data = require('lua.profile_data')
-- wezterm.on('user-var-changed', ...) goes below
```

2. When using `require('wezterm-config').set_wezterm_user_var()`, prefix the name of the config option with "profile_". For example, to target `config.background` you'd use "profile_background". Again, using the exact Wezterm config option's name is crucial. The full function call to set Wezterm's background to profile "bg_1" would look like `require('wezterm-config').set_wezterm_user_var("profile_background", "bg_1")`. 

Now, you can define a keymap to trigger this function just like in the key-value case above. 

## Tips

You can use the built-in functionality for upating plugins too. If you have `config.automatically_reload_config` set to true (the default), then the plugin *should* be updated on startup and/or on saving your config. Otherwise, you could also set a keymap to trigger reloading the config and update plugins.

```lua
wezterm.plugin.update_all()
```

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

### tmux

The plugin should play nicely with [tmux](https://github.com/tmux/tmux). Add the following to your tmux conf file, [as advised by Wez](https://wezfurlong.org/wezterm/recipes/passing-data.html#user-vars).

```
set -g allow-passthrough on
```
