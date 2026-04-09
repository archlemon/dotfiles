-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    'catppuccin/nvim',
    name = 'catppuccin-mocha',
    priority = 1000,
  },

  {
    'zbirenbaum/copilot.lua',
    config = function()
      require('copilot').setup {
        filetypes = {
          ['*'] = true,
        },
        suggestion = {
          enabled = true,
          auto_trigger = false,
          keymap = {
            accept = '<M-l>',
            accept_word = false,
            accept_line = false,
            next = '<M-j>',
            prev = '<M-k>',
            dismiss = '<M-]>',
          },
        },
        panel = { enabled = false },
      }
    end,
  },

  {
    'fang2hou/blink-copilot',
    dependencies = { 'zbirenbaum/copilot.lua', 'saghen/blink.cmp' },
    config = function()
      require('blink.cmp').setup {
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot' },
          providers = {
            copilot = {
              async = true,
              module = 'blink-copilot',
              name = 'copilot',
              score_offset = 100,
              opts = {
                max_completions = 3,
                debounce = 750,
              },
            },
          },
        },
      }
    end,
  },

  { 'rrethy/vim-illuminate' },

  { 'akinsho/toggleterm.nvim', version = '*', config = true },

  { 'tpope/vim-sleuth' },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufReadPost',
    config = function()
      require('treesitter-context').setup {
        enable = true,
        max_lines = 5,
        trim_scope = 'outer',
        mode = 'cursor',
        separator = nil,
      }
    end,
  },

  {
    'folke/zen-mode.nvim',
    opts = {},
  },
}
