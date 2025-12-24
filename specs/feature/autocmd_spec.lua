package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local has_match = H.expect.has_match
local child = H.new_child_neovim('hlwords')

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('AutoCmd', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Expectation
  -- -----------------------------------------------------------------------------------------------
  describe('(after setup)', function()

    before_each(function()
      child.lua([[SUT.setup()]])
    end)

    -- / Event
    -- ---------------------------------------------------------------------------------------------
    describe('on "WinEnter" event', function()

      it('can apply highlight usage to window', function()
        -- Arrange
        child.o.ignorecase = false
        child.prepare_words('foo')
        child.lua([[SUT.toggle()]])
        local new_stage = child.append_stage()
        local new_win_id = new_stage.win

        -- Act
        child.move_to_win(new_win_id)
        local actual = child.grub_matches()

        -- Assert
        has_match({ p = '\\C\\Vfoo' }, actual)
      end)

    end)

  end)

end)
