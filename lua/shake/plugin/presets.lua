local M = {}

local plugin = require('shake.plugin.plugin')
local utils = require('shake.shared.utils')
local api = require('shake.plugin.api')

M.stringcase = function(opts)
  local prefix = opts and opts.prefix or 'cr'

  plugin.register_keybindings(api.to_constant_case, {
    current_word = prefix .. 'n',
    visual = prefix .. 'n',
    operator = prefix .. 'on',
    lsp_rename = prefix .. 'N',
  })
  plugin.register_keybindings(api.to_camel_case, {
    current_word = prefix .. 'c',
    visual = prefix .. 'c',
    operator = prefix .. 'oc',
    lsp_rename = prefix .. 'C',
  })
  plugin.register_keybindings(api.to_dash_case, {
    current_word = prefix .. 'd',
    visual = prefix .. 'd',
    operator = prefix .. 'od',
    lsp_rename = prefix .. 'D',
  })
  plugin.register_keybindings(api.to_pascal_case, {
    current_word = prefix .. 'p',
    visual = prefix .. 'p',
    operator = prefix .. 'op',
    lsp_rename = prefix .. 'P',
  })
  plugin.register_keybindings(api.to_upper_case, {
    current_word = prefix .. 'u',
    visual = prefix .. 'u',
    operator = prefix .. 'ou',
    lsp_rename = prefix .. 'U',
  })
  plugin.register_keybindings(api.to_lower_case, {
    current_word = prefix .. 'l',
    visual = prefix .. 'l',
    operator = prefix .. 'ol',
    lsp_rename = prefix .. 'L',
  })

  plugin.register_replace_command('Subs', {
    api.to_upper_case,
    api.to_lower_case,
    api.to_snake_case,
    api.to_dash_case,
    api.to_constant_case,
    api.to_dot_case,
    api.to_phrase_case,
    api.to_camel_case,
    api.to_pascal_case,
    api.to_title_case,
    api.to_path_case,
  })
end

M.toggle_boolean = function(opts)
  local keybindings = opts and opts.keybindings or {current_word = 'gt'}

  local swappable_combinations = {
    {{'true'}, {'false'}},
    {{'TRUE'}, {'FALSE'}},
    {{'1', '\\d\\@<!1\\{1}\\d\\@!'}, {'0','\\d\\@<!0\\{1}\\d\\@!'}},
  }

  local jumper = function(str, region)
    local trimmed_str = utils.trim_str(str[1])
    local cursor_pos = vim.fn.getpos(".")

    for _, swap_values in ipairs(swappable_combinations) do
      if vim.tbl_contains(swap_values, trimmed_str) then
        return region
      end
    end

    local closest = nil
    local closest_value = nil
    for _, swap_values in ipairs(swappable_combinations) do
      for _, elements in ipairs(swap_values) do
        local value = elements
        local regex = elements
        if type(value) == 'table' then
          value = elements[1]
          regex = elements[2] or value
        end
        local next = vim.fn.searchpos(regex)
        vim.fn.setpos(".", cursor_pos)
        if not utils.is_empty_position(next) and
          next[1] >= cursor_pos[2] and
          (
            closest == nil
            or (next[1] == cursor_pos[2] and next[2] < closest[2])
            or (next[1] > cursor_pos[2] and next[1] < closest[1])
            or (next[1] > cursor_pos[2] and next[1] == closest[1] and next[2] < closest[2])
          )
        then
          closest = next
          closest_value = value
        end
      end
    end

    local row = closest[1]

    region = {
      start_row = row,
      start_col = closest[2],
      end_row = row,
      end_col = closest[2] + #closest_value,
    }

    return region
  end

  local toggle_boolean = utils.create_wrapped_method('toggle_boolean', function(str)
    local trim_info, trimmed_str = utils.trim_str(str)
    local result = trimmed_str

    if trimmed_str == 'true' then
      result = 'false'
    elseif trimmed_str == 'false' then
      result = 'true'
    end

    if trimmed_str == 'TRUE' then
      result = 'FALSE'
    elseif trimmed_str == 'FALSE' then
      result = 'TRUE'
    end

    if trimmed_str == '1' then
      result = '0'
    elseif trimmed_str == '0' then
      result = '1'
    end

    return utils.untrim_str(result, trim_info)
  end)

  plugin.register_keybindings(toggle_boolean, keybindings, {
    jumper = jumper
  })
end

return M
