local assert = require('luassert')
local helper = require('vusted.helper')
local say = require('say')

local M = {}

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

-- / Utility (Arrangement)
-- -------------------------------------------------------------------------------------------------

function M.extract_match(bag, pattern)
  local group = 'Hlwords'

  return vim.tbl_filter(function(item)
    if pattern then
      return vim.startswith(item.group, group) and item.pattern == pattern
    else
      return vim.startswith(item.group, group)
    end
  end, bag)
end

function M.prepare_words(...)
  local words = { ... }

  if vim.tbl_count(words) == 0 then
    words = { 'foo', 'Foo' }
  end

  for row_num, word in ipairs(words) do
    vim.fn.setline(row_num, word)
  end
end

function M.on_lc_word()
  vim.fn.setcursorcharpos(1, 1)
end

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
