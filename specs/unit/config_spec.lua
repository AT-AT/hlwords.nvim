package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq = MiniTest.expect.equality
local child = H.new_child_neovim('hlwords.config')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.config', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('options key', function()

    it('has option values generated from default values', function()
      -- Arrange
      local expected = child.lua_get('SUT.default_options')

      -- Act
      local actual = child.lua_get('SUT.options')

      -- Assert
      eq(expected, actual)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('merge_options()', function()

    it('can merge passed option values with default values', function()
      -- Arrange

      -- Act
      child.lua([[
        SUT.merge_options({ highlight_priority = 999, colors = { { fg = 'none' } } })
      ]])
      local actual = child.lua_get('SUT.options')

      -- Assert
      eq(999, actual.highlight_priority)
      eq({ { fg = 'none' } }, actual.colors)
    end)

  end)

end)
