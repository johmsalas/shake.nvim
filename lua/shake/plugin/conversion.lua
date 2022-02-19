local utils = require('utils')
local lsp = vim.lsp

local M = {}

function M.replace_matches(match, source, dest, try_lsp)
  if utils.is_empty_position(match) then return end

  local row, start_col = match[1] - 1, match[2] - 1
  local source_end_col = start_col + string.len(source)
  local current = utils.nvim_buf_get_text(0, row, start_col, row, source_end_col)
  if current[1] == source then
    if try_lsp then
      -- not used yet, hard coded to false
      local params = lsp.util.make_position_params()
      params.newName = dest
      lsp.buf_request(0, 'textDocument/rename', params)
    else
      vim.api.nvim_buf_set_text(0, row, start_col, row, source_end_col, {dest})
    end
  end
end

function M.do_substitution(start_row, start_col, end_row, end_col, method)
  local lines = utils.nvim_buf_get_text(0, start_row, start_col, end_row, end_col)
  local transformed = utils.map(lines, method)

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, transformed)
end

function M.do_lsp_rename(method)
  local current_word = vim.fn.expand('<cword>')
  local params = lsp.util.make_position_params()
  params.newName = method(current_word)
  lsp.buf_request(0, 'textDocument/rename', params)
end

return M
