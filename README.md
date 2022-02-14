# nvim-lua-string-case

## Features

### motion

A vim motion to change string case. Go from any text case (like camelCase) to any other in the supported list (like CONSTANT_CASE) using a regular text motion

### Bulk replacement

Given two pieces of text A and B, it searches for all of A variants (in the different string cases), and replaces the text using B. It transforms and uses B, according to the target string case


## Available string case conversions

| Trigger |      Case     | Example     |
|---------|---------------|-------------|
|    u    | Upper case    | LOREM IPSUM |
|    l    | Lower case    | lorem ipsum |
|    s    | Snake case    | lorem_ipsum |
|    d    | Dash case     | lorem-ipsum |
|    n    | Constant case | LOREM_IPSUM |
|    o    | Dot case      | lorem.ipsum |
|    c    | Camel case    | loremIpsum  |
|    p    | Pascal case   | LoremIpsum  |
|    t    | Title case    | Lorem Ipsum |
|    f    | Path case     | lorem/ipsum |
|    h    | Phrase case   | Lorem ipsum |

## Requirements

* Run on [Neovim](https://neovim.io/) 0.6+

## Setup

With packer.nvim

```
use {
  'johmsalas/nvim-lua-string-case',
  config = function()
    require('stringcase').setup{
      operator_prefix = 'cr',
      lsp_operator_prefix = 'cR',
      search_replace_prefix = 'CR',
    }
  end
}
```

## Usage

### Motion

The formula is `cr{case trigger}{object}`. For instance, to convert the following 3 words to camel case, use `crc3w`. To repeat press `.`.

#### LSP

It is possible to change the case, not only of the word under the cursor, but its definition and usages via LSP. Hovering the text to change, instead of using `cr`, try `cR{case trigger}`. Sample: `cRc`

### Bulk replacement

Activate the search replace feature via command mode:

`:CR/{string to be replaced}/{replacement string}` <enter>

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

**note:** The actual component will not be renamed yet because LSP renaming is still not enabled for bulk replacement

## Configuration (Optional)

### Key binding

The key binding prefixes are optional, if the prefixes are not provided, then there will be no default key mapping

```
require('stringcase').setup{
  operator_prefix = 'cr',
  lsp_operator_prefix = 'cR',
  search_replace_prefix = 'CR',
}
```

### Custom key binding

To manually provide the custom key mapping for every operation and case:

```lua
-- Apply to the line
vim.api.nvim_set_keymap("n", "crss", "<cmd>lua require('stringcase').line('snake_case')<cr>", { noremap = true })
-- Apply from the cursor to the end of line
vim.api.nvim_set_keymap("n", "crS", "<cmd>lua require('stringcase').eol('snake_case')<cr>", { noremap = true })
-- Wait until an object is provided
vim.api.nvim_set_keymap("n", "crs", "<cmd>lua require('stringcase').operator('snake_case')<cr>", { noremap = true })
-- Change word under cursor using LSP rename
vim.api.nvim_set_keymap("n", "cRs", "<cmd>lua require('stringcase').lsp_rename('snake_case')<cr>", { noremap = true })
```

## Why another string case conversion plugin

* Written in LUA. I wanted to add the features to tpope's vim-abolish, but vim script represents one more thing to learn, that only works inside vim ecosystem
* LSP support. In programming, usually text is corelated. When a text changes, it should also change in definitions and references

## Project Status

* [WIP] Beta testing: Currently checking if the triggers make sense
* [WIP] Beta testing: Getting feedback if the string case algorithm work as expected
* [x] Add instructions for setup
* [x] Provide triggering via commands
* [ ] Bulk replacement: LSP support
* [ ] Bulk replacement: Apply only on visual selection
* [ ] Bulk replacement: Hightlight replacable strings
* [ ] Bulk replacement: Interactive mode
* [ ] Add support for custom key mapping
* [ ] Add support for custom prefix on key mapping
* [ ] Support Telescope
* [ ] Verify format of prefixes

### Related projects

Inspired by [substitute.lua](https://github.com/gbprod/substitute.nvim). Honestly, Substitute code was copy/pasted and modified to adapt its functionality

Alternatives
[vim-abolish by tpope](https://github.com/tpope/vim-abolish)
