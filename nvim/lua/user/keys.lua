vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.CHADopen)
vim.keymap.set('n', '<leader>cr', function() vim.cmd { cmd = 'so', args = { '$MYVIMRC' } } end)
print('Hello moto')
