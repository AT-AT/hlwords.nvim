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

-- / Utility (Arrangement)
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

-- NOTE: Implicitly refer to current buffer.
function M.prepare_words(...)
  local words = { ... }

  if vim.tbl_count(words) == 0 then
    words = { 'foo', 'Foo' }
  end

  for row_num, word in ipairs(words) do
    vim.fn.setline(row_num, word)
  end
end

-- NOTE: Implicitly refer to current buffer.
function M.on_lc_word()
  vim.fn.setcursorcharpos(1, 1)
end

-- NOTE: Implicitly refer to current buffer.
function M.on_uc_word()
  vim.fn.setcursorcharpos(2, 1)
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
