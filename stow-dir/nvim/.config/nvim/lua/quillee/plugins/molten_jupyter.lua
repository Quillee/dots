return {
	"benlubas/molten-nvim",
	dependencies = {
		"3rd/image.nvim",
		"willothy/wezterm.nvim",
	},
    lazy = false,
    build = ":UpdateRemotePlugins",
    config = function ()
        vim.keymap.set("n", "<leader>mi", ":MoltenInit python<CR>",
            { silent = true, desc = "Initialize the plugin" })
        vim.keymap.set("n", "<leader>me", ":MoltenEvaluateOperator<CR>",
            { silent = true, desc = "run operator selection" })
        vim.keymap.set("v", "<leader>mve", ":<C-u>MoltenEvaluateVisual<CR>gv",
            { silent = true, desc = "evaluate visual selection" })
        vim.keymap.set("n", "<leader>ml", ":MoltenEvaluateLine<CR>",
            { silent = true, desc = "evaluate line" })
        vim.keymap.set("n", "<leader>mr", ":MoltenReevaluateCell<CR>",
            { silent = true, desc = "re-evaluate cell" })
    end
}
