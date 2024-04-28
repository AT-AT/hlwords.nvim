-- =================================================================================================
--  Types
-- =================================================================================================

---@alias word_pattern string
---@alias match_id integer
---@alias highlight_group string
---@alias highlight_spec { word_pattern: word_pattern?, match_id: match_id? }
---@alias highlight_record table<highlight_group, highlight_spec>


-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
local api = vim.api

---@see vim.fn
local fn = vim.fn

---@module 'hlwords.config'
local config = require('hlwords.config')

---@module 'hlwords.utils'
local utils = require('hlwords.utils')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Function
-- =================================================================================================

---@type highlight_record
local records = {}

-- Yes, this is BAD practice, but it's done for convenience.
if _TEST then ---@diagnostic disable-line: undefined-global
  M._records = records
end

-- / Modification
-- -------------------------------------------------------------------------------------------------

---@param hl_group highlight_group
---@param word_pattern word_pattern?
---@param match_id match_id?
function M.record(hl_group, word_pattern, match_id)
  records[hl_group] = { word_pattern = word_pattern, match_id = match_id }
end

---@param hl_group highlight_group
function M.register(hl_group)
  M.record(hl_group, nil, nil)
end

---@param hl_group highlight_group
function M.revert(hl_group)
  M.record(hl_group, nil, nil)
end

-- / Iteration
-- -------------------------------------------------------------------------------------------------

---@param word_pattern word_pattern
---@return boolean
function M.is_used_for(word_pattern)
  for _, spec in pairs(records) do
    if spec.word_pattern == word_pattern then
      return true
    end
  end

  return false
end

---@return match_id[]
function M.match_ids()
  local ids = {}

  for _, spec in pairs(records) do
    if spec.match_id ~= nil then
      table.insert(ids, spec.match_id)
    end
  end

  return ids
end

---@return highlight_group?
function M.pick()
  local picked = {}

  for hl_group, spec in pairs(records) do
    if not spec.word_pattern then
      table.insert(picked, hl_group)
    end
  end

  local picked_count = vim.tbl_count(picked)

  if picked_count == 0 then
    return nil
  end

  if config.options.random then
    return picked[math.random(picked_count)]
  else
    table.sort(picked)
    return picked[1]
  end
end

---@param word_pattern word_pattern
---@return highlight_record?
function M.record_of(word_pattern)
  for hl_group, spec in pairs(records) do
    if spec.word_pattern == word_pattern then
      return { [hl_group] = spec }
    end
  end

  return nil
end

-- / Match Manipulation
-- -------------------------------------------------------------------------------------------------

function M.define()
  local hl_group_prefix = config.plugin_name
  local current_hl_groups = api.nvim_get_hl(0, {})

  for hl_group, _ in pairs(current_hl_groups) do
    if vim.startswith(hl_group, hl_group_prefix) then
      vim.cmd('highlight clear ' .. hl_group)
    end
  end

  for index, color_table in pairs(config.options.colors) do
    local hl_group = hl_group_prefix .. string.format('%05d', index)
    api.nvim_set_hl(0, hl_group, color_table)
    M.register(hl_group)
  end
end

---@param word_pattern word_pattern?
function M.off(word_pattern)
  local target = word_pattern and M.record_of(word_pattern) or records

  if not target then
    utils.fail(string.format(
      'Unable to find the highlight and match-id for "%s".', tostring(word_pattern)
    ))
    return
  end

  local wins = api.nvim_list_wins()

  for hl_group, spec in pairs(target) do
    if spec.match_id then
      M.revert(hl_group)

      for _, win_id in pairs(wins) do
        local result = api.nvim_win_call(win_id, function()
          return fn.matchdelete(spec.match_id)
        end)

        if result == -1 then
          utils.fail(string.format(
            'Unable to remove the match (id=%d) on window (id=%d).', spec.match_id, win_id
          ))
        end
      end
    end
  end
end

---@param word_pattern word_pattern
function M.on(word_pattern)
  local hl_group = M.pick()

  if not hl_group then
    utils.warn('No more highlights in stock.')
    return
  end

  local match_id = -1
  local wins = api.nvim_list_wins()
  local priority = config.options.highlight_priority

  for _, win_id in pairs(wins) do
    local registered_id = api.nvim_win_call(win_id, function()
      return fn.matchadd(hl_group, word_pattern, priority, match_id)
    end)

    if registered_id == -1 then
      utils.fail(string.format(
        'Unable to add match "%s" in window (id=%d).', tostring(word_pattern), win_id
      ))
    else
      match_id = registered_id
    end
  end

  M.record(hl_group, word_pattern, match_id)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
