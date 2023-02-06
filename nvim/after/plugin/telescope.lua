local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
    return
end

local actions = require 'telescope.actions'

telescope.setup {
    defaults = {
        prompt_prefix = '(•◡•)/ ',
        selection_caret = 'ᕗ ',
        path_display = { "smart" },
        file_ignore_patterns = {
            "node_modules",
            ".vs",
            ".vscode",
            ".git",
            "%.mp4",
            "%.dll",
            "%.class",
            "%.exe",
            "%.cache",
            "%.ico",
            "%.pdf",
            "%.dylib",
            "%.jar",
            "%.mkv",
            "%.rar",
            "%.zip",
            "%.7z",
            "%.tar",
            "%.bz2",
            "%.epub",
            "%.flac",
            "%.tar.gz"
        },
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--ignore-file',
            '.gitignore'
        }
    },
    extensions = {
        fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true
        }
    }
}

telescope.load_extension 'fzy_native'

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>lf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ls',
    function()
        builtin.grep_string({ search = vim.fn.input("(╯🔥ᖨ🔥)╯┻━┻ ") });
    end)
vim.keymap.set('n', '<leader>ll', builtin.live_grep, {})
vim.keymap.set('n', '<leader>lb', builtin.buffers, {})

-- lsp mappings
vim.keymap.set('n', '<leader>ld', builtin.lsp_definitions, {})
vim.keymap.set('n', '<leader>lr', builtin.lsp_references, {})

-- diagnostics
vim.keymap.set('n', '<leader>le', builtin.diagnostics, {})

-- git
vim.keymap.set('n', '<leader>gc', builtin.git_bcommits, {})
vim.keymap.set('n', '<leader>gb', builtin.git_branches, {})
vim.keymap.set('n', '<leader>gs', builtin.git_status, {})
vim.keymap.set('n', '<leader>gt', builtin.git_stash, {})



