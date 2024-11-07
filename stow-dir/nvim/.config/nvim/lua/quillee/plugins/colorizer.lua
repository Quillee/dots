return {
	"norcalli/nvim-colorizer.lua",
    lazy = true,
	config = function()
		vim.o.termguicolors = true
		local colorizer = require("colorizer")

		colorizer.setup()
	end,
}
