return {
  'nfrid/markdown-togglecheck',
  ft = { 'markdown' },
  config = function()
    require('markdown-togglecheck').setup {
      create = true,
      remove = false,
    }

    -- Keymap to toggle checkbox on current line
    vim.keymap.set('n', '<leader>tt', require('markdown-togglecheck').toggle, { desc = '[T]oggle Markdown Checkbox' })
  end,
}
