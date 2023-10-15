vim.g.mapleader = " "
local map = vim.api.nvim_set_keymap
-- Toggle between tabs
map("n", "<C-h>", "<C-w>h", { noremap = true, silent = false })
map("n", "<C-j>", "<C-w>j", { noremap = true, silent = false })
map("n", "<C-k>", "<C-w>k", { noremap = true, silent = false })
map("n", "<C-l>", "<C-w>l", { noremap = true, silent = false })

-- Indenting
map("v", "<", "<gv", { noremap = true, silent = false })
map("v", ">", ">gv", { noremap = true, silent = false })

-- Copy-Pasting
map("v", "<C-c>", '"+y', { noremap = true, silent = false })
map("n", "<C-s>", '"+P', { noremap = true, silent = false })

-- map('n', '<leader>cr',
--     function()
--         vim.cmd { cmd = 'so', args = { '$MYVIMRC' } }
--     end)

-- -- search related bindings
-- map('n', '<leader>ho', vim.cmd.noh, { noremap = true, silent = false })
