local utils = require("stringcase.utils")
local config = require("stringcase.config")

local range = {}

range.state = {
  subject = nil,
  match = nil,
  overrides = {},
}

function range.operator(options)
  range.state.overrides = options or {}
  vim.o.operatorfunc = "v:lua.require'stringcase.range'.operator_callback"
  vim.api.nvim_feedkeys("g@", "i", false)
end

function range.visual(options)
  range.state.overrides = options or {}
  vim.o.operatorfunc = "v:lua.require'stringcase.range'.operator_callback"
  vim.api.nvim_feedkeys("g@`>", "i", false)
end

function range.word(options)
  range.state.overrides = options or {}
  vim.o.operatorfunc = "v:lua.require'stringcase.range'.operator_callback"
  vim.api.nvim_feedkeys("g@iw", "i", false)
end

local function create_match()
  range.state.match = vim.fn.matchadd("Search", vim.fn.escape(range.state.subject, "\\"), 2)

  vim.cmd([[
    augroup stringcaseClearMatch
      autocmd!
      autocmd InsertEnter,WinLeave,BufLeave * lua require('stringcase.range').clear_match()
      autocmd CursorMoved * lua require('stringcase.range').clear_match()
    augroup END
  ]])
end

function range.clear_match()
  if nil ~= range.state.match then
    vim.fn.matchdelete(range.state.match)
    range.state.match = nil
  end

  vim.cmd([[
    augroup stringcaseClearMatch
      autocmd!
    augroup END
  ]])
end

function range.operator_callback(vmode)
  local region = utils.get_region(vmode)
  if region.start_row ~= region.end_row then
    vim.notify("Multiline is not supported by stringcaseRange", vim.log.levels.INFO)
    return
  end

  local line = vim.api.nvim_buf_get_lines(0, region.start_row - 1, region.end_row, true)
  range.state.subject = string.sub(line[1], region.start_col + 1, region.end_col + 1)

  create_match()

  vim.o.operatorfunc = "v:lua.require'stringcase.range'.selection_operator_callback"
  vim.api.nvim_feedkeys("g@", "t", false)
end

local function create_replace_command()
  local c = config.get_range(range.state.overrides)
  local escaped_subject = vim.fn.escape(range.state.subject, "\\")
  return string.format(
    ":'[,']%s/%s/%s/g%s<Left><Left>%s",
    c.prefix,
    escaped_subject,
    c.prompt_current_text and escaped_subject or "",
    c.confirm and "c" or "",
    c.confirm and "<left>" or ""
  )
end

function range.selection_operator_callback()
  range.clear_match()

  local keys = vim.api.nvim_replace_termcodes(create_replace_command(), true, false, true)
  vim.api.nvim_feedkeys(keys, "tn", true)
end

return range
