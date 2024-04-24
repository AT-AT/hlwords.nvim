local helper = require('spec.helpers')
local assert = helper.assert

describe('Test for test:', function()
  -- The main premise is that there is no Ex command that simply changes the mode, and it is
  -- necessary to create the state by imitating the input using the feedkeys function.
  it('Is it possible to change mode?', function()
    -- Since feedkeys() is an asynchronous process, it is necessary to delay the determination of
    -- the result (add it to the queue).
    --   https://www.reddit.com/r/neovim/comments/uk3xmq/change_mode_in_lua/
    -- Currently, defer_fn() can be used for one-time processing.
    --   https://neovim.io/doc/user/lua.html#lua-loop
    --   https://neovim.io/doc/user/lua.html#vim.defer_fn()
    vim.defer_fn(function()
      assert.equals('v', vim.fn.mode())

      -- SHOULD use Lua API nvim_feedkeys() instead of the native function.
      --   https://vim-jp.org/vimdoc-ja/builtin.html#feedkeys()
      --   https://neovim.io/doc/user/api.html#nvim_feedkeys()
      -- And "special keys" NEED to be handled by nvim_replace_termcodes(). Escaping with double
      -- quotes and backslashes does NOT work.
      --   https://neovim.io/doc/user/api.html#nvim_replace_termcodes()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'm', false)
    end, 50)

    -- The "x!" option here is used to continue insert mode.
    vim.api.nvim_feedkeys('v', 'x!', true)
  end)

  it('Is it possible to make feedkeys() work correctly?', function()
    vim.defer_fn(function()
      assert.equals('foo', vim.fn.getline(1))
    end, 50)

    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes('ifoo<Esc>', true, false, true), 'm', false
    )
  end)

  it('Is it possible to make feedkeys() work correctly with any mapped key?', function()
    vim.defer_fn(function()
      assert.equals('bar', vim.fn.getline(1))
    end, 50)

    vim.keymap.set('n', '<leader>b', 'ibar<Esc>')

    -- Since "<leader>" itself is NOT "special keys", just write the key set by default.
    vim.api.nvim_feedkeys('\\b', 'm', true)
  end)

  -- When running multiple tests using feedkeys(), the order of the queues stacked by defer_fn() may
  -- change and the tests may fail. Therefore, create and use a helper that waits for execution
  -- using the wait function.
  it('Is it possible to do the same thing using your own helper?', function()
    helper.wait_for(function ()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('ifoo<Esc>', true, false, true), 'm', false
      )
    end, function ()
      assert.equals('foo', vim.fn.getline(1))
    end)
  end)
end)
