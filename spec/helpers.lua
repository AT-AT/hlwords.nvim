local assert = require('luassert')
local helper = require('vusted.helper')
local say = require('say')

local M = {}

M.plugin_name = 'HlwordsTest'

-- / Alias
-- -------------------------------------------------------------------------------------------------

M.assert = assert -- Suppress diagnostics warnings for luassert globally imported by busted.
M.cleanup = helper.cleanup
M.cleanup_modules = helper.cleanup_loaded_modules

-- / Custom Assertion
-- -------------------------------------------------------------------------------------------------

local function has_match(_, arguments)
  if not type(arguments[1]) == 'table' or #arguments ~= 2 then
    return false
  end

  local matches = M.extract_match(arguments[1], arguments[2])

  return vim.tbl_count(matches) > 0
end

say:set('assertion.has_match.positive', "Expected %s \nto have matcher: %s")
say:set('assertion.has_match.negative', "Expected %s \nto not have matcher: %s")
assert:register(
  'assertion',
  'has_match', has_match,
  'assertion.has_match.positive', 'assertion.has_match.negative'
)

local function only_match(_, arguments)
  if not type(arguments[1]) == 'table' or #arguments ~= 2 then
    return false
  end

  local matches = M.extract_match(arguments[1])
  local specified_matches = M.extract_match(arguments[1], arguments[2])

  return vim.tbl_count(matches) == 1 and vim.tbl_count(specified_matches) == 1
end

say:set('assertion.only_match.positive', "Expected %s \nto have matcher: %s")
say:set('assertion.only_match.negative', "Expected %s \nto not have matcher: %s")
assert:register(
  'assertion',
  'only_match', only_match,
  'assertion.only_match.positive', 'assertion.only_match.negative'
)

local function any_match(_, arguments)
  if not type(arguments[1]) == 'table' then
    return false
  end

  local matches = M.extract_match(arguments[1])

  return vim.tbl_count(matches) > 0
end

say:set('assertion.any_match.positive', "Expected %s \nto have any matcher")
say:set('assertion.any_match.negative', "Expected %s \nto not have any matcher")
assert:register(
  'assertion',
  'any_match', any_match,
  'assertion.any_match.positive', 'assertion.any_match.negative'
)

-- / Utility (Environment)
-- -------------------------------------------------------------------------------------------------

function M.set_plugin_name()
  require('hlwords.config').plugin_name = M.plugin_name
  return M.plugin_name
end

function M.set_option(key, value)
  require('hlwords.config').options[key] = value
end

-- TL;DR: If you allow events emission in a test, be sure to STOP emitting events IMMEDIATELY after
--        it completes.
--  - In vusted, the "window" is updated for each test file and an event related to the window is
--    emitted, so if there is some auto command related to the window, you need to be careful about
--    that point.
--  - Since "window updates" are executed after the last test in a test file, even if you stop
--    emitting events before the first test in the next test file, problems may occur as in the
--    example below.
--      Allow emitting events in the last test of test file A.
--        -> Move to the next test file B while allowing the event to be emitted.
--        -> Updating the window causes the event to be emitted and the test environment changes.
--        -> Stop emitting events before the first test execution of test file B.
--        -> But at this point, there is already some impact (Boooom).
function M.event_emission(emit)
  vim.o.eventignore = emit and '' or 'all'
end

-- / Utility (Extraction)
-- -------------------------------------------------------------------------------------------------

-- NOTE: Explicitly pass the target (bag) because it will be used from a custom assertion.
function M.extract_match(bag, pattern)
  local hl_prefix = M.plugin_name

  return vim.tbl_filter(function(item)
    if pattern then
      return vim.startswith(item.group, hl_prefix) and item.pattern == pattern
    else
      return vim.startswith(item.group, hl_prefix)
    end
  end, bag)
end

function M.extract_hldef()
  local hl_prefix = M.plugin_name
  local hl_groups = vim.tbl_keys(vim.api.nvim_get_hl(0, {}))
  local extracted = vim.tbl_filter(function (hl_group)
    return vim.startswith(hl_group, hl_prefix)
  end, hl_groups)
  table.sort(extracted)

  return extracted
end

-- / Utility (Arrangement)
-- -------------------------------------------------------------------------------------------------

function M.prepare_stage()
  -- First, there is a buffer and a window to display it.
  local buf1 = vim.api.nvim_get_current_buf()
  local win1 = vim.api.nvim_get_current_win()

  -- If a new buffer is created here, the current buffer will not change.
  local buf2 = vim.api.nvim_create_buf(true, false)

  -- In the version at the time of creation, nvim_open_win was unable to create a normal window.
  vim.cmd('vsplit')

  -- If a new window is created here, the current window will change to the new one.
  local win2 = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_buf(win2, buf2)
  vim.api.nvim_set_current_win(win1)

  local function append()
    vim.cmd('vsplit')
    local win3 = vim.api.nvim_get_current_win()
    local buf3 = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win3, buf3)
    vim.api.nvim_set_current_win(win1)

    return buf3, win3
  end

  return buf1, buf2, win1, win2, append
end

-- NOTE: Implicitly refer to current buffer.
function M.prepare_words(...)
  local words = { ... }

  if vim.tbl_count(words) == 0 then
    words = { 'foo', 'Foo' }
  end

  vim.api.nvim_buf_set_lines(0, 0, 0, true, words)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- NOTE: Implicitly refer to current buffer.
function M.on_lc_word()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- NOTE: Implicitly refer to current buffer.
function M.on_uc_word()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
end

function M.move_to_win(win_id)
  vim.api.nvim_set_current_win(win_id)
end

-- / Utility (Runner)
-- -------------------------------------------------------------------------------------------------

function M.wait_for(kick, after)
  local done = false

  vim.defer_fn(function ()
    after()
    done = true
  end, 50)

  kick()
  vim.wait(500, function() return done end, 100)
end

-- / Utility (Inspection)
-- -------------------------------------------------------------------------------------------------

function M.print(thing)
  vim.api.nvim_echo({ { tostring(thing) .. "\n" } }, false, {})
end

function M.dump(thing)
  M.print('----------')
  M.print(M.to_string(thing))
  M.print('----------')
end

function M.to_string(thing)
  if type(thing) == 'table' then
    local joined = '{ '

    for k, v in pairs(thing) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      joined = joined .. '['.. k ..'] = ' .. M.to_string(v) .. ','
    end

    return joined .. ' }'
  elseif thing == nil then
    return 'nil'
  else
    return tostring(thing)
  end
end

return M
