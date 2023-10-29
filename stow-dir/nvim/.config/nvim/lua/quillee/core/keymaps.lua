vim.g.mapleader = " "
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = false }

-- Toggle between tabs
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Copy-Pasting
map("v", "<C-c>", '"+y', opts)
map("n", "<C-s>", '"+P', opts)

-- map('n', '<leader>cr',
--     function()
--         vim.cmd { cmd = 'so', args = { '$MYVIMRC' } }
--     end)

-- -- search related bindings
-- map('n', '<leader>ho', vim.cmd.noh, { noremap = true, silent = false })
-- func_map('<leader>ho', vim.cmd.noh, opts)