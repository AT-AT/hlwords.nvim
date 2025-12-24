-- =================================================================================================
--  Types
-- =================================================================================================

---@alias highlight_group string
---@alias word_pattern string
---@alias highlight_record { hl_group: highlight_group,  word_pattern: word_pattern? }
---@alias match_id number


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

---@type highlight_record[]
local records = {}

-- For testing (yes, this is BAD practice, but it's done for convenience, sorry).
function M.grub_records()
  return records
end

-- / Record Modification
-- -------------------------------------------------------------------------------------------------

---@param hl_group highlight_group
---@param word_pattern word_pattern?
function M.record(hl_group, word_pattern)
  for _, record in ipairs(records) do
    if record.hl_group == hl_group then
      record.word_pattern = word_pattern
      return
    end
  end

  table.insert(records, { hl_group = hl_group, word_pattern = word_pattern })
end

---@param hl_group highlight_group
function M.register(hl_group)
  M.record(hl_group, nil)
end

---@param hl_group highlight_group
function M.revert(hl_group)
  M.record(hl_group, nil)
end

-- / Record Manipulation
-- -------------------------------------------------------------------------------------------------

---@param word_pattern word_pattern
---@return boolean
function M.is_used_for(word_pattern)
  return vim.tbl_count(M.record_of(word_pattern)) >= 1
end

---@return highlight_group?
function M.pick()
  local picked = {}

  for _, record in ipairs(records) do
    if not record.word_pattern then
      table.insert(picked, record.hl_group)
    end
  end

  local picked_count = vim.tbl_count(picked)

  if picked_count == 0 then
    return nil
  end

  if config.options.random then
    return picked[math.random(picked_count)]
  else
    return picked[1]
  end
end

---@param word_pattern word_pattern
---@return highlight_record[]
function M.record_of(word_pattern)
  return vim.tbl_filter(function(record)
    return record.word_pattern == word_pattern
  end, records)
end

-- / Match Manipulation
-- -------------------------------------------------------------------------------------------------

---@param win_id integer
function M.apply(win_id)
  local priority = config.options.highlight_priority
  local matches = fn.getmatches(win_id)
  local extract_match = function(stack, key)
    return vim.tbl_filter(function(match)
      return match.group == key
    end, stack)
  end

  for _, record in ipairs(records) do
    local current_matches = extract_match(matches, record.hl_group)
    local match_count = vim.tbl_count(current_matches)

    if match_count > 1 then
      utils.fail(string.format(
        'Multiple matches of highlight group %s were found.', record.hl_group
      ))

      return
    end

    local has_match = match_count == 1
    local match = current_matches[1]

    if record.word_pattern then
      local should_update = has_match and record.word_pattern ~= match.pattern

      if should_update then
        fn.matchdelete(match.id, win_id)
      end

      if should_update or not has_match then
        local candidate_id = nil

        if has_match then
          candidate_id = match.id
        end

        local match_id = M.fix_match_id(win_id, candidate_id)

        -- Currently, the diagnostic message is suppressed because the type of the "option"
        -- parameter cannot be correctly recognized.
        ---@diagnostic disable-next-line: param-type-mismatch
        fn.matchadd(record.hl_group, record.word_pattern, priority, match_id, { window = win_id })
      end
    else
      if has_match then
        fn.matchdelete(match.id, win_id)
      end
    end
  end
end

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

---@param win_id number
---@param candidate number?
---@return match_id?
function M.fix_match_id(win_id, candidate)
  local max = 2000 -- Set a maximum limit just in case.
  local start = candidate or 1000
  local used = {}

  if start > max then
    start = 1000
  end

  for _, match in ipairs(fn.getmatches(win_id)) do
    if match.id and match.id >= 1000 then
      used[match.id] = true
    end
  end

  for id = start, max do
    if not used[id] then
      return id
    end
  end

  utils.fail(string.format(
    'Unable to fix the match-id between "%d" to "%d".', start, max
  ))

  return nil
end

---@param word_pattern word_pattern?
function M.off(word_pattern)
  local target = nil

  if word_pattern == nil then
    target = records
  else
    target = M.record_of(word_pattern)
  end

  if vim.tbl_count(target) == 0 then
    if word_pattern then
      utils.fail(string.format(
        'Unable to find the highlight for "%s".', tostring(word_pattern)
      ))
    end

    return
  end

  for _, record in ipairs(target) do
    M.revert(record.hl_group)
  end

  M.propagate()
end

---@param word_pattern word_pattern
function M.on(word_pattern)
  local hl_group = M.pick()

  if not hl_group then
    utils.warn('No more highlights in stock.')
    return
  end

  M.record(hl_group, word_pattern)
  M.propagate()
end

function M.propagate()
  local wins = api.nvim_list_wins()

  for _, win_id in pairs(wins) do
    M.apply(win_id)
  end
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
