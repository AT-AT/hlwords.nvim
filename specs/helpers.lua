-- Should clearing the module cache before loading this module.
--   package.loaded['tests/helpers'] = nil
--   local H = require('tests/helpers')
-- The reasons are as follows:
-- - In Lua and Neovim, required modules are cached until the process terminates.
-- - Because the "execution" of each test is performed in a child process, the tested module is
--   loaded for each test case, and the latest state is reflected.
-- - On the other hand, since this module is loaded in the process executing the test, the cache is
--   used and any changes to the implementation will not be reflected unless the current Neovim is
--   terminated.

local Helpers = {}

-- / Child Process Handling
-- -------------------------------------------------------------------------------------------------

---@class MiniTest.child
---@field setup function
---@field change_config function
---@field config_of function
---@field append_stage function
---@field move_to_win function
---@field prepare_words function
---@field prev_row function
---@field next_row function
---@field grub_matches function

function Helpers.new_child_neovim(path)
  local child = MiniTest.new_child_neovim()

  function child.setup()
    child.restart({'-u', 'scripts/minimal_init.lua'})
    child.bo.readonly = false
    child.lua([[CONFIG_REF = require('hlwords.config')]])
    child.lua([[OPTION_REF = CONFIG_REF.options]])
    child.lua("SUT = require('" .. tostring(path) .. "')")
  end

  -- / Configuration Helper
  -- -----------------------------------------------------------------------------------------------

  function child.change_config(expression)
    child.lua('OPTION_REF.' .. expression)
  end

  function child.config_of(name)
    return child.lua_get('CONFIG_REF.' .. name)
  end

  -- / Staging Helper
  -- -----------------------------------------------------------------------------------------------

  -- Note:
  --  - Since win=-1, it is splited and added at the top level (initial-created-window).
  --  - The added window does not become the current window.
  function child.append_stage()
    -- Creates a new buffer.
    -- Even if any buffer is created here, the current buffer will not change.
    local buf = child.api.nvim_create_buf(true, false)

    -- Creates a new window.
    -- Since the second parameter is set to false, the current buffer is not changed.
    local win = child.api.nvim_open_win(buf, false, { split = 'right', vertical = true, win = -1 })

    return { buf = buf, win = win }
  end

  function child.move_to_win(win_id)
    child.api.nvim_set_current_win(win_id)
  end

  -- Note:
  --  - Each element of the list = each word will be on a new line.
  --  - After inserting words, the cursor is set to (1, 0) = (1st row, 1st column).
  function child.prepare_words(...)
    local words = { ... }

    if vim.tbl_count(words) == 0 then
      words = { 'foo', 'Foo' }
    end

    child.api.nvim_buf_set_lines(0, 0, 0, true, words)
    child.api.nvim_win_set_cursor(0, { 1, 0 })
  end

  function child.prev_row()
    local pos = child.api.nvim_win_get_cursor(0)
    child.api.nvim_win_set_cursor(0, { pos[1] - 1, 0 })
  end

  function child.next_row()
    local pos = child.api.nvim_win_get_cursor(0)
    child.api.nvim_win_set_cursor(0, { pos[1] + 1, 0 })
  end

  -- / Assertion Helper
  -- -----------------------------------------------------------------------------------------------
  function child.grub_matches(win_id)
    local id = win_id or 0

    return child.lua_get(string.format('vim.fn.getmatches(%d)', id))
  end


  return child
end

-- / Custom Expectation
-- -------------------------------------------------------------------------------------------------

Helpers.expect = {}

function Helpers.extract_match(matches, expected)
  local params = Helpers.extract_match_params(expected)

  return vim.tbl_filter(function(match)
    local has_group = false
    local has_pattern = false
    local has_priority = false

    if params.group then
      has_group = vim.startswith(match.group, params.group)
    end

    if params.pattern then
      has_pattern = match.pattern == params.pattern
    end

    if params.priority then
      has_priority = match.priority == params.priority
    end

    if params.group then
      if params.pattern then
        if params.priority then
          return has_group and has_pattern and has_priority
        else
          return has_group and has_pattern
        end
      else
        if params.priority then
          return has_group and has_priority
        else
          return has_group
        end
      end
    else
      if params.pattern then
        if params.priority then
          return has_pattern and has_priority
        else
          return has_pattern
        end
      else
        if params.priority then
          return has_priority
        else
          return false
        end
      end
    end
  end, matches)
end

function Helpers.extract_match_params(params)
  local group = params.g
  local pattern = params.p
  local priority = params.pr
  return { group = group, pattern = pattern, priority = priority }
end

Helpers.expect.has_match = MiniTest.new_expectation(
  'match existence determination',
  function(expected, actual)
    local extracted = Helpers.extract_match(actual, expected)

    return vim.tbl_count(extracted) == 1
  end,
  function(expected, _)
    local param = Helpers.to_string(Helpers.extract_match_params(expected))

    return string.format('The match (%s) does not exist.', param)
  end
)

Helpers.expect.has_no_match = MiniTest.new_expectation(
  'match non-existence determination',
  function(expected, actual)
    local extracted = Helpers.extract_match(actual, expected)

    return vim.tbl_count(extracted) ~= 1 -- Multiple matches are also considered a failure.
  end,
  function(expected, _)
    local param = Helpers.to_string(Helpers.extract_match_params(expected))

    return string.format('The match (%s) exists.', param)
  end
)

Helpers.expect.has_none_match = MiniTest.new_expectation(
  'match non-existence determination',
  function(actual)
    return vim.tbl_count(actual) == 0
  end,
  function(actual)
    return string.format('There is(are) %d matche(s).', vim.tbl_count(actual))
  end
)

Helpers.expect.is_null = MiniTest.new_expectation(
  'null like value determination',
  function(value)
    return value == nil or value == vim.NIL
  end,
  function()
    return 'Value is neither nil nor vim.NIL.'
  end
)

Helpers.expect.is_visual_mode = MiniTest.new_expectation(
  'visual mode determination',
  function(child)
    return child.api.nvim_get_mode().mode == 'v'
  end,
  function()
    return 'Not in visual mode.'
  end
)

-- / Inspection
-- -------------------------------------------------------------------------------------------------

function Helpers.dump(thing)
  Helpers.print('----------')
  Helpers.print(Helpers.to_string(thing))
  Helpers.print('----------')
end

function Helpers.print(thing)
  vim.notify(Helpers.to_string(thing))
end

function Helpers.to_string(thing)
  if type(thing) == 'table' then
    local joined = '{ '

    for k, v in pairs(thing) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      joined = joined .. '['.. k ..'] = ' .. Helpers.to_string(v) .. ','
    end

    return joined .. ' }'
  elseif thing == nil then
    return 'nil'
  else
    return tostring(thing)
  end
end

return Helpers
