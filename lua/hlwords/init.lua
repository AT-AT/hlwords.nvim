-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
local api = vim.api

---@module 'hlwords.config'
local config = require('hlwords.config')

---@module 'hlwords.letters'
local letters = require('hlwords.letters')

---@module 'hlwords.highlight'
local highlight = require('hlwords.highlight')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local API = {}


-- =================================================================================================
--  Function (API)
-- =================================================================================================

function API.clear()
  highlight.off()
end

---@param local_options PluginOptions?
function API.setup(local_options)
  config.merge_options(local_options or {})
  highlight.define()
  math.randomseed(os.time())

  -- Note that even if use "WinNew" event, it's difficult to identify the newly added window, so use
  -- "WinEnter" event to process each time.
  --   https://github.com/neovim/neovim/issues/25844
  --   https://github.com/neovim/neovim/issues/23581
  api.nvim_create_autocmd({ 'WinEnter' }, {
    group = api.nvim_create_augroup(config.plugin_name .. 'AutoCmd', {}),
    callback = function(_)
      local win_id = api.nvim_get_current_win()
      highlight.apply(win_id)
    end,
  })
end

function API.toggle()
  local word = letters.retrieve()

  if #word == 0 then
    return
  end

  local word_pattern = letters.to_pattern(word)

  if highlight.is_used_for(word_pattern) then
    highlight.off(word_pattern)
  else
    highlight.on(word_pattern)
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
