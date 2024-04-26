-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
local api = vim.api

---@module 'hlwords.config'
local config = require('hlwords.config')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Function
-- =================================================================================================

-- / Notification
-- -------------------------------------------------------------------------------------------------

---@param message string
function M.fail(message)
  M.notice(vim.log.levels.ERROR, message)
end

---@param level any @see vim.log.levels
---@param message string
function M.notice(level, message)
  vim.notify(config.plugin_name .. ': ' .. message, level)
end

---@param message string
function M.warn(message)
  M.notice(vim.log.levels.WARN, message)
end

-- / Determiner
-- -------------------------------------------------------------------------------------------------

---@type string "^V" = "\x16"
M.v_block_keycode = vim.api.nvim_replace_termcodes('<C-v>', true, false, true)

---@return boolean
function M.is_acceptable_vmode()
  local mode = api.nvim_get_mode().mode

  -- Only accepts "v" (Visual, includes like as "viw") or "^V" (V-Block), not "V" (V-Line).
  return mode == 'v' or mode == M.v_block_keycode
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
