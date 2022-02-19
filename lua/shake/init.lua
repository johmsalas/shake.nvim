local stringcase = require('conversion.stringcase')
local plugin = require('plugin.plugin')

local M = {
  api = {
    stringcase
  },
  setup = plugin.setup,
  register_keybindings = plugin.register_keybindings,
  reg_keys = plugin.reg_keys,
  register_replace_command = plugin.register_replace_command,
  dispatcher = plugin.dispatcher,
  operator = plugin.operator,
  operator_callback = plugin.operator_callback,
  line = plugin.line,
  eol = plugin.eol,
  visual = plugin.visual,
  lsp_rename = plugin.lsp_rename,
}

return M
