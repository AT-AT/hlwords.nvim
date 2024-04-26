local helper = require('spec.helpers')
local assert = helper.assert
local prepare_words = helper.prepare_words

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.letters', function()
  local sut_module
  local sut

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords.letters')
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
  describe('retrieve() can get characters in visual mode', function ()
    before_each(function ()
      sut = sut_module.retrieve
    end)

    it('selected by operator', function ()
      helper.wait_for(function ()
        -- Arrange
        prepare_words('foo')
        vim.api.nvim_feedkeys('viw', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals('foo', actual)
      end)
    end)

    it('selected by cursor', function ()
      helper.wait_for(function ()
        -- Arrange
        prepare_words('barfoobaz')
        vim.fn.setcursorcharpos(1, 4)
        vim.api.nvim_feedkeys('vll', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals('foo', actual)
      end)
    end)

    it('selected by cursor in reverse order', function ()
      helper.wait_for(function ()
        -- Arrange
        prepare_words('barfoobaz')
        vim.fn.setcursorcharpos(1, 6)
        vim.api.nvim_feedkeys('vhh', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals('foo', actual)
      end)
    end)

    it('selected block-wise', function ()
      helper.wait_for(function ()
        -- Arrange
        prepare_words('foobar', 'bazqux')
        vim.api.nvim_feedkeys('vllj', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals('foobar\\nbaz', actual)
      end)
    end)
  end) -- Function
end)
