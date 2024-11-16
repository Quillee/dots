return {
	"norcalli/nvim-colorizer.lua",
    lazy = true,
	config = function()
		local colorizer = require("colorizer")

		colorizer.setup()
	end,
}
