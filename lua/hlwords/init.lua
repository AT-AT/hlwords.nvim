-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
local api = vim.api

---@see vim.fn
local fn = vim.fn

---@module 'hlwords.config'
local config = require('hlwords.config')

---@module 'hlwords.letters'
local letters = require('hlwords.letters')


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

---@type PluginOptions
local options


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
  vim.notify(config.plugin_name .. ': ' .. message, level)
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
  for index, color_table in pairs(options.colors) do
    local hl_group = config.plugin_name .. string.format('%02d', index)

    api.nvim_set_hl(0, hl_group, color_table)
    HL.register(hl_group)
  end
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

  if options.random then
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
  local wins = api.nvim_list_wins()

  for _, win_id in pairs(wins) do
    local registered_id = api.nvim_win_call(win_id, function()
      return fn.matchadd(hl_group, word_pattern, options.highlight_priority, match_id)
    end)

    if registered_id == -1 then
      M.fail('Unable to add match "' .. word_pattern .. '" in window (id=' .. win_id .. ').')
    else
      match_id = registered_id
    end
  end

  HL.apply(hl_group, word_pattern, match_id)
end

---@package
---@param match_id integer
function HL.release(match_id)
  local result = fn.matchdelete(match_id)

  if result == -1 then
    M.fail('Unable to remove the match (id=' .. match_id .. ').')
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

---@param user_options PluginOptions
function API.setup(user_options)
  user_options = user_options or {}
  options = vim.tbl_deep_extend('force', config.default_options, user_options)

  M.initialize_highlight()
  math.randomseed(os.time())
end

function API.toggle()
  local mode = api.nvim_get_mode().mode

  -- Only accepts "v" (Visual, includes like as "viw") or "^V" (V-Block), not "V" (V-Line).
  local is_visual_mode = mode == 'v' or mode == '\x16' -- \x16 == '^V'

  local word = ''

  if is_visual_mode then
    word = letters.retrieve()
  else
    word = fn.expand('<cword>')
  end

  if #word == 0 then
    return
  end

  local word_pattern = ''

  if is_visual_mode or not options.strict_word then
    word_pattern = letters.to_pattern(word)
  else
    word_pattern = letters.to_pattern('\\<' .. word .. '\\>')
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
