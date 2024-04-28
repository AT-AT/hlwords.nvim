-- =================================================================================================
--  Types
-- =================================================================================================

---@alias color_spec table<string, any> Options acceptable to vim.api.nvim_set_hl()

-- https://github.com/LuaLS/lua-language-server/discussions/1436#discussioncomment-3318346
---@class PluginOptions
---@field colors table
---@field highlight_priority integer
---@field random boolean
---@field strict_word boolean


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Function
-- =================================================================================================

---@type string
M.plugin_name = 'Hlwords'

---@type PluginOptions
M.default_options = {
  colors = {
    { fg = '#000000', bg = '#00ffff' },
    { fg = '#ffffff', bg = '#ff00ff' },
    { fg = '#000000', bg = '#ffff00' },
    { fg = '#ffffff', bg = '#444444' },
  },
  highlight_priority = 10,
  random = true,
  strict_word = false,
}

---@type PluginOptions
M.options = vim.tbl_deep_extend('force', {}, M.default_options)

---@param local_options PluginOptions?
function M.merge_options(local_options)
  local_options = local_options or {}
  M.options = vim.tbl_deep_extend('force', M.options, local_options)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
