# Shake.nvim

Give super powers to string transformation LUA functions

## Features

### Lua functions as vim operator

Add your custom vim operators. Wish it was easy to add your LUA functions to repeatable vim operators? With `shake.nvim` you get:

- Custom key binding to apply the function on:
  - Current line
  - Until end of line
  - Given a vim object, like `aw` or `p`
  - The current word, using **LSP rename**. Affecting the definition and its references

### Bulk replacement

Given two pieces of text A and B, it searches for all of A variants (in different string cases or custom functions), and replaces the text using B. It transforms and uses B, according to the target transformation. String cases are prioritized over custom Lua functions

This project also provides a set of basic `changes`:
 - String case (see available string case conversions)


### Operator

A vim operator to change strings, supports:

- Change provided object
- Change whole line
- Change until end of line
- Change word under cursor using LSP

## Built-in string transforms

### String case conversions

|      Case     | Example     | Method                     |
|---------------|-------------|----------------------------|
| Upper case    | LOREM IPSUM | shake.api.to_constant_case |
| Lower case    | lorem ipsum | shake.api.to_lower_case    |
| Snake case    | lorem_ipsum | shake.api.to_snake_case    |
| Dash case     | lorem-ipsum | shake.api.to_dash_case     |
| Constant case | LOREM_IPSUM | shake.api.to_constant_case |
| Dot case      | lorem.ipsum | shake.api.to_dot_case      |
| Camel case    | loremIpsum  | shake.api.to_camel_case    |
| Pascal case   | LoremIpsum  | shake.api.to_pascal_case   |
| Title case    | Lorem Ipsum | shake.api.to_title_case    |
| Path case     | lorem/ipsum | shake.api.to_path_case     |
| Phrase case   | Lorem ipsum | shake.api.to_phrase_case   |

## Integration with other plugins

### Snip Lua

## Requirements

* Run on [Neovim](https://neovim.io/) 0.6+

## Setup

With packer.nvim

```
use {
  'johmsalas/shake.nvim',
  config = function()
    local shake = require('shake')

    -- keys order: 'line', 'eol', 'visual', 'operator', 'lsp_rename'
    shake.register_keys(shake.api.to_constant_case, {'crnn', 'crN', 'crn', 'crn', 'cRn'})
    shake.register_keys(shake.api.to_camel_case, {'crcc', 'crC', 'crc', 'crc', 'cRc'})
    shake.register_keys(shake.api.to_dash_case, {'crdd', 'crD', 'crd', 'crd', 'cRd'})

    shake.register_replace_command('Subs', {
      shake.api.to_upper_case,
      shake.api.to_lower_case,
      shake.api.to_snake_case,
      shake.api.to_dash_case,
      shake.api.to_constant_case,
      shake.api.to_dot_case,
      shake.api.to_phrase_case,
      shake.api.to_camel_case,
      shake.api.to_pascal_case,
      shake.api.to_title_case,
      shake.api.to_path_case,
    })

    lvim.builtin.which_key.mappings["r"]["s"] = { ":lua require('shake').replace_word_under_cursor('Subs')<cr>", "Replace word under cursor" }
  end
}
```

## Usage

### Operator

Suppose constant, camel and dash cases were setup using the following code
```
-- keys order: 'line', 'eol', 'visual', 'operator', 'lsp_rename'
shake.register_keys(shake.api.to_constant_case, {'crnn', 'crN', 'crn', 'crn', 'cRn'})
shake.register_keys(shake.api.to_camel_case, {'crcc', 'crC', 'crc', 'crc', 'cRc'})
shake.register_keys(shake.api.to_dash_case, {'crdd', 'crD', 'crd', 'crd', 'cRd'})
```

The following examples are based on the shown configuration

**Convert whole line**

`crnn`

**Convert until end of line**

`crN`

**Convert visual selection**

Given the current vim mode is `visual`, use `crn`

**LSP**

It is possible to change the case, not only of the word under the cursor, but its definition and usages via LSP. 
Hovering the text to change, use `cRn`

### Bulk replacement

Suppose constant, camel and dash cases were registered under the same command `Subs`. Take into account it is possible to setup multiple commands grouping different methods

```
shake.register_replace_command('Subs', {
  shake.api.to_dash_case,
  shake.api.to_constant_case,
  shake.api.to_camel_case,
})
```

Activate the search replace feature via command mode:

`:Subs/{string to be replaced}/{replacement string}` <enter>

Let's say you want to replace the `StepOne` component name to `StudentsOnboarding` in the following piece of code:

```javascript
import StepOne from './components/step-one';

const SampleWizard = () => {
  const [currentStep, setCurrentStep] = useState(1)
  if (currentStep === steps.STEP_ONE)  {
    return <StepOne />
  }
}
```

Executing `:CR/step one/students onboarding` will result into:

```javascript
import StudentsOnboarding from './components/students-onboarding';

const SampleWizard = () => {
  const [currentStep, setCurrentStep] = useState(1)
  if (currentStep === steps.STUDENTS_ONBOARDING)  {
    return <StudentsOnboarding />
  }
}
```

**note:** The actual component will not be renamed yet because LSP renaming is not enabled for bulk replacement

## Configuration

### Key binding

Key bindings are setup when the method is registered

```
-- keys order: 'line', 'eol', 'visual', 'operator', 'lsp_rename'
shake.register_keys(shake.api.to_constant_case, {'crnn', 'crN', 'crn', 'crn', 'cRn'})
```

The previous piece of code is a shortcut. The complete version, which is also more readable, is available:

```
shake.register_keybindings(shake.api.to_constant_case, {
  line: 'crnn',
  eol: 'crN',
  visual: 'crn',
  operator: 'crn',
  lsp_rename: 'cRn',
})
```

To avoid registering a keybinding any of the values can be omitted or provided as nil

### Manual key binds

To manually provide the custom key mapping for every operation:

```lua
-- Apply to the line
vim.api.nvim_set_keymap("n", "crss", "<cmd>lua require('shake').line('snake_case')<cr>", { noremap = true })
-- Apply from the cursor to the end of line
vim.api.nvim_set_keymap("n", "crS", "<cmd>lua require('shake').eol('snake_case')<cr>", { noremap = true })
-- Wait until an object is provided
vim.api.nvim_set_keymap("n", "crs", "<cmd>lua require('shake').operator('snake_case')<cr>", { noremap = true })
-- Change word under cursor using LSP rename
vim.api.nvim_set_keymap("n", "cRs", "<cmd>lua require('shake').lsp_rename('snake_case')<cr>", { noremap = true })
```

I don't know if there is a use case for manually setting up the keybinds

## Bulk replacement

Register a set of transformations under a given command. For the following example, let's assume the command `Subs`, and add several transforms

```
shake.register_replace_command('Subs', {
  shake.api.to_dash_case,
  shake.api.to_constant_case,
  shake.api.to_camel_case,
})
```

When the command `Subs` is invoked, it will try every variation of the source string transformed using the provided methods. And transform all the variations of the second string using the current conversion

## Contribution

### Development

#### Useful commands

Start vim and the module for testing
`nvim --cmd "set rtp+=/path/to/the/module"`

To remove the cache of the module
`:lua package.loaded['shake'] = nil`

Run the tests
nvim --headless --noplugin -u tests/minimal.vim -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.vim'}"

### Project Status

* [WIP] Beta testing: Currently checking if the triggers make sense
* [WIP] Beta testing: Getting feedback if the string case algorithm work as expected
* [x] Add instructions for setup
* [x] Provide triggering via commands
* [ ] Bulk replacement: LSP support
* [x] Bulk replacement: Apply only on visual selection
* [ ] Bulk replacement: Hightlight replicable strings
* [ ] Bulk replacement: Interactive mode
* [x] Add support for custom key mapping
* [x] Add support for custom prefix on key mapping
* [ ] Support Telescope
* [ ] Verify format of prefixes

### Related projects

Inspired by [substitute.lua](https://github.com/gbprod/substitute.nvim)

Alternatives
[vim-abolish by tpope](https://github.com/tpope/vim-abolish)
