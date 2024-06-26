local helper = require('spec.helpers')
local assert = helper.assert
local extract_hldef = helper.extract_hldef
local extract_match = helper.extract_match
local mock_config_option = helper.mock_config_option
local move_to_win = helper.move_to_win
local prepare_stage = helper.prepare_stage
local plugin_name = helper.plugin_name

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('Module.highlight', function()
  local sut_module
  local sut_store
  local sut

  local function to_record_spec(word_pattern, match_id)
    return { word_pattern = word_pattern, match_id = match_id }
  end

  local function to_record(hl_group, word_pattern, match_id)
    return { [hl_group] = to_record_spec(word_pattern, match_id) }
  end

  local function push_record_store(hl_group, word_pattern, match_id)
    if type(hl_group) == 'table' then
      local key = vim.tbl_keys(hl_group)[1]
      sut_store[key] = hl_group[key]
    else
      sut_store[hl_group] = to_record_spec(word_pattern, match_id)
    end
  end

  local function add_match(record, win_id)
    local hl_group = vim.tbl_keys(record)[1]
    local spec = record[hl_group]

    vim.fn.matchadd(hl_group, spec.word_pattern, 10, spec.match_id, { window = win_id })
  end

  setup(function()
    _G._TEST = true
  end)

  teardown(function()
    _G._TEST = nil
  end)

  before_each(function()
    helper.cleanup_modules('hlwords')
    sut_module = require('hlwords.highlight')

    sut_store = sut_module._records
    helper.event_emission(false)
    helper.mock_plugin_name()
    stub(require('hlwords.utils'), 'notice')
    mock_config_option('random', false) -- Always should be sequencial in tests.
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('define() can register highlight definition', function ()
    before_each(function ()
      sut = sut_module.define
    end)

    it('no yet registered any plugin highlight definition', function ()
      -- Arrange
      mock_config_option('colors', { { fg = 'none' } })

      -- Act
      sut()

      -- Assert
      local actual = extract_hldef()
      assert.equals(1, vim.tbl_count(actual))
    end)

    it('after deleting highlight definitions that were already registered', function ()
      -- Arrange
      mock_config_option('colors', { { fg = 'none' }, { fg = 'none' } })

      -- Act
      sut()

      -- Assert
      local actual = extract_hldef()
      assert.equals(2, vim.tbl_count(actual))

      -- Arrange
      local first = actual[1]
      mock_config_option('colors', { { fg = 'none' } })

      -- Act
      sut()

      -- Assert
      actual = extract_hldef()
      assert.equals(1, vim.tbl_count(actual))
      assert.equals(first, actual[1])
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('record() can update highlight usage in local store', function ()
    before_each(function ()
      sut = sut_module.record
    end)

    it('with fully parameters', function ()
      -- Act
      sut('foo', 'bar', 1)

      -- Assert
      assert.same(to_record('foo', 'bar', 1), sut_store)
    end)

    it('with nil parameters', function ()
      -- Act
      sut('foo', nil, nil)

      -- Assert
      assert.same(to_record('foo', nil, nil), sut_store)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('register() can register highlight to local store', function ()
    before_each(function ()
      sut = sut_module.register
    end)

    it('with initial state', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)

      -- Act
      sut('foo')

      -- Assert
      assert.same(to_record('foo', nil, nil), sut_store)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('revert() can revert highlight state in local store', function ()
    before_each(function ()
      sut = sut_module.revert
    end)

    it('to initial state', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)

      -- Act
      sut('foo')

      -- Assert
      assert.same(to_record('foo', nil, nil), sut_store)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('is_used_for() can determine that highlight', function ()
    before_each(function ()
      sut = sut_module.is_used_for
    end)

    it('is used', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)
      push_record_store('baz', nil, nil)

      -- Act
      local actual = sut('bar')

      -- Assert
      assert.is_true(actual)
    end)

    it('is not used', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)
      push_record_store('baz', nil, nil)

      -- Act
      local actual = sut('qux')

      -- Assert
      assert.is_false(actual)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('match_ids()', function ()
    before_each(function ()
      sut = sut_module.match_ids
    end)

    it('can extract id where highlight is currently used', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)
      push_record_store('baz', 'qux', 2)
      push_record_store('any', nil, nil)

      -- Act
      local actual = sut()

      -- Assert
      table.sort(actual)
      assert.same({ 1, 2 }, actual)
    end)

    it('can return empty table if no highlight is used', function ()
      -- Arrange
      push_record_store('foo', nil, nil)

      -- Act
      local actual = sut()

      -- Assert
      assert.same({}, actual)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('pick()', function ()
    before_each(function ()
      sut = sut_module.pick
    end)

    it('can extract first registered highlight group that is not used', function ()
      -- Arrange
      push_record_store('foo2', 'bar', 1)
      push_record_store('foo3', nil, nil)
      push_record_store('foo1', nil, nil)

      -- Act
      local actual = sut()

      -- Assert
      assert.equals('foo1', actual)
    end)

    it('can return nil if there is no available highlight', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)

      -- Act
      local actual = sut()

      -- Assert
      assert.equals(nil, actual)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('record_of()', function ()
    before_each(function ()
      sut = sut_module.record_of
    end)

    it('can extract highlight group that is matched to passed word-pattern', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)

      -- Act
      local actual = sut('bar')

      -- Assert

      assert.same(to_record('foo', 'bar', 1), actual)
    end)

    it('can return nil if there is no highlight that is matched to passed word-pattern', function ()
      -- Arrange
      push_record_store('foo', 'bar', 1)

      -- Act
      local actual = sut('qux')

      -- Assert
      assert.equals(nil, actual)
    end)
  end) -- Function

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('apply() can add matches', function ()
    before_each(function ()
      sut = sut_module.apply
    end)

    it('to new window', function ()
      -- Arrange
      local hl_group_1 = plugin_name .. '1'
      local hl_group_2 = plugin_name .. '2'
      local _, _, _, win_id = prepare_stage()
      local unused_record = to_record(hl_group_1, 'foo', 2000)
      local used_record = to_record(hl_group_2, nil, nil)
      push_record_store(unused_record)
      push_record_store(used_record)
      move_to_win(win_id)

      -- Assert
      local matches = vim.fn.getmatches()
      assert.any_match_not(matches)

      -- Act
      sut(win_id)

      -- Assert
      matches = vim.fn.getmatches()
      assert.only_match(matches, 'foo')
    end)

    it('to any window which already has matches without errors.', function ()
      -- Arrange
      local hl_group_1 = plugin_name .. '1'
      local _, _, _, win_id = prepare_stage()
      local unused_record = to_record(hl_group_1, 'foo', 2000)
      push_record_store(unused_record)
      add_match(unused_record, win_id)
      move_to_win(win_id)

      -- Assert
      local matches = vim.fn.getmatches()
      assert.has_match(matches, 'foo')

      -- Act
      sut(win_id)

      -- Assert
      matches = vim.fn.getmatches()
      assert.has_match(matches, 'foo')
    end)
  end)

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('off() can clear matches and highlight usage', function ()
    before_each(function ()
      sut = sut_module.off
    end)

    it('for specified record with passed word pattern', function ()
      -- Arrange
      local hl_group_1 = plugin_name .. '1'
      local hl_group_2 = plugin_name .. '2'
      local _, _, win_id_1, win_id_2 = prepare_stage()
      local target_record = to_record(hl_group_1, 'foo', 2000)
      local remained_record = to_record(hl_group_2, 'bar', 2001)
      local cleared_record = to_record(hl_group_1, nil, nil)
      local expected_store = vim.tbl_deep_extend('force', cleared_record, remained_record)
      push_record_store(target_record)
      push_record_store(remained_record)
      add_match(target_record, win_id_1)
      add_match(target_record, win_id_2)
      add_match(remained_record, win_id_1)
      add_match(remained_record, win_id_2)

      -- Act
      sut('foo')

      -- Assert
      assert.same(expected_store, sut_store)

      for _, win_id in pairs({ win_id_1, win_id_2 }) do
        move_to_win(win_id)
        local matches = vim.fn.getmatches()
        assert.has_match_not(matches, 'foo')
        assert.has_match(matches, 'bar')
      end
    end)

    it('everything if no word pattern is passed', function ()
      -- Arrange
      local hl_group_1 = plugin_name .. '1'
      local hl_group_2 = plugin_name .. '2'
      local _, _, win_id_1, win_id_2 = prepare_stage()
      local record_1 = to_record(hl_group_1, 'foo', 2000)
      local record_2 = to_record(hl_group_2, 'bar', 2001)
      local cleared_record_1 = to_record(hl_group_1, nil, nil)
      local cleared_record_2 = to_record(hl_group_2, nil, nil)
      local expected_store = vim.tbl_deep_extend('force', cleared_record_1, cleared_record_2)
      push_record_store(record_1)
      push_record_store(record_2)
      add_match(record_1, win_id_1)
      add_match(record_1, win_id_2)
      add_match(record_2, win_id_1)
      add_match(record_2, win_id_2)

      -- Act
      sut()

      -- Assert
      assert.same(expected_store, sut_store)

      for _, win_id in pairs({ win_id_1, win_id_2 }) do
        move_to_win(win_id)
        local matches = vim.fn.getmatches()
        assert.any_match_not(matches)
      end
    end)
  end)

  -- / Function
  -- -----------------------------------------------------------------------------------------------
  describe('on()', function ()
    before_each(function ()
      sut = sut_module.on
    end)

    it('can add match and record highlight usage for passed word pattern', function ()
      -- Arrange
      local hl_group = plugin_name .. '1'
      local _, _, win_id_1, win_id_2 = prepare_stage()
      local initial_record = to_record(hl_group, nil, nil)
      push_record_store(initial_record)

      -- Act
      sut('foo')

      -- Assert
      local match_id = extract_match(vim.fn.getmatches(), 'foo')[1].id
      local expected_store = to_record(hl_group, 'foo', match_id)
      assert.same(expected_store, sut_store)

      for _, win_id in pairs({ win_id_1, win_id_2 }) do
        move_to_win(win_id)
        local matches = vim.fn.getmatches()
        assert.has_match(matches, 'foo')
      end
    end)

    it('can not apply hightlight if highlight color is not in stock', function ()
      -- Arrange
      local hl_group = plugin_name .. '1'
      local _, _, win_id_1, win_id_2 = prepare_stage()
      local initial_record = to_record(hl_group, 'foo', 2000)
      push_record_store(initial_record)
      add_match(initial_record, win_id_1)
      add_match(initial_record, win_id_2)

      -- Act
      sut('bar')

      -- Assert
      assert.same(initial_record, sut_store)

      for _, win_id in pairs({ win_id_1, win_id_2 }) do
        move_to_win(win_id)
        local matches = vim.fn.getmatches()
        assert.only_match(matches, 'foo')
      end
    end)
  end)
end)
