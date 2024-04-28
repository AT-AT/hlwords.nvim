local helper = require('spec.helpers')
local assert = helper.assert
local move_to_win = helper.move_to_win
local prepare_stage = helper.prepare_stage
local prepare_words = helper.prepare_words

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('AutoCmd:', function()
  local sut_module

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords')

    helper.event_emission(false)
    helper.set_plugin_name() -- Must do before the highlight definition in setup.
    sut_module.setup()
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Multiple Window
  -- -----------------------------------------------------------------------------------------------
  describe('on "WinEnter" event', function()
    local toggle

    before_each(function()
      vim.opt.ignorecase = false
      helper.event_emission(true)
      toggle = sut_module.toggle
    end)

    after_each(function ()
      helper.event_emission(false) -- See the comment in that helper function.
    end)

    it('can apply already registered matches', function()
      -- Arrange
      local _, _, win_id_1, win_id_2, append = prepare_stage()
      move_to_win(win_id_1)
      prepare_words()

      -- Act
      toggle()

      -- Assert
      move_to_win(win_id_2)
      local actual = vim.fn.getmatches()
      assert.has_match(actual, '\\C\\Vfoo')

      local _, win_id_3 = append()
      move_to_win(win_id_3)
      actual = vim.fn.getmatches()
      assert.has_match(actual, '\\C\\Vfoo')

      move_to_win(win_id_1) -- Move to window where any matches already exists.
    end)
  end)
end)
