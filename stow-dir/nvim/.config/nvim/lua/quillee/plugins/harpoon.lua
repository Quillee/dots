return {
    'theprimeagen/harpoon',
    config = function()
        local mark = require('harpoon.mark')
        local ui = require('harpoon.ui')
        local term = require('harpoon.term')

        vim.keymap.set('n', '<leader>haa', mark.add_file)
        vim.keymap.set('n', '<leader>han', ui.nav_next)
        vim.keymap.set('n', '<leader>hap', ui.nav_prev)
        vim.keymap.set('n', '<leader>ht', function() term.gotoTerminal(1) end)

        vim.keymap.set('n', '<C-e>', ui.toggle_quick_menu)

        vim.keymap.set('n', '<C-y>', function() ui.nav_file(1) end)
        vim.keymap.set('n', '<C-t>', function() ui.nav_file(2) end)
        vim.keymap.set('n', '<C-n>', function() ui.nav_file(3) end)
        vim.keymap.set('n', '<C-s>', function() ui.nav_file(4) end)
    end,
}
