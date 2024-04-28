local helper = require('spec.helpers')
local assert = helper.assert

-- TODO: Introduce reliable testing methods for asynchronous processing rather than proprietary
--       helper (wait_for()).

-- Pay attention to the following points during the entire test.
--  - I still do NOT understand the details and behavior of vim queuing and how Lua (busted) handles
--    it, so there's a lot of workaround.
--  - The main premise is that there is no Ex command that simply changes the mode, and it is
--    necessary to create the state by imitating the input using the feedkeys function.
--  - feedkeys() is an asynchronous process, it's necessary to delay the determination of the result
--    (add it to the queue).
--      https://www.reddit.com/r/neovim/comments/uk3xmq/change_mode_in_lua/
--    Usually defer_fn() can be used for that purpose.
--      https://neovim.io/doc/user/lua.html#lua-loop
--      https://neovim.io/doc/user/lua.html#vim.defer_fn()
--    Example:
--      vim.defer_fn(function()
--        assert.equals(...)
--      end, 50)
--      vim.api.nvim_feedkeys(...)
--  - However, even if defer_fn() is used, the processing of the test block (it(...)) that contains
--    defer_fn() continues, and processing of the next test starts at the end of the block.
--  - Therefore, when running multiple tests using feedkeys(), the order of the queues stacked by
--    defer_fn() may change and the tests may fail. So create and use a helper that waits for
--    execution using the wait function.
--  - Note that I tried the example using coroutine on the page below, but yield() could not be
--    executed, probably because the environment was not using plenary.nvim.
--      https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md#asynchronous-testing

describe('Test for test:', function()
  after_each(function()
    -- Buffers MUST always be cleared. Otherwise, there are situations in which after running some
    -- test using wait_for(), a test that also runs using wait_for() will fail.
    helper.cleanup()
  end)

  it('Is it possible to change mode?', function()
    helper.wait_for(function ()
      -- If the previous input keystrokes are not consumed by the x option, an error may occur in
      -- subsequent tests. Note that the "!" option here is used to continue insert mode.
      vim.api.nvim_feedkeys('v', 'x!', true)
    end, function ()
      assert.equals('v', vim.api.nvim_get_mode().mode)

      -- SHOULD use Lua API nvim_feedkeys() instead of the native function.
      --   https://vim-jp.org/vimdoc-ja/builtin.html#feedkeys()
      --   https://neovim.io/doc/user/api.html#nvim_feedkeys()
      -- And "special keys" NEED to be handled by nvim_replace_termcodes(). Escaping with double
      -- quotes and backslashes does NOT work.
      --   https://neovim.io/doc/user/api.html#nvim_replace_termcodes()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'mx', false)
    end)
  end)

  it('Is it possible to make feedkeys() work correctly?', function()
    helper.wait_for(function ()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('ifoo<Esc>', true, false, true), 'x', false
      )
    end, function ()
      assert.equals('foo', vim.api.nvim_buf_get_lines(0, 0, 1, true)[1])
    end)
  end)

  it('Is it possible to make feedkeys() work correctly with any mapped key?', function()
    vim.keymap.set('n', '<leader>b', 'ibar<Esc>')

    helper.wait_for(function ()
      -- Since "<leader>" itself is NOT "special keys", just write the default key ("\").
      vim.api.nvim_feedkeys('\\b', 'mx', true)
    end, function ()
      assert.equals('bar', vim.api.nvim_buf_get_lines(0, 0, 1, true)[1])
    end)
  end)
end)
