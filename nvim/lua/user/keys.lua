vim.g.mapleader = ' '

-- config
vim.keymap.set('n', '<leader>cr',
    function()
        vim.cmd { cmd = 'so', args = { '$MYVIMRC' } }
    end)

-- search related bindings
vim.keymap.set('n', '<leader>ho', vim.cmd.noh)

-- move selections up and down
-- vim.keymap.set('v', 'J', function()
--     vim.cmd { cmd = 'move', args = { '\'>+1' } }
--     vim.cmd { cmd = 'gv=gv' }
-- end)
-- vim.keymap.set('v', 'K', function()
--     vim.cmd { cmd = 'move', args = { '\'>-1' } }
--     vim.cmd { cmd = 'gv=gv' }
-- end)

