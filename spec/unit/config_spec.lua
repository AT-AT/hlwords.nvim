local helper = require('spec.helpers')
local assert = helper.assert

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('Module.config', function()
  local sut_module
  local sut

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords.config')
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('initial options', function ()
    before_each(function ()
      sut = sut_module.merge_options
    end)

    it('should be initialized by deep-copy with default options', function ()
      -- Assert
      local actual = sut_module.options
      assert.same(sut_module.default_options, actual)
      assert.equals_not(sut_module.default_options, actual)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('merge_options()', function ()
    before_each(function ()
      sut = sut_module.merge_options
    end)

    it('can merge local options to initial options from default', function ()
      -- Arrange
      local local_options = { highlight_priority = 999, colors = { { fg = 'none' } } }

      -- Act
      sut(local_options)

      -- Assert
      local actual = sut_module.options
      assert.equals(local_options.highlight_priority, actual.highlight_priority)
      assert.same(local_options.colors, actual.colors)
    end)
  end) -- Function
end)
