local helper = require('spec.helpers')
local assert = helper.assert
local prepare_words = helper.prepare_words
local set_option = helper.set_option
local wait_for = helper.wait_for

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('Module.letters', function()
  local sut_module
  local sut

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords.letters')

    helper.event_emission(false)
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('to_pattern() can apply pattern to text', function ()
    before_each(function ()
      sut = sut_module.to_pattern
    end)

    it('with applying word boundary', function ()
      -- Arrange
      vim.opt.ignorecase = false
      set_option('strict_word', true)

      -- Act
      local actual = sut('foo')

      -- Assert
      assert.equals('\\C\\V\\<foo\\>', actual)
    end)

    describe('with ignorecase=y, smartcase=y', function ()
      before_each(function ()
        vim.opt.ignorecase = true
        vim.opt.smartcase = true
      end)

      it('has lowercase only', function ()
        -- Act
        local actual = sut('foo')

        -- Assert
        assert.equals('\\c\\Vfoo', actual)
      end)

      it('contains uppercase', function ()
        -- Act
        local actual = sut('Foo')

        assert.equals('\\C\\VFoo', actual)
      end)
    end)

    describe('with ignorecase=y, smartcase=n', function ()
      before_each(function ()
        vim.opt.ignorecase = true
        vim.opt.smartcase = false
      end)

      it('has lowercase only', function ()
        -- Act
        local actual = sut('foo')

        -- Assert
        assert.equals('\\c\\Vfoo', actual)
      end)

      it('contains uppercase', function ()
        -- Act
        local actual = sut('Foo')

        assert.equals('\\c\\Vfoo', actual)
      end)
    end)

    describe('with ignorecase=n, smartcase=any', function ()
      before_each(function ()
        vim.opt.ignorecase = false
      end)

      it('has lowercase only', function ()
        -- Act
        local actual = sut('foo')

        -- Assert
        assert.equals('\\C\\Vfoo', actual)
      end)

      it('contains uppercase', function ()
        -- Act
        local actual = sut('Foo')

        assert.equals('\\C\\VFoo', actual)
      end)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('retrieve() can get characters', function ()
    before_each(function ()
      sut = sut_module.retrieve
    end)

    describe('in normal mode', function ()
      it('from word under cursor', function ()
        -- Arrange
        prepare_words('foo')

        -- Act
        local actual = sut()

        -- Assert
        assert.equals('foo', actual)
      end)

      it('as empty space if cursor is not over any word', function ()
        -- Arrange
        prepare_words(' ')

        -- Act
        local actual = sut()

        -- Assert
        assert.equals('', actual)
      end)
    end)

    describe('in visual mode', function ()
      it('selected by operator', function ()
        wait_for(function ()
          -- Arrange
          prepare_words('foo')
          vim.api.nvim_feedkeys('viw', 'x!', true)
        end, function ()
          -- Assert
          assert.equals('v', vim.api.nvim_get_mode().mode)

          -- Act
          local actual = sut()

          -- Assert
          assert.equals('foo', actual)
        end)
      end)

      it('selected by cursor', function ()
        wait_for(function ()
          -- Arrange
          prepare_words('barfoobaz')
          vim.api.nvim_win_set_cursor(0, { 1, 3 })
          vim.api.nvim_feedkeys('vll', 'x!', true)
        end, function ()
          -- Assert
          assert.equals('v', vim.api.nvim_get_mode().mode)

          -- Act
          local actual = sut()

          -- Assert
          assert.equals('foo', actual)
        end)
      end)

      it('selected by cursor in reverse order', function ()
        wait_for(function ()
          -- Arrange
          prepare_words('barfoobaz')
          vim.api.nvim_win_set_cursor(0, { 1, 5 })
          vim.api.nvim_feedkeys('vhh', 'x!', true)
        end, function ()
          -- Assert
          assert.equals('v', vim.api.nvim_get_mode().mode)

          -- Act
          local actual = sut()

          -- Assert
          assert.equals('foo', actual)
        end)
      end)

      it('selected block-wise', function ()
        wait_for(function ()
          -- Arrange
          prepare_words('foobar', 'bazqux')
          vim.api.nvim_feedkeys('vllj', 'x!', true)
        end, function ()
          -- Assert
          assert.equals('v', vim.api.nvim_get_mode().mode)

          -- Act
          local actual = sut()

          -- Assert
          assert.equals('foobar\\nbaz', actual)
        end)
      end)
    end)
  end) -- Function
end)
