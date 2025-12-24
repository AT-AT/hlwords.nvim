package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq = MiniTest.expect.equality
local child = H.new_child_neovim('hlwords.letters')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.letters', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('to_pattern() can apply pattern to text', function()

    describe('can apply pattern to text', function()

      it('with applying word boundary', function()
        -- Arrange
        child.o.ignorecase = false
        child.change_config([[strict_word = true]])

        -- Act
        local actual = child.lua_get([[SUT.to_pattern('foo')]])

        -- Assert
        eq('\\C\\V\\<foo\\>', actual)
      end)

      describe('with ignorecase=y, smartcase=y', function()

        before_each(function()
          child.o.ignorecase = true
          child.o.smartcase = true
        end)

        it('has lowercase only', function()
          -- Arrange

          -- Act
          local actual = child.lua_get([[SUT.to_pattern('foo')]])

          -- Assert
          eq('\\c\\Vfoo', actual)
        end)

        it('contains uppercase', function()
          -- Arrange

          -- Act
          local actual = child.lua_get([[SUT.to_pattern('Foo')]])

          -- Assert
          eq('\\C\\VFoo', actual)
        end)

      end)

      describe('with ignorecase=y, smartcase=n', function()

        before_each(function()
          child.o.ignorecase = true
          child.o.smartcase = false
        end)

        it('has lowercase only', function()
          -- Arrange

          -- Act
          local actual = child.lua_get([[SUT.to_pattern('foo')]])

          -- Assert
          eq('\\c\\Vfoo', actual)
        end)

        it('contains uppercase', function()
          -- Arrange

          -- Act
          local actual = child.lua_get([[SUT.to_pattern('Foo')]])

          -- Assert
          eq('\\c\\Vfoo', actual)
        end)

      end)

      describe('with ignorecase=n, smartcase=any', function()

        before_each(function()
          child.o.ignorecase = false
        end)

        it('has lowercase only', function()
          -- Arrange

          -- Act
          local actual = child.lua_get([[SUT.to_pattern('foo')]])

          -- Assert
          eq('\\C\\Vfoo', actual)
        end)

        it('contains uppercase', function()
          -- Arrange

          -- Act
          local actual = child.lua_get([[SUT.to_pattern('Foo')]])

          -- Assert
          eq('\\C\\VFoo', actual)
        end)

      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('retrieve()', function()

    describe('can get characters', function()

      describe('in normal mode', function()

        it('from word under cursor', function()
          -- Arrange
          child.prepare_words('foo')

          -- Act
          local actual = child.lua_get([[SUT.retrieve()]])

          -- Assert
          eq('foo', actual)
        end)

        it('as empty space if cursor is not over any word', function()
          -- Arrange
          child.prepare_words(' ')

          -- Act
          local actual = child.lua_get([[SUT.retrieve()]])

          -- Assert
          eq('', actual)
        end)

      end)

      describe('in visual mode', function()

        it('selected by operator', function()
          -- Arrange
          child.prepare_words('foo')
          child.type_keys('viw')

          -- Act
          local actual = child.lua_get([[SUT.retrieve()]])

          -- Assert
          eq('foo', actual)
        end)

        it('selected by cursor', function()
          -- Arrange
          child.prepare_words('barfoobaz')
          child.api.nvim_win_set_cursor(0, { 1, 3 })
          child.type_keys('vll')

          -- Act
          local actual = child.lua_get([[SUT.retrieve()]])

          -- Assert
          eq('foo', actual)
        end)

        it('selected by cursor in reverse order', function()
          -- Arrange
          child.prepare_words('barfoobaz')
          child.api.nvim_win_set_cursor(0, { 1, 5 })
          child.type_keys('vhh')

          -- Act
          local actual = child.lua_get([[SUT.retrieve()]])

          -- Assert
          eq('foo', actual)
        end)

        it('selected block-wise', function()
          -- Arrange
          child.prepare_words('foobar', 'bazqux')
          child.type_keys('vllj')

          -- Act
          local actual = child.lua_get([[SUT.retrieve()]])

          -- Assert
          eq('foobar\\nbaz', actual)
        end)

      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('accept()', function()

    describe('can get characters', function()

      it('from user input', function()
        MiniTest.skip('Add test when I figure out how to emulate user input via input().')
      end)

    end)

  end)

end)
