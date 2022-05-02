local plugin = require('shake.plugin.plugin')
local utils = require('shake.shared.utils')
local sniplua = require('shake.extensions.sniplua')
local presets = require('shake.plugin.presets')
local api = require('shake.plugin.api')

local c = utils.create_wrapped_method

local M = {
  api = {
    to_upper_case = c('to_upper_case', api.to_upper_case),
    to_lower_case = c('to_lower_case', api.to_lower_case),
    to_snake_case = c('to_snake_case', api.to_snake_case),
    to_dash_case = c('to_dash_case', api.to_dash_case),
    to_constant_case = c('to_constant_case', api.to_constant_case),
    to_dot_case = c('to_dot_case', api.to_dot_case),
    to_phrase_case = c('to_phrase_case', api.to_phrase_case),
    to_camel_case = c('to_camel_case', api.to_camel_case),
    to_pascal_case = c('to_pascal_case', api.to_pascal_case),
    to_title_case = c('to_title_case', api.to_title_case),
    to_path_case = c('to_path_case', api.to_path_case),
  },
  utils = {
    create_wrapped_method = c,
    trim_str = utils.trim_str,
    untrim_str = utils.untrim_str,
  },
  sniplua = {
    from_snip_input = sniplua.from_snip_input,
    flatten_multilines = sniplua.flatten_multilines,
  },
  presets = {
    stringcase = presets.stringcase,
    toggle_boolean = presets.toggle_boolean,
  },
  setup = plugin.setup,
  register_keybindings = plugin.register_keybindings,
  register_keys = plugin.register_keys,
  register_replace_command = plugin.register_replace_command,
  replace_word_under_cursor = plugin.replace_word_under_cursor,
  replace_selection = plugin.replace_selection,
  dispatcher = plugin.dispatcher,
  operator = plugin.operator,
  operator_callback = plugin.operator_callback,
  line = plugin.line,
  current_word = plugin.current_word,
  eol = plugin.eol,
  visual = plugin.visual,
  lsp_rename = plugin.lsp_rename,
  clear_match = plugin.clear_match,
}

return M
