local helper = require('spec.helpers')
local assert = helper.assert
local prepare_words = helper.prepare_words
local extract_match = helper.extract_match

-- / Method
-- -------------------------------------------------------------------------------------------------
describe('Option:', function()
  local sut_module

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords')

    helper.set_plugin_name()
  end)

  after_each(function()
    helper.cleanup()
  end)

  describe('random = false', function ()
    it('should use highlight color in order of definition', function()
      -- Arrange
      sut_module.setup({ random = false })
      local toggle = sut_module.toggle
      prepare_words('foo', 'bar', 'baz', 'qux')
      local order = { 'foo', 'bar', 'baz', 'qux' }

      -- Act
      for row_num = 1, 4 do
        vim.fn.setcursorcharpos(row_num, 1)
        toggle()
      end

      -- Assert
      local actual = extract_match(vim.fn.getmatches())
      assert.equals(vim.tbl_count(order), vim.tbl_count(actual))

      for _, v in pairs(actual) do
        local idx = tonumber(string.sub(v.group, -1))
        local word = order[idx]
        assert.is_not.equals(nil, string.find(v.pattern, word))
      end
    end)
  end)

  describe('highlight_priority', function ()
    it('should be used in match as priority', function()
      -- Arrange
      local expected = 100
      sut_module.setup({ highlight_priority = expected })
      local toggle = sut_module.toggle
      prepare_words()

      -- Act
      toggle()

      -- Assert
      local actual = extract_match(vim.fn.getmatches())
      assert.equals(1, vim.tbl_count(actual))
      assert.equals(expected, actual[1].priority)
    end)
  end)

  describe('strict_word = true', function ()
    it('should highlight words only', function()
      -- Arrange
      vim.opt.ignorecase = false
      sut_module.setup({ strict_word = true })
      local toggle = sut_module.toggle
      prepare_words()

      -- Act
      toggle()

      -- Assert
      local actual = extract_match(vim.fn.getmatches())
      assert.equals(1, vim.tbl_count(actual))
      assert.equals('\\C\\V\\<foo\\>', actual[1].pattern)
    end)
  end)
end)
