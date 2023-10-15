return {
    'ms-jpq/chadtree',
    config = function()
        vim.keymap.set('n', '<leader>pv', vim.cmd.CHADopen)
    end,
}
