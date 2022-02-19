local utils = require("utils")
local constants = require("constants")
local conversion = require("conversion")
local config = require("config")
local types = require("types")

local M = {}

M.state = {
  register = nil,
  methods_by_key = {},
  methods_by_command = {},
  change_type = nil,
  current_method = nil, -- Since curried vim func operators are not yet supported
  match = nil,
}

local plugin_name = 'Shane.nvim'
local namespace = 'stringcase'

function M.setup(options)
  M.config = config.setup(options)

  local conversions = M.config.conversions

  for key, method in ipairs(conversions) do
    M.state.methods_by_key[key] = method
  end
end

function M.register_keybindings(key, keybindings)
  if ~M[key] then
    print(plugin_name + ': method ' + key + ' not registered')
    return
  end

  for _, feature in ipairs({ 'line', 'eol', 'visual', 'operator', 'lsp_rename' }) do
    if keybindings[feature] ~= nil then
      vim.api.nvim_set_keymap(
        "n",
        keybindings[feature],
        "<cmd>lua require('" .. namespace .. "')." .. feature .. "('" .. key .. "')<cr>",
        { noremap = true }
      )
    end
  end
end

function M.reg_keys(method, keybindings)
  -- Sugar syntax
  M.register_keybindings(method, {
    line = keybindings[1],
    eol = keybindings[2],
    visual = keybindings[3],
    operator = keybindings[4],
    lsp_rename = keybindings[5],
  })
end

function M.register_replace_command(command, method_keys)
  -- TODO: validate command

  for _, method in ipairs(method_keys) do
    M.state.methods_by_command[command] = {}
    if M.state.methods_by_key[method] then
      print(plugin_name + ': method ' + method + ' not registered')
    else
      table.insert(M.state.methods_by_command[command], method)
    end
  end

  vim.cmd(
    "command! -nargs=1 -bang -bar -range=0 " .. command .. " :lua require('" .. namespace .. "').dispatcher('" .. command .. "', <q-args>)"
  )
end

function M.dispatcher(command, args)
  local params = vim.split(args, '/')
  local source, dest = params[2], params[3]

  -- TODO: Hightlight matches
  -- stringcase.state.match = vim.fn.matchadd("Search", vim.fn.escape(source, "\\"), 2)
  local cursor_pos = vim.fn.getpos(".")

  for _, method in ipairs(M.state.methods_by_command[command]) do
    local transformed_source = method(source)
    local transformed_dest = method(dest)

    local get_match = utils.get_list(utils.escape_string(transformed_source))
    for match in get_match do
      M.replace_matches(match, transformed_source, transformed_dest, false)
    end
  end

  vim.fn.setpos(".", cursor_pos)
end

function M.operator(method_key)
  M.state.register = vim.v.register
  M.state.current_method = method_key
  vim.o.operatorfunc = "v:lua.require'" .. namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@", "i", false)
end

function M.operator_callback(vmode)
  local region = utils.get_region(vmode)

  if M.state.change_type == types.change_type.LSP_RENAME then
    conversion.do_lsp_rename(M.state.register)
  else
    conversion.do_substitution(
      region.start_row - 1,
      region.start_col,
      region.end_row - 1,
      region.end_col + 1,
      M.state.methods_by_key[M.state.current_method]
    )
  end
end

function M.line(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc
  vim.o.operatorfunc = "v:lua.require'" .. namespace .."'.operator_callback"
  local keys = vim.api.nvim_replace_termcodes(
    string.format("g@:normal! 0v%s$<cr>", vim.v.count > 0 and vim.v.count - 1 .. "j" or ""),
    true,
    false,
    true
  )
  vim.api.nvim_feedkeys(keys, "i", false)
end

function M.eol(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc
  vim.o.operatorfunc = "v:lua.require'" .. namespace .."'.operator_callback"
  vim.api.nvim_feedkeys("g@$", "i", false)
end

function M.visual(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc
  vim.o.operatorfunc = "v:lua.require'" .. namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@`>", "i", false)
end

function M.lsp_rename(case_desc)
  M.state.register = vim.v.register
  M.state.current_case = case_desc
  M.state.change_type = constants.change_type.LSP_RENAME

  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@aW", "i", false)
end

return M
