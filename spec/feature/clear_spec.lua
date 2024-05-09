local helper = require('spec.helpers')
local assert = helper.assert
local on_lc_word = helper.on_lc_word
local on_uc_word = helper.on_uc_word
local prepare_words = helper.prepare_words

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('API.clear()', function()
  local sut_module
  local sut

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords')

    helper.event_emission(false)
    helper.mock_plugin_name() -- Must do before the highlight definition in setup.
    sut_module.setup()
    sut = sut_module.clear
    prepare_words()
  end)

  after_each(function()
    helper.cleanup()
  end)

  it('can remove all highlights', function()
    -- Arrange
    vim.opt.ignorecase = false
    local toggle = sut_module.toggle
    on_lc_word()
    toggle()
    on_uc_word()
    toggle()

    -- Assert
    local actual = vim.fn.getmatches()
    assert.any_match(actual)

    -- Act
    sut()

    -- Assert
    actual = vim.fn.getmatches()
    assert.any_match_not(actual)
  end)

  it('can be executed without error even if there is no highlight', function()
    -- Act
    sut()

    -- Assert
    assert.truthy(true)
  end)
end)
