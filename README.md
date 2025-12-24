# Hlwords.nvim

Highlight multiple different words at the same time. That's all.

![Highlighting Sample](sample.png)

> I really loved [vim-quickhl](https://github.com/t9md/vim-quickhl).  

## Acknowledgements

Wrote this plugin in Lua with **a lot of** hints from [interestingwords.nvim](https://github.com/Mr-LLLLL/interestingwords.nvim).  
Thanks.

## Features

- Toggle highlighting of the word under the cursor.
- Toggle current selection highlighting.
- Toggle highlighting of the word from input.
- Remove all highlights by this plugin.

## Requirements

- Neovim >= 0.11
  - Because it is developed with this version. Since it is simple, I think it will work even in lower versions.
  - Please note that version 0.10 or higher is required to run the tests.

## Installation

Install the plugin with your preferred package manager. Here is an example in [lazy.nvim](https://github.com/folke/lazy.nvim).  
```lua
{
  'AT-AT/hlwords.nvim',
  config = function()
    require('hlwords').setup({
      -- options...
    })
  end,
}
```

## Configuration

Below are the configurable options and their default values.
```lua
{
  -- Highlight colors.
  -- We only provide primitive highlight colors, so change them to match your colorscheme.
  -- You can set any number of color definition maps that are compatible with nvim_set_hl(),
  -- and can highlight as many items as you set here at the same time.
  -- See: https://neovim.io/doc/user/api.html#nvim_set_hl()
  colors = {
    { fg = '#000000', bg = '#00ffff' },
    { fg = '#ffffff', bg = '#ff00ff' },
    { fg = '#000000', bg = '#ffff00' },
    { fg = '#ffffff', bg = '#444444' },
  },

  -- Priority order when highlights overlap.
  -- See: https://neovim.io/doc/user/builtin.html#matchadd()
  highlight_priority = 10,

  -- Order of use of highlight colors.
  -- If false, they will be used in the order specified in the "colors" option.
  random = true,

  -- Handling of words specified in normal mode.
  -- When highlighting is executed in normal mode, a pattern including word boundaries
  -- ('\\<' .. word .. '\\>') is used in interestingwords.nvim, but not in vim-quickhl.
  -- If set to false, the match pattern will no longer represent exact words, so the
  -- behavior will be similar to vim-quickhl.
  strict_word = false,
}
```

Note that the behavior of this plugin is affected by the settings of the `ignorecase`  and `smartcase` options.  
See [the documentation](doc/hlwords-nvim.txt) for details.

## Key Mappings

This plugin does not provide a default keymap. Below is an example.
```lua
-- Toggles highlighting of the word (<word>) under the cursor.
vim.keymap.set('n', '<leader>hh', function() require('hlwords').toggle() end)

-- Toggle highlighting current selection.
-- Note that "V-LINE" mode is not applicable, and it's possible to select a range
-- spanning multiple lines in "V-BLOCK" mode but it doesn't make much sense.
vim.keymap.set('x', '<leader>hh', function() require('hlwords').toggle() end)

-- Toggle highlighting of the word from input.
vim.keymap.set('n', '<leader>hw', function() require('hlwords').accept() end)

-- Remove all highlights.
vim.keymap.set('n', '<leader>hc', function() require('hlwords').clear() end)
```

If you are using Lazy.nvim, you can perform lazy loading at the same time by registering with the "keys" option.
```lua
{
  keys = {
    {
      '<leader>hh',
      function()
        require('hlwords').toggle()
      end,
      mode = { 'n', 'x' },
    },
    {
      '<leader>hw',
      function()
        require('hlwords').accept()
      end,
    },
    {
      '<leader>hc',
      function()
        require('hlwords').clear()
      end,
    },
  },
}
```

## Related Plugins

- [interestingwords.nvim](https://github.com/Mr-LLLLL/interestingwords.nvim)
- [high-str.nvim](https://github.com/pocco81/high-str.nvim)
- [hi-my-words.nvim](https://github.com/dvoytik/hi-my-words.nvim)

## License

[MIT](LICENSE)

