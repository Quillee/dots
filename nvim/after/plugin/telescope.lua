require('telescope').setup {
    defaults = {
        file_ignore_patterns = { "node_modules", ".vs", ".vscode", ".git" }
   --     vimgrep_arguments = {
   --         'rg',
   --         '--color=never',
    --        '--no-heading',
    --        '--with-filename',
     --       '--line-number',
    --        '--column',
    --        '--smart-case',
    --        '--ignore-file',
    --        '.gitignore'
    --    }
    }
}
   
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>fs', 
    function() 
        builtin.grep_string({ search = vim.fn.input("grep > ") });
    end)
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
