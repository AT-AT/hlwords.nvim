local helper = require('spec.helpers')
local assert = helper.assert
local prepare_words = helper.prepare_words
local wait_for = helper.wait_for

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.utils', function()
  local sut_module
  local sut

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords.utils')
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('is_acceptable_vmode() can determine whether mode is acceptable or not', function ()
    before_each(function ()
      sut = sut_module.is_acceptable_vmode
    end)

    it('changed by mode key', function ()
      wait_for(function ()
        -- Arrange
        vim.api.nvim_feedkeys('v', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals(true, actual)
      end)
    end)

    it('changed by operator', function ()
      wait_for(function ()
        -- Arrange
        prepare_words('foo')
        vim.api.nvim_feedkeys('viw', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals(true, actual)
      end)
    end)

    it('changed by mode key and changed to v-block mode ', function ()
      wait_for(function ()
        -- Arrange
        prepare_words('foo')
        vim.api.nvim_feedkeys('vll', 'x!', true)
      end, function ()
        -- Assert
        assert.equals('v', vim.fn.mode())

        -- Act
        local actual = sut()

        -- Assert
        assert.equals(true, actual)
      end)
    end)
  end) -- Function
end)
