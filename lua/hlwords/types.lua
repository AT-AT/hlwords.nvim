-- =================================================================================================
--  Types
-- =================================================================================================

-- https://github.com/LuaLS/lua-language-server/discussions/1436#discussioncomment-3318346
---@class PluginOptions
---@field colors table
---@field highlight_priority integer
---@field random boolean
---@field strict_word boolean

---@alias color_spec table<string, any> Options acceptable to vim.api.nvim_set_hl()

---@alias highlight_group string
---@alias word_pattern string
---@alias highlight_record { hl_group: highlight_group,  word_pattern: word_pattern? }
---@alias match_id number
