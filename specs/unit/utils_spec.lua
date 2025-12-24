package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq, is_visual_mode = MiniTest.expect.equality, H.expect.is_visual_mode
local child = H.new_child_neovim('hlwords.utils')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.utils', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('is_acceptable_vmode()', function()

    describe('can determine whether mode is acceptable or not', function()

      it('changed by mode key', function()
        -- Arrange
        child.type_keys('v')

        -- Act
        local actual = child.lua_get([[SUT.is_acceptable_vmode()]])

        -- Assert
        is_visual_mode(child)
        eq(true, actual)
      end)

      it('changed by operator', function()
        -- Arrange
        child.prepare_words('any')
        child.type_keys('viw')

        -- Act
        local actual = child.lua_get([[SUT.is_acceptable_vmode()]])

        -- Assert
        is_visual_mode(child)
        eq(true, actual)
      end)

      it('changed by mode key and changed to v-block mode ', function()
        -- Arrange
        child.prepare_words('any')
        child.type_keys('vll')

        -- Act
        local actual = child.lua_get([[SUT.is_acceptable_vmode()]])

        -- Assert
        is_visual_mode(child)
        eq(true, actual)
      end)

    end)

  end)

end)
