local types = {}
local casing = require("casing")

types.change_type = {
  LSP_RENAME = 1
}

types.string_cases = {
  {
    descriptor = "upper_case",
    trigger = 'u',
    method = casing.to_upper_case
  },
  {
    descriptor = "lower_case",
    trigger = 'l',
    method = casing.to_lower_case
  },
  {
    descriptor = "snake_case",
    trigger = 's',
    method = casing.to_snake_case
  },
  {
    descriptor = "dash_case",
    trigger = 'd',
    method = casing.to_dash_case
  },
  {
    descriptor = "constant_case",
    trigger = 'n',
    method = casing.to_constant_case
  },
  {
    descriptor = "dot_case",
    trigger = 'o',
    method = casing.to_dot_case
  },
  {
    descriptor = "prhase_case",
    trigger = 'h',
    method = casing.to_phrase_case
  },
  {
    descriptor = "camel_case",
    trigger = 'c',
    method = casing.to_camel_case
  },
  {
    descriptor = "pascal_case",
    trigger = 'p',
    method = casing.to_pascal_case
  },
  {
    descriptor = "title_case",
    trigger = 't',
    method = casing.to_title_case
  },
  {
    descriptor = "path_case",
    trigger = 'f',
    method = casing.to_path_case
  },
}

return types
