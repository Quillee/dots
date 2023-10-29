return {
	'lewis6991/gitsigns.nvim',
    dependencies = {
        'tpope/vim-fugitive'
    },
	config = function()
		require('gitsigns').setup({
			current_line_blame = true,
		})
	end,
}
