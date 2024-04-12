-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
local api = vim.api

---@see vim.fn
local fn = vim.fn


-- =================================================================================================
--  Namespace
-- =================================================================================================

---@type { [string]: function }
local M = {}

---@type { [string]: function }
local API = {}

---@type { [string]: function|table }
local HL = {} -- Just used to simplify the function name.


-- =================================================================================================
--  Local Variable
-- =================================================================================================

---@type string
local app_name = 'Hlwords'

---@see default_config
local config = {}

---@alias color_spec table<string, any> Options acceptable to vim.api.nvim_set_hl
---@type { colors: color_spec[], highlight_priority: integer, random: boolean }
local default_config = {
  colors = {
    { fg = '#000000', bg = '#00ffff' },
    { fg = '#ffffff', bg = '#ff00ff' },
    { fg = '#000000', bg = '#ffff00' },
    { fg = '#ffffff', bg = '#444444' },
  },
  highlight_priority = 10,
  random = true,
}


-- =================================================================================================
--  Function (Module Local)
-- =================================================================================================

-- / Notification
-- -------------------------------------------------------------------------------------------------

---@package
---@param message string
function M.fail(message)
  M.notice(vim.log.levels.ERROR, message)
end

---@package
---@param level any @see vim.log.levels
---@param message string
function M.notice(level, message)
  vim.notify(app_name .. ': ' .. message, level)
end

---@package
---@see M.fail
function M.warn(message)
  M.notice(vim.log.levels.WARN, message)
end

-- / Setup
-- -------------------------------------------------------------------------------------------------

---@package
function M.initialize_highlight()
  for index, color_table in pairs(config.colors) do
    local hl_group = app_name .. string.format('%02d', index)

    api.nvim_set_hl(0, hl_group, color_table)
    HL.register(hl_group)
  end
end

-- / Text Handler
-- -------------------------------------------------------------------------------------------------

---@package
---@param target string
---@return string
function M.apply_pattern_mode(target)
  -- With "Very Nomagic(\V)", meta characters included in the target string are treated as normal
  -- literals as much as possible.
  local pattern_mode = '\\V' .. target

  -- Case-Insensitive(\c), No-SmartCase(follow "ignorecase") or has no UpperCase-Letters(\u=[^A-Z]+)
    if vim.o.ignorecase and (not vim.o.smartcase or fn.match(target, '\\u') == -1) then
      return '\\c' .. pattern_mode
  -- Case-Sensitive(\C)
    else
      return '\\C' .. pattern_mode
    end
end

---@package
---@return string
---
--- This method only accepts "v" (Visual, includes using operators like as "viw") or "^V" (V-Block),
--- not "V" (V-Line).<br>
--- After "getregion()" is merged, refactor using it. And once it's merged and sufficient
--- functionality is implemented, "vim.region" will be deprecated and will not be used.
function M.retrieve_text()
  local start_row, start_col = fn.getpos('v')[2], fn.getpos('v')[3]
  local end_row, end_col = fn.getpos('.')[2], fn.getpos('.')[3]

  -- Normalize the position to correspond to the tail processing rules of nvim_buf_get_text() in
  -- the row/column direction.
  if end_row < start_row then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  elseif end_row == start_row and end_col < start_col then
    start_col, end_col = end_col, start_col
  end

  -- In nvim_buf_get_text(), indexing is zero-based and row indices are end-inclusive, so simply
  -- move the coordinates upward.
  start_row = start_row - 1
  end_row = end_row - 1

  -- On the other hand, column indices are end-exclusive, so move only the starting position.
  start_col = start_col - 1

  local lines = api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

  vim.cmd('normal! ')

  if vim.tbl_isempty(lines) then
    return ''
  end

  local text = table.concat(vim.tbl_map(function(line)
    return fn.escape(line, '\\')
  end, lines), '\\n')

  return text
end

-- =================================================================================================
--  Definition (Highlight Related)
-- =================================================================================================

---@alias highlight_spec { word_pattern: string, match_id: integer }
---@alias highlight_group string
---@alias highlight_record table<highlight_group, highlight_spec>

---@type highlight_record
HL.record = {}

-- / Stack Register
-- -------------------------------------------------------------------------------------------------

---@package
---@param hl_group highlight_group
---@param word_pattern string
---@param match_id integer
function HL.apply(hl_group, word_pattern, match_id)
  HL.record[hl_group] = { word_pattern = word_pattern, match_id = match_id }
end

---@package
---@param hl_group highlight_group
function HL.cancel(hl_group)
  HL.apply(hl_group, nil, nil)
end

---@package
---@param hl_group highlight_group
function HL.register(hl_group)
  HL.apply(hl_group, nil, nil)
end

-- / Stack Handler
-- -------------------------------------------------------------------------------------------------

---@package
---@param word_pattern string
---@return boolean
function HL.is_used_for(word_pattern)
  for _, spec in pairs(HL.record) do
    if spec.word_pattern == word_pattern then
      return true
    end
  end

  return false
end

---@package
---@return integer[]
function HL.match_ids()
  local ids = {}

  for _, spec in pairs(HL.record) do
    if spec.match_id ~= nil then
      table.insert(ids, spec.match_id)
    end
  end

  return ids
end

---@package
---@return string?
function HL.pick()
  local picked = {}

  for hl_group, spec in pairs(HL.record) do
    if not spec.word_pattern then
      table.insert(picked, hl_group)
    end
  end

  local picked_count = vim.tbl_count(picked)

  if picked_count == 0 then
    return nil
  end

  if config.random then
    return picked[math.random(picked_count)]
  else
    table.sort(picked)
    return picked[1]
  end
end

---@package
---@param word_pattern string
---@return highlight_record?
function HL.record_of(word_pattern)
  for hl_group, spec in pairs(HL.record) do
    if spec.word_pattern == word_pattern then
      return { [hl_group] = spec }
    end
  end

  return nil
end

-- / Highlight Handler
-- -------------------------------------------------------------------------------------------------

---@package
---@param word_pattern string
function HL.off(word_pattern)
  local record = HL.record_of(word_pattern)

  if not record then
    M.fail('Unable to find the highlight and match-id for "' .. word_pattern .. '".')
    return
  end

  HL.sweep(record)
end

---@package
---@param word_pattern string
function HL.on(word_pattern)
  local hl_group = HL.pick()

  if not hl_group then
    M.warn('No more highlights in stock.')
    return
  end

  local match_id = -1

  for win_number = 1, fn.winnr('$') do
    local suceeded, registered_id, foo = pcall(function()
      return fn.matchadd(
        hl_group, word_pattern, config.highlight_priority, match_id, { window = win_number }
      )
    end)

    if suceeded and (match_id == -1) then
      match_id = registered_id
    end
  end

  if match_id == -1 then
    M.fail('Unable to add match "' .. word_pattern .. '" in any windows.')
  end

  HL.apply(hl_group, word_pattern, match_id)
end

---@package
---@param match_id integer
function HL.release(match_id)
  for win_number = 1, fn.winnr('$') do
    local suceeded, result = pcall(function()
      return fn.matchdelete(match_id, win_number)
    end)

    if (not suceeded) or (result == -1) then
      M.fail('Unable to remove the match (id=' .. match_id .. ') in the following reasons:')
      M.fail(result)
    end
  end
end

---@package
---@param record highlight_record?
function HL.sweep(record)
  if not record then
    record = HL.record
  end

  for hl_group, spec in pairs(record) do
    if spec.match_id then
      HL.release(spec.match_id)
      HL.cancel(hl_group)
    end
  end
end


-- =================================================================================================
--  Function (API)
-- =================================================================================================

function API.clear()
  HL.sweep()
end

---@param options table @see default_config
function API.setup(options)
  options = options or {}
  config = vim.tbl_deep_extend('force', default_config, options)

  M.initialize_highlight()
  math.randomseed(os.time())
end

function API.toggle()
  local mode = api.nvim_get_mode().mode

  -- Only accepts "v" (Visual, includes like as "viw") or "^V" (V-Block), not "V" (V-Line).
  local is_visual_mode = mode == 'v' or mode == '\x16' -- \x16 == '^V'

  local word = ''

  if is_visual_mode then
    word = M.retrieve_text()
  else
    word = fn.expand('<cword>')
  end

  if #word == 0 then
    return
  end

  local word_pattern = ''

  if is_visual_mode then
    word_pattern = M.apply_pattern_mode(word)
  else
    -- "\<" and "\>" are word boundary specifiers, which are only needed in normal mode when
    -- targeting the word under the cursor.
    word_pattern = M.apply_pattern_mode('\\<' .. word .. '\\>')
  end

  if HL.is_used_for(word_pattern) then
    HL.off(word_pattern)
  else
    HL.on(word_pattern)
  end
end

-- =================================================================================================
--  Export
-- =================================================================================================

return {
  setup = API.setup,
  toggle = API.toggle,
  clear = API.clear,
}
