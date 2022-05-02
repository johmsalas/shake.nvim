local M = {}

M.plugin_name = 'shake.nvim'
M.namespace = 'shake'

M.change_type = {
  LSP_RENAME = 'LSP_RENAME',
  CURRENT_WORD = 'CURRENT_WORD',
}

return M
