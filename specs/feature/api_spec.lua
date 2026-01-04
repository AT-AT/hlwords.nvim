package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local no_error = MiniTest.expect.no_error
local has_match, has_no_match = H.expect.has_match, H.expect.has_no_match
local has_none_match = H.expect.has_none_match
local child = H.new_child_neovim('hlwords')

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('API', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  local function prev_row()
    local pos = child.api.nvim_win_get_cursor(0)
    child.api.nvim_win_set_cursor(0, { pos[1] - 1, 0 })
  end

  local function next_row()
    local pos = child.api.nvim_win_get_cursor(0)
    child.api.nvim_win_set_cursor(0, { pos[1] + 1, 0 })
  end

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('setup()', function()

    before_each(function()
      child.lua([[SUT.setup()]])
    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('toggle()', function()

      local function select_visually()
        child.type_keys('viw')
      end

      describe('can switch highlight', function()

        -- / Vim Option
        -- -----------------------------------------------------------------------------------------
        describe('with ignorecase=y, smartcase=y', function()

          before_each(function()
            child.o.ignorecase = true
            child.o.smartcase = true
          end)

          -- / Word Type
          -- ---------------------------------------------------------------------------------------
          describe('for lowercase word', function()

            before_each(function()
              child.prepare_words('foo')
            end)

            it('in normal mode', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('in visual mode (on)', function()
              -- Arrange
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)
            end)

            it('in visual mode (off)', function()
              -- Arrange
              child.lua([[SUT.toggle()]])
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('from argument', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle('foo')]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle('foo')]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

          -- / Word Type
          -- ---------------------------------------------------------------------------------------
          describe('for sentencecase word', function()

            before_each(function()
              child.prepare_words('Foo')
            end)

            it('in normal mode', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\VFoo' }, actual)

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('in visual mode (on)', function()
              -- Arrange
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\VFoo' }, actual)
            end)

            it('in visual mode (off)', function()
              -- Arrange
              child.lua([[SUT.toggle()]])
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('from argument', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle('Foo')]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\VFoo' }, actual)

              -- Act
              child.lua([[SUT.toggle('Foo')]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

          -- / Mixed
          -- ---------------------------------------------------------------------------------------
          describe('for words with different case', function()

            before_each(function()
              child.prepare_words('foo', 'Foo')
            end)

            it('to each their own', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              next_row()
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)
              has_no_match({ p = '\\C\\Vfoo' }, actual)
              has_no_match({ p = '\\c\\VFoo' }, actual)
              has_match({ p = '\\C\\VFoo' }, actual)
            end)

            it('and first one remains', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              next_row()
              child.lua([[SUT.toggle()]])
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)
              has_no_match({ p = '\\C\\Vfoo' }, actual)
              has_no_match({ p = '\\c\\VFoo' }, actual)
              has_no_match({ p = '\\C\\VFoo' }, actual)
            end)

            it('and first one remains', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              next_row()
              child.lua([[SUT.toggle()]])
              prev_row()
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_no_match({ p = '\\c\\Vfoo' }, actual)
              has_no_match({ p = '\\C\\Vfoo' }, actual)
              has_no_match({ p = '\\c\\VFoo' }, actual)
              has_match({ p = '\\C\\VFoo' }, actual)
            end)

          end)

        end)

        -- / Vim Option
        -- -----------------------------------------------------------------------------------------
        describe('with ignorecase=y, smartcase=n', function()

          before_each(function()
            child.o.ignorecase = true
            child.o.smartcase = false
          end)

          -- / Word Type
          -- ---------------------------------------------------------------------------------------
          describe('for lowercase word', function()

            before_each(function()
              child.prepare_words('foo')
            end)

            it('in normal mode', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('in visual mode (on)', function()
              -- Arrange
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)
            end)

            it('in visual mode (off)', function()
              -- Arrange
              child.lua([[SUT.toggle()]])
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('from argument', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle('foo')]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle('foo')]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

          -- / Word Type
          -- ---------------------------------------------------------------------------------------
          describe('for sentencecase word', function()

            before_each(function()
              child.prepare_words('Foo')
            end)

            it('in normal mode', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('in visual mode (on)', function()
              -- Arrange
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)
            end)

            it('in visual mode (off)', function()
              -- Arrange
              child.lua([[SUT.toggle()]])
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('from argument', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle('Foo')]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle('Foo')]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

          -- / Mixed
          -- ---------------------------------------------------------------------------------------
          describe('for words with different case', function()

            before_each(function()
              child.prepare_words('foo', 'Foo')
            end)

            it('and always toggle both', function()
              -- Arrange
              child.prepare_words('foo', 'Foo')

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\c\\Vfoo' }, actual)
              has_no_match({ p = '\\C\\Vfoo' }, actual)
              has_no_match({ p = '\\c\\VFoo' }, actual)
              has_no_match({ p = '\\C\\VFoo' }, actual)

              -- Arrange
              next_row()

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

        end)

        -- / Vim Option
        -- -----------------------------------------------------------------------------------------
        describe('with ignorecase=n, smartcase=any', function()

          before_each(function()
            child.o.ignorecase = false
          end)

          -- / Word Type
          -- ---------------------------------------------------------------------------------------
          describe('for lowercase word', function()

            before_each(function()
              child.prepare_words('foo')
            end)

            it('in normal mode', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('in visual mode (on)', function()
              -- Arrange
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\Vfoo' }, actual)
            end)

            it('in visual mode (off)', function()
              -- Arrange
              child.lua([[SUT.toggle()]])
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('from argument', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle('foo')]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\Vfoo' }, actual)

              -- Act
              child.lua([[SUT.toggle('foo')]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

          -- / Word Type
          -- ---------------------------------------------------------------------------------------
          describe('for sentencecase word', function()

            before_each(function()
              child.prepare_words('Foo')
            end)

            it('in normal mode', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\VFoo' }, actual)

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('in visual mode (on)', function()
              -- Arrange
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\VFoo' }, actual)
            end)

            it('in visual mode (off)', function()
              -- Arrange
              child.lua([[SUT.toggle()]])
              select_visually()

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

            it('from argument', function()
              -- Arrange

              -- Act
              child.lua([[SUT.toggle('Foo')]])
              local actual = child.grub_matches()

              -- Assert
              has_match({ p = '\\C\\VFoo' }, actual)

              -- Act
              child.lua([[SUT.toggle('Foo')]])
              actual = child.grub_matches()

              -- Assert
              has_none_match(actual)
            end)

          end)

          -- / Mixed
          -- ---------------------------------------------------------------------------------------
          describe('for words with different case', function()

            before_each(function()
              child.prepare_words('foo', 'Foo')
            end)

            it('and always toggle both', function()
              -- Arrange
              child.prepare_words('foo', 'Foo')

              -- Act
              child.lua([[SUT.toggle()]])
              local actual = child.grub_matches()

              -- Assert
              has_no_match({ p = '\\c\\Vfoo' }, actual)
              has_match({ p = '\\C\\Vfoo' }, actual)
              has_no_match({ p = '\\c\\VFoo' }, actual)
              has_no_match({ p = '\\C\\VFoo' }, actual)

              -- Arrange
              next_row()

              -- Act
              child.lua([[SUT.toggle()]])
              actual = child.grub_matches()

              -- Assert
              has_no_match({ p = '\\c\\Vfoo' }, actual)
              has_match({ p = '\\C\\Vfoo' }, actual)
              has_no_match({ p = '\\c\\VFoo' }, actual)
              has_match({ p = '\\C\\VFoo' }, actual)
            end)

          end)

        end)

      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('clear()', function()

      it('can remove all highlights', function()
        -- Arrange
        child.o.ignorecase = false
        child.prepare_words('foo', 'Foo')
        child.lua([[SUT.toggle()]])
        next_row()
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

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('accept()', function()

      describe('can get characters', function()

        it('from user input', function()
          MiniTest.skip('Add test when I figure out how to emulate user input via input().')
        end)

      end)

    end)

  end)

end)
