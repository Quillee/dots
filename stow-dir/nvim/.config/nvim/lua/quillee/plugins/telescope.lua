return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"kdheepak/lazygit.nvim",
		"nvim-tree/nvim-web-devicons",
        "debugloop/telescope-undo.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},

	config = function()
		local telescope = require "telescope"
		local actions = require "telescope.actions"
        local builtin = require "telescope.builtin"

        vim.keymap.set("n", "<leader>lf", builtin.find_files, {})
        -- @todo: remove cause this is STOOPID
        vim.keymap.set("n", "<C-p>", builtin.git_files, {})
        vim.keymap.set("n", "<leader>ls",
            function()
                builtin.grep_string({ search = vim.fn.input("(╯🔥ᖨ🔥)╯┻━┻ ") });
            end, {})
        vim.keymap.set("n", "<leader>ll", builtin.live_grep, {})
        vim.keymap.set("n", "<leader>lb", builtin.buffers, {})
        vim.keymap.set("n", "<leader>lcb", builtin.current_buffer_fuzzy_find, {})
        vim.keymap.set("n", "<leader>lcl", builtin.jumplist, {})
        vim.keymap.set("n", "<leader>lr", builtin.registers, {})
        require("telescope").load_extension("undo")
        vim.keymap.set("n", "<leader>lu", "<cmd>Telescope undo<cr>")
        
        -- history mappings
        vim.keymap.set("n", "<leader>lh", builtin.search_history, {})
        vim.keymap.set("n", "<leader>lch", builtin.command_history, {})
        
        -- frequently used
        vim.keymap.set("n", "<leader>lo", builtin.oldfiles, {})
        vim.keymap.set("n", "<leader>lp", builtin.resume, {})
        vim.keymap.set("n", "<leader>lm", builtin.marks, {})
        vim.keymap.set("n", "<leader>lk", builtin.keymaps, {})
        vim.keymap.set("n", "<leader>lH", builtin.help_tags, {})
        vim.keymap.set("n", "<leader>lc", builtin.colorscheme, {})

        -- lsp mappings
        vim.keymap.set("n", "<leader>ld", builtin.lsp_definitions, {})
        vim.keymap.set("n", "<leader>li", builtin.lsp_implementations, {})
        vim.keymap.set("n", "<leader>lt", builtin.lsp_type_definitions, {})
        vim.keymap.set("n", "<leader>lR", builtin.lsp_references, {})
        vim.keymap.set("n", "<leader>lw", builtin.lsp_workspace_symbols, {})
        vim.keymap.set("n", "<leader>lds", builtin.lsp_document_symbols, {})

        -- diagnostics
        vim.keymap.set("n", "<leader>lD", builtin.diagnostics, {})

        -- git
        vim.keymap.set("n", "<leader>gc", builtin.git_bcommits, {})
        vim.keymap.set("n", "<leader>gb", builtin.git_branches, {})
        vim.keymap.set("n", "<leader>gs", builtin.git_status, {})
        vim.keymap.set("n", "<leader>gt", builtin.git_stash, {})

		telescope.setup({
			defaults = {
                prompt_prefix = "(•◡•)/ ",
                selection_caret = "ᕗ ",
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
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "--ignore-file",
                    ".gitignore"
                },
				layout_config = {
					width = 0.80,
					prompt_position = "bottom",
					preview_cutoff = 120,
					horizontal = { mirror = false },
					vertical = { mirror = false },
				},
				find_command = {
					"rg",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				entry_prefix = "  ",
				selection_strategy = "reset",
				sorting_strategy = "descending",
				layout_strategy = "horizontal",
				file_sorter = require("telescope.sorters").get_fuzzy_file,
				generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
				winblend = 0,
				border = {},
				borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				color_devicons = true,
				use_less = true,
				set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
				file_previewer = require("telescope.previewers").vim_buffer_cat.new,
				grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
				qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
				buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
				mappings = {
					i = {
						["<C-n>"] = actions.move_selection_next,
						["<C-p>"] = actions.move_selection_previous,
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<esc>"] = actions.close,
						["<CR>"] = actions.select_default + actions.center,
					},
				},
			},
            extensions = {
                -- fzy_native = {
                --     override_generic_sorter = false,
                --     override_file_sorter = true
                -- },
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = false,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                }
            }
		})

		telescope.load_extension("fzf")
	end,

}
