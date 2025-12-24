package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq, ne = MiniTest.expect.equality, MiniTest.expect.no_equality
local has_match, has_no_match = H.expect.has_match, H.expect.has_no_match
local has_none_match, is_null = H.expect.has_none_match, H.expect.is_null
local child = H.new_child_neovim('hlwords.highlight')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.highlight', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Helper
  -- -----------------------------------------------------------------------------------------------

  local function grub_records()
    return child.lua_get([[SUT.grub_records()]])
  end

  local function set_record(hl_group, word_pattern)
    if word_pattern then
      child.lua(string.format("SUT.record('%s', '%s')", hl_group, word_pattern))
    else
      child.lua(string.format("SUT.record('%s', nil)", hl_group))
    end
  end

  local function to_record(hl_group, word_pattern)
    return { hl_group = hl_group, word_pattern = word_pattern }
  end

  local function extract_hldef()
    local hl_prefix = child.config_of('plugin_name')
    local hl_groups = vim.tbl_keys(child.api.nvim_get_hl(0, {}))
    local extracted = vim.tbl_filter(function(hl_group)
      return vim.startswith(hl_group, hl_prefix)
    end, hl_groups)
    table.sort(extracted)

    return extracted
  end

  local function add_match(record, win_id)
    local match_id = record.match_id or -1
    return child.fn.matchadd(
      record.hl_group, record.word_pattern, 10, match_id, { window = win_id or 0 }
    )
  end

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('record()', function()

    describe('can update highlight usage in local store', function()

      it('with fully parameters', function()
        -- Arrange

        -- Act
        child.lua([[SUT.record('foo', 'bar')]])
        local actual = grub_records()

        -- Assert
        eq({ to_record('foo', 'bar') }, actual)
      end)

      it('with nil parameters', function()
        -- Arrange

        -- Act
        child.lua([[SUT.record('foo', nil)]])
        local actual = grub_records()

        -- Assert
        eq({ to_record('foo', nil) }, actual)
      end)

      it('by overwriting without duplicates', function()
        -- Arrange

        -- Act
        child.lua([[SUT.record('foo', 'bar')]])
        child.lua([[SUT.record('foo', 'baz')]])
        local actual = grub_records()

        -- Assert
        eq(1, vim.tbl_count(actual))
        eq({ to_record('foo', 'baz') }, actual)
      end)

    end)

  end)

  -- After the verification of the record() method is completed (from this point onwards), values
  -- added by the record() method itself, preventing the addition of test methods, logic, etc. to
  -- the implementation side.

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('register()', function()

    describe('can register highlight to local store', function()

      it('with initial state', function()
        -- Arrange

        -- Act
        child.lua([[SUT.register('foo')]])
        local actual = grub_records()

        -- Assert
        eq({ to_record('foo', nil) }, actual)
      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('revert()', function()

    describe('can revert highlight usage in local store', function()

      it('to initial state', function()
        -- Arrange
        set_record('foo', 'bar')

        -- Act
        child.lua([[SUT.revert('foo')]])
        local actual = grub_records()

        -- Assert
        eq({ to_record('foo', nil) }, actual)
      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('is_used_for()', function()

    describe('can determine that highlight', function()

      it('is used', function()
        -- Arrange
        set_record('foo', 'bar')
        set_record('baz', nil)

        -- Act
        local actual = child.lua_get([[SUT.is_used_for('bar')]])

        -- Assert
        eq(true, actual)
      end)

      it('is not used', function()
        -- Arrange
        set_record('foo', 'bar')
        set_record('baz', nil)

        -- Act
        local actual = child.lua_get([[SUT.is_used_for('any')]])

        -- Assert
        eq(false, actual)
      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('pick()', function()

    it('can pick unused highlight in order of earliest registration', function()
      -- Arrange
      child.change_config([[random = false]])
      set_record('foo', 'bar')
      set_record('baz', nil)
      set_record('qux', nil)

      -- Act
      local actual = child.lua_get([[SUT.pick()]])

      -- Assert
      eq('baz', actual)
    end)

    it('can return nil if there is no available highlight', function()
      -- Arrange
      child.change_config([[random = false]])
      set_record('foo', 'bar')

      -- Act
      local actual = child.lua_get([[SUT.pick()]])

      -- Assert
      is_null(actual)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('record_of()', function()

    it('can extract highlight that is matched to passed word-pattern', function()
      -- Arrange
      set_record('foo', 'bar')

      -- Act
      local actual = child.lua_get([[SUT.record_of('bar')]])

      -- Assert
      eq({ to_record('foo', 'bar') }, actual)
    end)

    it('can return empty table if there is no highlight that is matched to word-pattern', function()
      -- Arrange
      set_record('foo', 'bar')

      -- Act
      local actual = child.lua_get([[SUT.record_of('any')]])

      -- Assert
      eq({}, actual)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('define()', function()

    describe('can register highlight', function()

      it('without any registration yet', function()
        -- Arrange
        child.change_config([[colors = { { fg = 'none' } }]])

        -- Act
        child.lua([[SUT.define()]])
        local actual = extract_hldef()

        -- Assert
        eq(1, vim.tbl_count(actual))
      end)

      it('after deleting one that were already registered', function()
        -- Arrange
        child.change_config([[colors = { { fg = 'none' }, { fg = 'none' } }]])
        child.lua([[SUT.define()]])
        local expected_first_hl_group = extract_hldef()[1]
        child.change_config([[colors = { { fg = 'none' } }]])

        -- Act
        child.lua([[SUT.define()]])
        local actual = extract_hldef()

        -- Assert
        eq(1, vim.tbl_count(actual))
        eq(expected_first_hl_group, actual[1])
      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('fix_match_id()', function()

    describe('can determine unused match-id', function()

      it('with no desired starting number specified in minimal environment', function()
        -- Arrange
        local stage = child.append_stage()
        local win_id = stage.win

        -- Act
        local actual = child.lua_get(string.format(
          'SUT.fix_match_id(%d)', win_id
        ))

        -- Assert
        eq(1000, actual)
      end)

      it('with desired starting number specified in minimal environment', function()
        -- Arrange
        local stage = child.append_stage()
        local win_id = stage.win

        -- Act
        local actual = child.lua_get(string.format(
          'SUT.fix_match_id(%d, 1100)', win_id
        ))

        -- Assert
        eq(1100, actual)
      end)

      it('even if another id already exists', function()
        -- Arrange
        local stage = child.append_stage()
        local win_id = stage.win
        local used_id = add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win_id)

        -- Act
        local actual = child.lua_get(string.format(
          'SUT.fix_match_id(%d)', win_id
        ))

        -- Assert
        eq(true, actual >= 1000)
        ne(used_id, actual)
      end)

    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('apply()', function()

    describe('can update matches with current highlight usage with', function()

      it('new window', function()
        -- Arrange
        set_record('Foo', 'foo')
        set_record('Bar', nil)

        -- Act
        child.lua([[SUT.apply(0)]])
        local actual = child.grub_matches()

        -- Assert
        has_match({ g = 'Foo' }, actual)
        has_no_match({ g = 'Bar' }, actual)
      end)

      it('existing window that already has matches before update', function()
        -- Arrange
        set_record('Foo', 'foo')
        set_record('Bar', 'bar')
        set_record('Baz', nil)
        add_match({ hl_group = 'Foo', word_pattern = 'foo' })
        add_match({ hl_group = 'Bar', word_pattern = 'bar-pre' })
        add_match({ hl_group = 'Baz', word_pattern = 'baz' })

        -- Act
        child.lua([[SUT.apply(0)]])
        local actual = child.grub_matches()

        -- Assert
        has_match({ g = 'Foo' }, actual)
        has_match({ g = 'Bar', p = 'bar' }, actual)
        has_no_match({ g = 'Baz' }, actual)
      end)

    end)

    it('can add match with priority specified in the options', function ()
      -- Arrange
      child.change_config('highlight_priority = 999')
      set_record('Foo', 'foo')

      -- Act
      child.lua([[SUT.apply(0)]])
      local actual = child.grub_matches()

      -- Assert
      has_match({ g = 'Foo', p = 'foo', pr = 999 }, actual)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('on()', function()

    it('can update highlight usage with word-pattern and apply it across all windows', function()
      -- Arrange
      local stage1 = child.append_stage()
      local win1_id = stage1.win
      local stage2 = child.append_stage()
      local win2_id = stage2.win
      set_record('Foo', nil)

      -- Act
      child.lua([[SUT.on('foo')]])
      local actual_records = grub_records()
      local actual_win1 = child.grub_matches(win1_id)
      local actual_win2 = child.grub_matches(win2_id)

      -- Assert
      eq({ to_record('Foo', 'foo') }, actual_records)
      has_match({ g = 'Foo' }, actual_win1)
      has_match({ g = 'Foo' }, actual_win2)
    end)

    it('cannot update and apply if highlight is not in stock', function()
      -- Arrange
      local stage1 = child.append_stage()
      local win1_id = stage1.win
      local stage2 = child.append_stage()
      local win2_id = stage2.win
      set_record('Foo', 'foo')
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win1_id)
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win2_id)

      -- Act
      child.lua([[SUT.on('bar')]])
      local actual_records = grub_records()
      local actual_win1 = child.grub_matches(win1_id)
      local actual_win2 = child.grub_matches(win2_id)

      -- Assert
      eq({ to_record('Foo', 'foo') }, actual_records)
      has_match({ g = 'Foo', p = 'foo' }, actual_win1)
      has_no_match({ g = 'Foo', p = 'bar' }, actual_win1)
      has_match({ g = 'Foo', p = 'foo' }, actual_win2)
      has_no_match({ g = 'Foo', p = 'bar' }, actual_win2)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('off()', function()

    it('can clear highlight usage for specified one and apply it across all windows', function()
      -- Arrange
      local stage1 = child.append_stage()
      local win1_id = stage1.win
      local stage2 = child.append_stage()
      local win2_id = stage2.win
      set_record('Foo', 'foo')
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win1_id)
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win2_id)

      -- Act
      child.lua([[SUT.off('foo')]])
      local actual_records = grub_records()
      local actual_win1 = child.grub_matches(win1_id)
      local actual_win2 = child.grub_matches(win2_id)

      -- Assert
      eq({ to_record('Foo', nil) }, actual_records)
      has_none_match(actual_win1)
      has_none_match(actual_win2)
    end)

    it('can clear all highlight usage and apply it across all windows', function()
      -- Arrange
      local stage1 = child.append_stage()
      local win1_id = stage1.win
      local stage2 = child.append_stage()
      local win2_id = stage2.win
      set_record('Foo', 'foo')
      set_record('Bar', 'bar')
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win1_id)
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win2_id)
      add_match({ hl_group = 'Bar', word_pattern = 'bar' }, win1_id)
      add_match({ hl_group = 'Bar', word_pattern = 'bar' }, win2_id)

      -- Act
      child.lua([[SUT.off()]])
      local actual_records = grub_records()
      local actual_win1 = child.grub_matches(win1_id)
      local actual_win2 = child.grub_matches(win2_id)

      -- Assert
      eq({ to_record('Foo', nil), to_record('Bar', nil) }, actual_records)
      has_none_match(actual_win1)
      has_none_match(actual_win2)
    end)

    it('do nothing if passed pattern does not exist', function()
      -- Arrange
      local stage1 = child.append_stage()
      local win1_id = stage1.win
      local stage2 = child.append_stage()
      local win2_id = stage2.win
      set_record('Foo', 'foo')
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win1_id)
      add_match({ hl_group = 'Foo', word_pattern = 'foo' }, win2_id)

      -- Act
      child.lua([[SUT.off('any')]])
      local actual_records = grub_records()
      local actual_win1 = child.grub_matches(win1_id)
      local actual_win2 = child.grub_matches(win2_id)

      -- Assert
      eq({ to_record('Foo', 'foo') }, actual_records)
      has_match({ g = 'Foo' }, actual_win1)
      has_match({ g = 'Foo' }, actual_win2)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('propagate()', function()

    it('can apply highlight usage across all window', function()
      MiniTest.skip('This function is covered by other test cases.')
    end)

  end)

end)
