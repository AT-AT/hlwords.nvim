package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local no_error = MiniTest.expect.no_error
local has_none_match = H.expect.has_none_match
local child = H.new_child_neovim('hlwords')

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('API.clear()', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  it('can remove all highlights', function()
    -- Arrange
    child.o.ignorecase = false
    child.prepare_words('foo', 'Foo')
    child.lua([[SUT.toggle()]])
    child.next_row()
    child.lua([[SUT.toggle()]])

    -- Act
    child.lua([[SUT.clear()]])
    local actual = child.grub_matches()

    -- Assert
    has_none_match(actual)
  end)

  it('can be executed without error even if there is no highlight', function()
    -- Arrange

    -- Assert
    no_error(function()
      -- Act
      child.lua([[SUT.clear()]])
    end)
  end)

end)
