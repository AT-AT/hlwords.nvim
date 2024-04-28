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

---@param target string
---@return string
function M.to_pattern(target)
  local is_visual_mode = utils.is_acceptable_vmode()
  local has_uppercase_letters = fn.match(target, '\\u') ~= -1
  local ignore_case = vim.api.nvim_get_option_value('ignorecase', {})
  local smart_case = vim.api.nvim_get_option_value('smartcase', {})
  local text = target
  local case_flag = '\\C' -- Case-Sensitive(\C)

  -- To prevent patterns with the same meaning but with different "case" letters from being
  -- registered, generate a pattern using lowercase letters if possible.
  if ignore_case and (not smart_case) then
    text = string.lower(text)
  end

  if not is_visual_mode and config.options.strict_word then
    text = '\\<' .. text .. '\\>'
  end

  -- Depending on the values of "case" related options and the contents of the target string, use
  -- the Case-Insensitive(\c) flag if possible.
  if ignore_case and (not smart_case or not has_uppercase_letters) then
    case_flag = '\\c'
  end

  -- With "Very Nomagic(\V)", meta characters included in the target string are treated as normal
  -- literals as much as possible.
  return case_flag .. '\\V' .. text
end

---@return string
---
--- TODO: After "getregion()" is merged, refactor using it. And once it's merged and sufficient
---       functionality is implemented, "vim.region" will be deprecated and will not be used.
function M.retrieve()
  -- In visual mode, only accepts Visual ("v", "viw") or V-Block ("^V"), not V-Line ("V").
  local is_visual_mode = utils.is_acceptable_vmode()

  if not is_visual_mode then
    return fn.expand('<cword>')
  end

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

  return table.concat(vim.tbl_map(function(line)
    return fn.escape(line, '\\')
  end, lines), '\\n')
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
