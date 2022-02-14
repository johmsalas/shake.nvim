local utils = require("utils")
local config = require("config")
local types = require("types")
local lsp = vim.lsp

local stringcase = {}

stringcase.state = {
  register = nil,
  case_by_descriptor = {},
  case_by_trigger = {},
  change_type = nil,
  current_case = nil, -- Since curried vim func operators are not yet supported
  match = nil,
}

function stringcase.setup(options)
  stringcase.config = config.setup(options)

  local operator_prefix = stringcase.config.operator_prefix
  local lsp_operator_prefix = stringcase.config.lsp_operator_prefix
  local search_replace_prefix = stringcase.config.search_replace_prefix

  for _, case in ipairs(types.string_cases) do
    local desc, trigger = case.descriptor, case.trigger
    stringcase.state.case_by_descriptor[desc] = case
    stringcase.state.case_by_trigger[trigger] = case

    if operator_prefix ~= nil then
      vim.api.nvim_set_keymap("n", operator_prefix .. case.trigger .. case.trigger, "<cmd>lua require('stringcase').line('" .. desc .. "')<cr>", { noremap = true })
      vim.api.nvim_set_keymap("n", operator_prefix .. case.trigger:upper(), "<cmd>lua require('stringcase').eol('" .. desc .. "')<cr>", { noremap = true })
      vim.api.nvim_set_keymap("n", operator_prefix .. case.trigger, "<cmd>lua require('stringcase').operator('" .. desc .. "')<cr>", { noremap = true })
    end

    if lsp_operator_prefix ~= nil then
      vim.api.nvim_set_keymap("n", lsp_operator_prefix .. case.trigger, "<cmd>lua require('stringcase').lsp_rename('" .. desc .. "')<cr>", { noremap = true })
    end

    if search_replace_prefix ~= nil then
      vim.cmd("command! -nargs=1 -bang -bar -range=0 " .. search_replace_prefix .. " :lua require('stringcase').dispatcher(<q-args>)")
    end
  end

end

function stringcase.replace_matches(match, source, dest, try_lsp)
  if utils.is_empty_position(match) then return end
  -- print(vim.inspect(match))

  local row, start_col = match[1] - 1, match[2] - 1
  local source_end_col = start_col + string.len(source)
  local current = utils.nvim_buf_get_text(0, row, start_col, row, source_end_col)
  if current[1] == source then
    if try_lsp then
      -- not used yet, hard coded to false
      local params = lsp.util.make_position_params()
      params.newName = dest
      local response = lsp.buf_request(0, 'textDocument/rename', params)
      -- print(vim.inspect(response))
    else
      vim.api.nvim_buf_set_text(0, row, start_col, row, source_end_col, {dest})
    end
  end
end

function stringcase.dispatcher(args)
  local params = vim.split(args, '/')
  local source, dest = params[2], params[3]

  -- TODO: Hightlight matches
  -- stringcase.state.match = vim.fn.matchadd("Search", vim.fn.escape(source, "\\"), 2)
  local cursor_pos = vim.fn.getpos(".")

  for _, case in ipairs(types.string_cases) do
    local transformed_source = case.method(source)
    local transformed_dest = case.method(dest)

    local get_match = utils.get_list(utils.escape_string(transformed_source))
    for match in get_match do
      stringcase.replace_matches(match, transformed_source, transformed_dest, false)
    end
  end

  vim.fn.setpos(".", cursor_pos)
end

function stringcase.operator(case_desc)
  stringcase.state.register = vim.v.register
  stringcase.state.current_case = case_desc
  vim.o.operatorfunc = "v:lua.require'stringcase'.operator_callback"
  vim.api.nvim_feedkeys("g@", "i", false)
end

function stringcase.lsp_rename(case_desc)
  stringcase.state.register = vim.v.register
  stringcase.state.current_case = case_desc
  stringcase.state.change_type = types.change_type.LSP_RENAME

  vim.o.operatorfunc = "v:lua.require'stringcase'.operator_callback"
  vim.api.nvim_feedkeys("g@aW", "i", false)
end

local function do_substitution(start_row, start_col, end_row, end_col, register)
  local lines = utils.nvim_buf_get_text(0, start_row, start_col, end_row, end_col)
  local transformed = utils.map(lines, stringcase.state.case_by_descriptor[stringcase.state.current_case].method)

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, transformed)

  if config.options.on_stringcase ~= nil then
    config.options.on_stringcase({
      register = register,
    })
  end
end

local function do_lsp_rename(register)
  local current_word = vim.fn.expand('<cword>')
  local handler = stringcase.state.case_by_descriptor[stringcase.state.current_case].method

  local params = lsp.util.make_position_params()
  params.newName = handler(current_word)
  lsp.buf_request(0, 'textDocument/rename', params)

  if config.options.on_stringcase ~= nil then
    config.options.on_stringcase({
      register = register,
    })
  end
end

function stringcase.operator_callback(vmode)
  local region = utils.get_region(vmode)

  if stringcase.state.change_type == types.change_type.LSP_RENAME then
    do_lsp_rename(stringcase.state.register)
  else
    do_substitution(
      region.start_row - 1,
      region.start_col,
      region.end_row - 1,
      region.end_col + 1,
      stringcase.state.register
    )
  end
end

function stringcase.line(case_desc)
  stringcase.state.register = vim.v.register
  stringcase.state.current_case = case_desc
  vim.o.operatorfunc = "v:lua.require'stringcase'.operator_callback"
  local keys = vim.api.nvim_replace_termcodes(
    string.format("g@:normal! 0v%s$<cr>", vim.v.count > 0 and vim.v.count - 1 .. "j" or ""),
    true,
    false,
    true
  )
  vim.api.nvim_feedkeys(keys, "i", false)
end

function stringcase.eol(case_desc)
  stringcase.state.register = vim.v.register
  stringcase.state.current_case = case_desc
  vim.o.operatorfunc = "v:lua.require'stringcase'.operator_callback"
  vim.api.nvim_feedkeys("g@$", "i", false)
end

function stringcase.visual(case_desc)
  stringcase.state.register = vim.v.register
  stringcase.state.current_case = case_desc
  vim.o.operatorfunc = "v:lua.require'stringcase'.operator_callback"
  vim.api.nvim_feedkeys("g@`>", "i", false)
end

return stringcase
