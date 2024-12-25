# `markdown-present.nvim`

This is the plugin to view markdown file as slides in neovim.

## Usage

```lua
require("markdown-present").start_present()
```
or 

- Use predefined command `:Present` to enter presentation mode.

Notes:
- Use ctrl-n / ctrl-p to navigate the slides.
- Use q to leave the presentation mode.

## Configuration
I recommend to use other plugin to render the markdown syntax.
Sample configuration is shown below:

lazy.nvim
```lua
{
  'laddertosky/markdown-present.nvim',
  dependencies = {
    'MeanderingProgrammer/render-markdown.nvim',
    'nvim-tree/nvim-web-devicons',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('render-markdown').setup {}
  end,
}
```
