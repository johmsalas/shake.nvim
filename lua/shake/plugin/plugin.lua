local utils = require("shake.shared.utils")
local constants = require("shake.shared.constants")
local conversion = require("shake.plugin.conversion")
local config = require("shake.plugin.config")

local M = {}

M.state = {
  register = nil,
  methods_by_desc = {},
  methods_by_command = {},
  change_type = nil,
  current_method = nil, -- Since curried vim func operators are not yet supported
  match = nil,
}

function M.setup(options)
  M.config = config.setup(options)

  local conversions = M.config.conversions

  for key, method in ipairs(conversions) do
    M.state.methods_by_desc[key] = method
  end
end

function M.register_keybindings(method_table, keybindings)
  -- TODO: validate method_table
  M.state.methods_by_desc[method_table.desc] = method_table
  for _, feature in ipairs({
    'line',
    'eol',
    'visual',
    'operator',
    'lsp_rename',
    'current_word',
  }) do
    if keybindings[feature] ~= nil then
      vim.api.nvim_set_keymap(
        "n",
        keybindings[feature],
        "<cmd>lua require('" .. constants.namespace .. "')." .. feature .. "('" .. method_table.desc .. "')<cr>",
        { noremap = true }
      )
    end
  end
end

function M.register_keys(method_table, keybindings)
  -- Sugar syntax
  M.register_keybindings(method_table, {
    line = keybindings[1],
    eol = keybindings[2],
    visual = keybindings[3],
    operator = keybindings[4],
    lsp_rename = keybindings[5],
    current_word = keybindings[6],
  })
end

function M.register_replace_command(command, method_keys)
  -- TODO: validate command
  M.state.methods_by_command[command] = {}

  for _, method in ipairs(method_keys) do
    table.insert(M.state.methods_by_command[command], method)
  end

  vim.cmd([[
    command! -nargs=1 -bang -bar -range=0 ]] .. command .. [[ :lua require("]] .. constants.namespace .. [[").dispatcher( "]] .. command .. [[" ,<q-args>)
  ]])
end

function M.clear_match(command_namespace)
  if nil ~= M.state.match then
    vim.fn.matchdelete(M.state.match)
    M.state.match = nil
  end

  vim.cmd([[
    augroup ]] .. command_namespace .. [[ClearMatch
      autocmd!
    augroup END
  ]])
end

local function add_match(command, str)
  local command_namespace = constants.namespace .. command
  M.state.match = vim.fn.matchadd(
    command_namespace,
    vim.fn.escape(str, "\\"),
    2
  )

  vim.cmd([[
    augroup ]] .. command_namespace .. [[ClearMatch
      autocmd!
      autocmd InsertEnter,WinLeave,BufLeave * lua require("]] .. constants.namespace .. [[").clear_match("]] .. command_namespace .. [[")
      autocmd CursorMoved * lua require("]] .. constants.namespace .. [[").clear_match("]] .. command_namespace .. [[")
    augroup END
  ]])
end

function M.dispatcher(command, args)
  local params = vim.split(args, '/')
  local source, dest = params[2], params[3]

  -- TODO: Hightlight matches
  -- stringcase.state.match = vim.fn.matchadd("Search", vim.fn.escape(source, "\\"), 2)
  local cursor_pos = vim.fn.getpos(".")

  for _, method in ipairs(M.state.methods_by_command[command]) do
    local transformed_source = method.apply(source)
    local transformed_dest = method.apply(dest)

    add_match(command, transformed_source)

    local get_match = utils.get_list(utils.escape_string(transformed_source))
    for match in get_match do
      conversion.replace_matches(match, transformed_source, transformed_dest, false)
    end
  end

  vim.fn.setpos(".", cursor_pos)
end

function M.operator(method_key)
  M.state.register = vim.v.register
  M.state.current_method = method_key
  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@", "i", false)
end

function M.operator_callback(vmode)
  local region = utils.get_region(vmode)
  local method = M.state.methods_by_desc[M.state.current_method].apply

  if M.state.change_type == constants.change_type.LSP_RENAME then
    conversion.do_lsp_rename(method)
  else
    conversion.do_substitution(
      region.start_row - 1,
      region.start_col,
      region.end_row - 1,
      region.end_col + 1,
      method
    )
  end
end

function M.line(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc
  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .."'.operator_callback"
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
  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .."'.operator_callback"
  vim.api.nvim_feedkeys("g@$", "i", false)
end

function M.visual(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc
  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@`>", "i", false)
end

function M.lsp_rename(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc
  M.state.change_type = constants.change_type.LSP_RENAME

  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@aW", "i", false)
end

function M.current_word(case_desc)
  M.state.register = vim.v.register
  M.state.current_method = case_desc

  vim.o.operatorfunc = "v:lua.require'" .. constants.namespace .. "'.operator_callback"
  vim.api.nvim_feedkeys("g@aW", "i", false)
end


function M.replace_word_under_cursor(command)
  local current_word = vim.fn.expand('<cword>')
  vim.api.nvim_feedkeys(":" .. command .. '/' .. current_word .. '/', "i", false)
end

function M.replace_selection()
  print('TODO: pending implementation')
end

return M

