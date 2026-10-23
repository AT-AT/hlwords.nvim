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

---@return string
function M.accept()
  -- https://github.com/kylechui/nvim-surround/blob/main/lua/nvim-surround/input.lua
  local status, result = pcall(
    vim.fn.input, { prompt = 'Toggle highlight: ', cancelreturn = vim.NIL }
  )

  return (status and result ~= vim.NIL) and result or ''
end

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
function M.retrieve()
  -- In visual mode, only accepts Visual ("v", "viw") or V-Block ("^V"), not V-Line ("V").
  local is_visual_mode = utils.is_acceptable_vmode()

  if not is_visual_mode then
    return fn.expand('<cword>')
  end

  local lines = fn.getregion(fn.getpos('v'), fn.getpos('.'), { type = api.nvim_get_mode().mode })

  -- Return to normal mode.
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
