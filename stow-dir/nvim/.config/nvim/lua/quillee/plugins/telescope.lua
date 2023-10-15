return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"kdheepak/lazygit.nvim",
		"nvim-tree/nvim-web-devicons",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},

	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
        local builtin = require 'telescope.builtin'

		telescope.setup({
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
                },
				layout_config = {
					width = 0.80,
					prompt_position = "top",
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
				initial_mode = "insert",
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
					n = {
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                        ['<leader>lf'] = builtin.find_files,
                        ['<C-p>'] = builtin.git_files,
                        ['<leader>ls'] = function()
                                builtin.grep_string({ search = vim.fn.input("(╯🔥ᖨ🔥)╯┻━┻ ") });
                            end,
                        ['<leader>ll']  = builtin.live_grep,
                        ['<leader>lb']  = builtin.buffers,
                        ['<leader>lcb'] = builtin.current_buffer_fuzzy_find,
                        ['<leader>lj']  = builtin.jump_list,
                        ['<leader>lr']  = builtin.registers,
                        --
                        -- lsp mappings
                        ['<leader>lgd']  = builtin.lsp_definitions,
                        ['<leader>lgr']  = builtin.lsp_references,

                        -- diagnostics
                        ['<leader>di']  = builtin.diagnostics,

                        -- git
                        ['<leader>gc']  = builtin.git_bcommits,
                        ['<leader>gb']  = builtin.git_branches,
                        ['<leader>gs']  = builtin.git_status,
                        ['<leader>gt']  = builtin.git_stash,
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
