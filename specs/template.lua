package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq, ne = MiniTest.expect.equality, MiniTest.expect.no_equality
local error, no_error = MiniTest.expect.error, MiniTest.expect.no_error
local has_match, has_no_match = H.expect.has_match, H.expect.has_no_match
local has_none_match = H.expect.has_none_match
local is_null, is_visual_mode = H.expect.is_null, H.expect.is_visual_mode
local child = H.new_child_neovim('hlwords.XXXXX')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.XXXXX', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('XXXXX()', function()

    describe('-----XXXXX-----', function()

      it('-----XXXXX-----', function()
        -- Arrange

        -- Act

        -- Assert
      end)

    end)

  end)

end)
