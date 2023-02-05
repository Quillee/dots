vim.g.mapleader = ' '

-- config
vim.keymap.set('n', '<leader>cr', function() vim.cmd { cmd = 'so', args = { '$MYVIMRC' } } end)

-- search
vim.keymap.set('n', '<leader>ho', vim.cmd.noh)

-- buffer mgmt
vim.keymap.set('n', 'gb', vim.cmd('buffers<CR>:buffer<Space>'))
