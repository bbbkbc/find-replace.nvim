# find-replace.nvim

A simple Neovim plugin to find and replace text in the current buffer with visual highlights. This is an early version, but it should work well. Hopefully, others will find it as useful as I do.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require('lazy').setup({
  {
    'yourusername/find-replace.nvim',
    config = function()
      vim.keymap.set('n', '<leader>fr', require('find_replace').find_and_replace_in_buffer, { desc = 'Find and replace in current buffer' })
    end
  }
})
