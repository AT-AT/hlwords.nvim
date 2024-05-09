local helper = require('spec.helpers')
local assert = helper.assert
local on_lc_word = helper.on_lc_word
local on_uc_word = helper.on_uc_word
local prepare_words = helper.prepare_words
local wait_for = helper.wait_for

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('API.toggle() can switch highlight', function()
  local sut_module
  local sut

  local function start_visual()
    vim.api.nvim_feedkeys('viw', 'x!', true)
  end

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords')

    helper.event_emission(false)
    helper.mock_plugin_name() -- Must do before the highlight definition in setup.
    sut_module.setup()
    sut = sut_module.toggle
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Vim Option
  -- -----------------------------------------------------------------------------------------------
  describe('with ignorecase=y, smartcase=y', function()
    before_each(function()
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
    end)

    -- / Word Type
    -- ---------------------------------------------------------------------------------------------
    describe('for lowercase word', function()
      before_each(function()
        prepare_words()
        on_lc_word()
      end)

      it('in normal mode', function()
        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vfoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)

      it('in visual mode (on)', function()
        wait_for(function ()
          -- Arrange
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.only_match(actual, '\\c\\Vfoo')
        end)
      end)

      it('in visual mode (off)', function()
        wait_for(function()
          -- Arrange
          sut()
          start_visual()
        end, function()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.any_match_not(actual)
        end)
      end)

      it('from argument', function()
        -- Act
        sut('bar')

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vbar')

        -- Act
        sut('bar')

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Word Type

    -- / Word Type
    -- ---------------------------------------------------------------------------------------------
    describe('for uppercase word', function()
      before_each(function()
        prepare_words()
        on_uc_word()
      end)

      it('in normal mode', function()
        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\VFoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)

      it('in visual mode (on)', function()
        wait_for(function ()
          -- Arrange
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.only_match(actual, '\\C\\VFoo')
        end)
      end)

      it('in visual mode (off)', function()
        wait_for(function ()
          -- Arrange
          sut()
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.any_match_not(actual)
        end)
      end)

      it('from argument', function()
        -- Act
        sut('Bar')

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\VBar')

        -- Act
        sut('Bar')

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Word Type

    -- / Multiple
    -- ---------------------------------------------------------------------------------------------
    describe('for words with different case', function()
      before_each(function()
        prepare_words()
        on_lc_word()
        sut()
        on_uc_word()
        sut()
      end)

      it('and first one remains', function()
        -- Assert
        local actual = vim.fn.getmatches()
        assert.has_match(actual, '\\c\\Vfoo')
        assert.has_match_not(actual, '\\C\\Vfoo')
        assert.has_match_not(actual, '\\c\\VFoo')
        assert.has_match(actual, '\\C\\VFoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vfoo')
      end)

      it('and last one remains', function()
        -- Arrange
        on_lc_word()

        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\VFoo')
      end)
    end) -- Multiple
  end) -- Vim Option

  -- / Vim Option
  -- -----------------------------------------------------------------------------------------------
  describe('with ignorecase=y, smartcase=n', function()
    before_each(function()
      vim.opt.ignorecase = true
      vim.opt.smartcase = false
    end)

    -- / Word Type
    -- ---------------------------------------------------------------------------------------------
    describe('for lowercase word', function()
      before_each(function()
        prepare_words()
        on_lc_word()
      end)

      it('in normal mode', function()
        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vfoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)

      it('in visual mode (on)', function()
        wait_for(function ()
          -- Arrange
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.only_match(actual, '\\c\\Vfoo')
        end)
      end)

      it('in visual mode (off)', function()
        wait_for(function()
          -- Arrange
          sut()
          start_visual()
        end, function()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.any_match_not(actual)
        end)
      end)

      it('from argument', function()
        -- Act
        sut('bar')

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vbar')

        -- Act
        sut('bar')

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Word Type

    -- / Word Type
    -- ---------------------------------------------------------------------------------------------
    describe('for uppercase word', function()
      before_each(function()
        prepare_words()
        on_uc_word()
      end)

      it('in normal mode', function()
        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vfoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)

      it('in visual mode (on)', function()
        wait_for(function ()
          -- Arrange
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.only_match(actual, '\\c\\Vfoo')
        end)
      end)

      it('in visual mode (off)', function()
        wait_for(function ()
          -- Arrange
          sut()
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.any_match_not(actual)
        end)
      end)

      it('from argument', function()
        -- Act
        sut('Bar')

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vbar')

        -- Act
        sut('Bar')

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Word Type

    -- / Multiple
    -- ---------------------------------------------------------------------------------------------
    describe('for words with different case', function()
      it('and always toggle both', function()
        -- Arrange
        prepare_words()
        on_lc_word()

        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\c\\Vfoo')

        -- Arrange
        on_uc_word()

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Multiple
  end) -- Vim Option

  -- / Vim Option
  -- -----------------------------------------------------------------------------------------------
  describe('with ignorecase=n, smartcase=any', function()
    before_each(function()
      vim.opt.ignorecase = false
    end)

    -- / Word Type
    -- ---------------------------------------------------------------------------------------------
    describe('for lowercase word', function()
      before_each(function()
        prepare_words()
        on_lc_word()
      end)

      it('in normal mode', function()
        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\Vfoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)

      it('in visual mode (on)', function()
        wait_for(function ()
          -- Arrange
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.only_match(actual, '\\C\\Vfoo')
        end)
      end)

      it('in visual mode (off)', function()
        wait_for(function()
          -- Arrange
          sut()
          start_visual()
        end, function()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.any_match_not(actual)
        end)
      end)

      it('from argument', function()
        -- Act
        sut('bar')

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\Vbar')

        -- Act
        sut('bar')

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Word Type

    -- / Word Type
    -- ---------------------------------------------------------------------------------------------
    describe('for uppercase word', function()
      before_each(function()
        prepare_words()
        on_uc_word()
      end)

      it('in normal mode', function()
        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\VFoo')

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)

      it('in visual mode (on)', function()
        wait_for(function ()
          -- Arrange
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.only_match(actual, '\\C\\VFoo')
        end)
      end)

      it('in visual mode (off)', function()
        wait_for(function ()
          -- Arrange
          sut()
          start_visual()
        end, function ()
          -- Assert
          assert.is_visual_mode()

          -- Act
          sut()

          -- Assert
          local actual = vim.fn.getmatches()
          assert.any_match_not(actual)
        end)
      end)

      it('from argument', function()
        -- Act
        sut('Bar')

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\VBar')

        -- Act
        sut('Bar')

        -- Assert
        actual = vim.fn.getmatches()
        assert.any_match_not(actual)
      end)
    end) -- Word Type

    -- / Multiple
    -- ---------------------------------------------------------------------------------------------
    describe('for words with different case', function()
      it('and always toggle one side', function()
        -- Arrange
        prepare_words()
        on_lc_word()

        -- Act
        sut()

        -- Assert
        local actual = vim.fn.getmatches()
        assert.only_match(actual, '\\C\\Vfoo')

        -- Arrange
        on_uc_word()

        -- Act
        sut()

        -- Assert
        actual = vim.fn.getmatches()
        assert.has_match_not(actual, '\\c\\Vfoo')
        assert.has_match(actual, '\\C\\Vfoo')
        assert.has_match_not(actual, '\\c\\VFoo')
        assert.has_match(actual, '\\C\\VFoo')
      end)
    end) -- Multiple
  end) -- Vim Option
end)
