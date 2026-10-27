return {
	"nvim-treesitter/nvim-treesitter",
<<<<<<< Updated upstream
	branch = "master",
=======
    branch = "master",
>>>>>>> Stashed changes

	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
		"windwp/nvim-ts-autotag",
		"windwp/nvim-autopairs",
	},

	build = ":TSUpdate",
	event = "bufWinEnter",

	config = function()
		local treesitter = require("nvim-treesitter.configs")

		treesitter.setup({
			ensure_installed = {
				"angular",
				"c",
				"lua",
				"vim",
				"vimdoc",
				"html",
				"css",
				"javascript",
				"typescript",
				"python",
				"markdown",
				"markdown_inline",
				"make",
				"xml",
                "zig",
                "mermaid",
                "go",
			},
			sync_install = false,
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = true,
			},
			autotag = {
				enable = true,
			},
			autopairs = {
				enable = true,
			},
			rainbow = {
				enable = true,
			},
		})
	end,
}
